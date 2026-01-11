# Cashier Check-in/Check-out Implementation Plan

## 📋 Tổng Quan

Implement tính năng Cashier Check-in/Check-out trong offline mode (POS page), bao gồm:
- Check-in khi mở POS page (nếu chưa check-in)
- Cache dữ liệu check-in/check-out dưới local
- Check-out dialog với form nhập tiền mặt và ghi chú
- Sync dữ liệu khi có mạng trước khi check-out
- Trigger về màn login sau khi check-out thành công

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────┐
│      POS Page (Offline Mode)            │
│      - Check-in on init                  │
│      - Check-out on summary              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│    CashierSessionBloc                   │
│    - Manage session state                │
│    - Handle check-in/check-out           │
└──────────────┬──────────────────────────┘
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
┌──────────────┐  ┌──────────────────────┐
│   Repository │  │   Local Data Source  │
│   (Remote)   │  │   (Cache)            │
└──────────────┘  └──────────────────────┘
        │             │
        └──────┬──────┘
               ▼
┌─────────────────────────────────────────┐
│      API Endpoints                       │
│      - POST /api/cashier/start          │
│      - POST /api/cashier/end            │
└─────────────────────────────────────────┘
```

---

## 📦 Step 1: Entity & Model

### 1.1 Cashier Session Entity

**File:** `domain/lib/src/entity/cashier_session_entity.dart`

```dart
class CashierSessionEntity extends Entity {
  final int? id;
  final int userId;
  final int locationId;
  final double openingAmount;        // Số tiền vào ca
  final double? closingAmount;       // Tổng tiền đóng ca
  final double? closingAmountOnStaff; // Tiền mặt đóng ca
  final double? totalCardSlips;      // Tổng thẻ
  final double? totalCheques;        // Tổng séc
  final String? closingNote;         // Ghi chú đóng ca
  final Map<String, int>? denominations; // Mệnh giá và số lượng
  final DateTime? startTime;         // Thời gian vào ca
  final DateTime? endTime;           // Thời gian đóng ca
  final String status;               // "active", "closed"
  final bool isSynced;               // Đã sync chưa

  const CashierSessionEntity({
    this.id,
    required this.userId,
    required this.locationId,
    required this.openingAmount,
    this.closingAmount,
    this.closingAmountOnStaff,
    this.totalCardSlips,
    this.totalCheques,
    this.closingNote,
    this.denominations,
    this.startTime,
    this.endTime,
    this.status = 'active',
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        locationId,
        openingAmount,
        closingAmount,
        closingAmountOnStaff,
        status,
        isSynced,
      ];

  bool get isActive => status == 'active';
  
  CashierSessionEntity copyWith({...}) { ... }
}
```

### 1.2 Cashier Session Model

**File:** `data/lib/src/model/cashier_session_model.dart`

```dart
class CashierSessionModel extends BaseModel {
  final int? id;
  final int userId;
  final int locationId;
  final double openingAmount;
  final double? closingAmount;
  final double? closingAmountOnStaff;
  final double? totalCardSlips;
  final double? totalCheques;
  final String? closingNote;
  final Map<String, int>? denominations;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final bool isSynced;

  CashierSessionModel({...});

  factory CashierSessionModel.fromJson(Map<String, dynamic> json) {
    return CashierSessionModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      locationId: json['location_id'] as int,
      openingAmount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      closingAmount: json['closing_amount'] != null 
          ? double.tryParse(json['closing_amount'].toString().replaceAll(',', ''))
          : null,
      closingAmountOnStaff: json['closing_amount_on_staff'] != null
          ? double.tryParse(json['closing_amount_on_staff'].toString().replaceAll(',', ''))
          : null,
      totalCardSlips: json['total_card_slips'] != null
          ? double.tryParse(json['total_card_slips'].toString().replaceAll(',', ''))
          : null,
      totalCheques: json['total_cheques'] != null
          ? double.tryParse(json['total_cheques'].toString().replaceAll(',', ''))
          : null,
      closingNote: json['closing_note'] as String?,
      denominations: json['denominations'] != null
          ? Map<String, int>.from(
              (json['denominations'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : null,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      status: json['status'] as String? ?? 'active',
      isSynced: json['is_synced'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() { ... }
}
```

---

## 📦 Step 2: Local Data Source

### 2.1 Cashier Session Local Data Source

**File:** `data/lib/src/data_source/local/cashier_session_local_data_source.dart`

```dart
abstract class CashierSessionLocalDataSource {
  /// Get active session for user and location
  Future<CashierSessionModel?> getActiveSession({
    required int userId,
    required int locationId,
  });

  /// Save session (check-in)
  Future<void> saveSession(CashierSessionModel session);

  /// Update session (check-out)
  Future<void> updateSession(CashierSessionModel session);

  /// Get unsynced sessions
  Future<List<CashierSessionModel>> getUnsyncedSessions();

  /// Mark session as synced
  Future<void> markSessionAsSynced(int sessionId);

  /// Delete session
  Future<void> deleteSession(int sessionId);
}

class CashierSessionLocalDataSourceImpl
    implements CashierSessionLocalDataSource {
  final UserDatabaseHelper _dbHelper;

  CashierSessionLocalDataSourceImpl({
    required UserDatabaseHelper dbHelper,
  }) : _dbHelper = dbHelper;

  // Use table: cashier_sessions
  // Columns: id, user_id, location_id, opening_amount, closing_amount, 
  //          closing_amount_on_staff, total_card_slips, total_cheques,
  //          closing_note, denominations (JSON), start_time, end_time,
  //          status, is_synced, created_at, updated_at

  @override
  Future<CashierSessionModel?> getActiveSession({
    required int userId,
    required int locationId,
  }) async {
    // Query: SELECT * FROM cashier_sessions 
    // WHERE user_id = ? AND location_id = ? AND status = 'active'
    // ORDER BY created_at DESC LIMIT 1
  }

  @override
  Future<void> saveSession(CashierSessionModel session) async {
    // INSERT INTO cashier_sessions ...
  }

  @override
  Future<void> updateSession(CashierSessionModel session) async {
    // UPDATE cashier_sessions SET ... WHERE id = ?
  }

  @override
  Future<List<CashierSessionModel>> getUnsyncedSessions() async {
    // SELECT * FROM cashier_sessions WHERE is_synced = 0
  }

  @override
  Future<void> markSessionAsSynced(int sessionId) async {
    // UPDATE cashier_sessions SET is_synced = 1 WHERE id = ?
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    // DELETE FROM cashier_sessions WHERE id = ?
  }
}
```

### 2.2 Database Schema

**File:** `data/lib/src/data_source/local/database/user_database_helper.dart`

Thêm table mới:

```dart
// In onCreate or onUpgrade
CREATE TABLE IF NOT EXISTS cashier_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  location_id INTEGER NOT NULL,
  opening_amount REAL NOT NULL,
  closing_amount TEXT,
  closing_amount_on_staff TEXT,
  total_card_slips TEXT,
  total_cheques TEXT,
  closing_note TEXT,
  denominations TEXT,  -- JSON string
  start_time TEXT,
  end_time TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  is_synced INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(user_id, location_id, status) WHERE status = 'active'
);
```

---

## 📦 Step 3: Remote Data Source

### 3.1 Cashier Session Remote Data Source

**File:** `data/lib/src/data_source/remote/cashier_session_remote_data_source.dart`

```dart
abstract class CashierSessionRemoteDataSource {
  /// Check-in (start session)
  Future<CashierSessionModel> checkIn({
    required int locationId,
    required double amount,
  });

  /// Check-out (end session)
  Future<CashierSessionModel> checkOut({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
  });
}

class CashierSessionRemoteDataSourceImpl
    implements CashierSessionRemoteDataSource {
  final ApiClient _apiClient;
  final String _checkInEndpoint;
  final String _checkOutEndpoint;

  CashierSessionRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String checkInEndpoint,
    required String checkOutEndpoint,
  })  : _apiClient = apiClient,
        _checkInEndpoint = checkInEndpoint,
        _checkOutEndpoint = checkOutEndpoint;

  @override
  Future<CashierSessionModel> checkIn({
    required int locationId,
    required double amount,
  }) async {
    final response = await _apiClient.post(
      _checkInEndpoint,
      body: {
        'location_id': locationId,
        'amount': amount.toString(),
      },
    );

    return CashierSessionModel.fromJson(response);
  }

  @override
  Future<CashierSessionModel> checkOut({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
  }) async {
    final response = await _apiClient.post(
      _checkOutEndpoint,
      body: {
        'closing_amount': closingAmount.toString().replaceAll(',', ''),
        'closing_amount_on_staff': closingAmountOnStaff.toString().replaceAll(',', ''),
        'total_card_slips': totalCardSlips.toString().replaceAll(',', ''),
        'total_cheques': totalCheques.toString().replaceAll(',', ''),
        'closing_note': closingNote,
        'denominations': denominations,
      },
    );

    return CashierSessionModel.fromJson(response);
  }
}
```

---

## 📦 Step 4: Repository

### 4.1 Cashier Session Repository Interface

**File:** `domain/lib/src/repository/cashier_session_repository.dart`

```dart
abstract class CashierSessionRepository {
  /// Get active session
  Future<Result<CashierSessionEntity?>> getActiveSession({
    required int userId,
    required int locationId,
  });

  /// Check-in (start session)
  Future<Result<CashierSessionEntity>> checkIn({
    required int locationId,
    required double amount,
  });

  /// Check-out (end session)
  Future<Result<CashierSessionEntity>> checkOut({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
  });

  /// Sync unsynced sessions
  Future<Result<void>> syncUnsyncedSessions();
}
```

### 4.2 Cashier Session Repository Implementation

**File:** `data/lib/src/repository/cashier_session_repository_impl.dart`

```dart
class CashierSessionRepositoryImpl implements CashierSessionRepository {
  final CashierSessionRemoteDataSource _remoteDataSource;
  final CashierSessionLocalDataSource _localDataSource;
  final CashierSessionMapper _mapper;

  @override
  Future<Result<CashierSessionEntity?>> getActiveSession({
    required int userId,
    required int locationId,
  }) async {
    try {
      // Always check local first (offline-first)
      final localSession = await _localDataSource.getActiveSession(
        userId: userId,
        locationId: locationId,
      );

      if (localSession != null) {
        return Success(_mapper.toEntity(localSession));
      }

      return const Success(null);
    } catch (e) {
      Logger.logE('Error getting active session', e);
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<CashierSessionEntity>> checkIn({
    required int locationId,
    required double amount,
  }) async {
    try {
      // Try remote first
      final remoteSession = await _remoteDataSource.checkIn(
        locationId: locationId,
        amount: amount,
      );

      // Save to local
      await _localDataSource.saveSession(remoteSession);

      return Success(_mapper.toEntity(remoteSession));
    } catch (e) {
      Logger.logE('Check-in failed, saving to local', e);
      
      // If remote fails, create local session
      final localSession = CashierSessionModel(
        userId: _getCurrentUserId(), // Get from AuthCubit
        locationId: locationId,
        openingAmount: amount,
        startTime: DateTime.now(),
        status: 'active',
        isSynced: false,
      );

      await _localDataSource.saveSession(localSession);

      return Success(_mapper.toEntity(localSession));
    }
  }

  @override
  Future<Result<CashierSessionEntity>> checkOut({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
  }) async {
    try {
      // First sync unsynced sessions
      await syncUnsyncedSessions();

      // Try remote check-out
      final remoteSession = await _remoteDataSource.checkOut(
        closingAmount: closingAmount,
        closingAmountOnStaff: closingAmountOnStaff,
        totalCardSlips: totalCardSlips,
        totalCheques: totalCheques,
        closingNote: closingNote,
        denominations: denominations,
      );

      // Update local
      await _localDataSource.updateSession(remoteSession);
      await _localDataSource.markSessionAsSynced(remoteSession.id!);

      return Success(_mapper.toEntity(remoteSession));
    } catch (e) {
      Logger.logE('Check-out failed, saving to local', e);
      
      // If remote fails, update local session
      final activeSession = await _localDataSource.getActiveSession(
        userId: _getCurrentUserId(),
        locationId: _getCurrentLocationId(),
      );

      if (activeSession != null) {
        final updatedSession = activeSession.copyWith(
          closingAmount: closingAmount,
          closingAmountOnStaff: closingAmountOnStaff,
          totalCardSlips: totalCardSlips,
          totalCheques: totalCheques,
          closingNote: closingNote,
          denominations: denominations,
          endTime: DateTime.now(),
          status: 'closed',
          isSynced: false,
        );

        await _localDataSource.updateSession(updatedSession);

        return Success(_mapper.toEntity(updatedSession));
      }

      return Error(NotFoundFailure(message: 'Active session not found'));
    }
  }

  @override
  Future<Result<void>> syncUnsyncedSessions() async {
    try {
      final unsyncedSessions = await _localDataSource.getUnsyncedSessions();

      for (final session in unsyncedSessions) {
        if (session.status == 'active') {
          // Sync check-in
          try {
            await _remoteDataSource.checkIn(
              locationId: session.locationId,
              amount: session.openingAmount,
            );
            await _localDataSource.markSessionAsSynced(session.id!);
          } catch (e) {
            Logger.logE('Failed to sync check-in', e);
          }
        } else if (session.status == 'closed') {
          // Sync check-out
          try {
            await _remoteDataSource.checkOut(
              closingAmount: session.closingAmount ?? 0,
              closingAmountOnStaff: session.closingAmountOnStaff ?? 0,
              totalCardSlips: session.totalCardSlips ?? 0,
              totalCheques: session.totalCheques ?? 0,
              closingNote: session.closingNote ?? '',
              denominations: session.denominations ?? {},
            );
            await _localDataSource.markSessionAsSynced(session.id!);
          } catch (e) {
            Logger.logE('Failed to sync check-out', e);
          }
        }
      }

      return const Success(null);
    } catch (e) {
      Logger.logE('Error syncing sessions', e);
      return Error(UnknownFailure(message: e.toString()));
    }
  }
}
```

---

## 📦 Step 5: BLoC/Cubit

### 5.1 Cashier Session State

**File:** `lib/src/application/cashier_session/cashier_session_state.dart`

```dart
sealed class CashierSessionState {
  const CashierSessionState();
}

class CashierSessionInitial extends CashierSessionState {
  const CashierSessionInitial();
}

class CashierSessionLoading extends CashierSessionState {
  const CashierSessionLoading();
}

class CashierSessionLoaded extends CashierSessionState {
  final CashierSessionEntity? activeSession;
  final bool showCheckInDialog;

  const CashierSessionLoaded({
    required this.activeSession,
    this.showCheckInDialog = false,
  });
}

class CashierSessionError extends CashierSessionState {
  final String message;

  const CashierSessionError(this.message);
}

class CashierSessionCheckOutSuccess extends CashierSessionState {
  const CashierSessionCheckOutSuccess();
}
```

### 5.2 Cashier Session Event

**File:** `lib/src/application/cashier_session/cashier_session_event.dart`

```dart
sealed class CashierSessionEvent {
  const CashierSessionEvent();
}

class CashierSessionInitialize extends CashierSessionEvent {
  final int userId;
  final int locationId;

  const CashierSessionInitialize({
    required this.userId,
    required this.locationId,
  });
}

class CashierSessionCheckIn extends CashierSessionEvent {
  final int locationId;
  final double amount;

  const CashierSessionCheckIn({
    required this.locationId,
    required this.amount,
  });
}

class CashierSessionCheckOut extends CashierSessionEvent {
  final double closingAmount;
  final double closingAmountOnStaff;
  final double totalCardSlips;
  final double totalCheques;
  final String closingNote;
  final Map<String, int> denominations;

  const CashierSessionCheckOut({
    required this.closingAmount,
    required this.closingAmountOnStaff,
    required this.totalCardSlips,
    required this.totalCheques,
    required this.closingNote,
    required this.denominations,
  });
}

class CashierSessionShowCheckOutDialog extends CashierSessionEvent {
  const CashierSessionShowCheckOutDialog();
}
```

### 5.3 Cashier Session BLoC

**File:** `lib/src/application/cashier_session/cashier_session_bloc.dart`

```dart
class CashierSessionBloc
    extends Bloc<CashierSessionEvent, CashierSessionState> {
  final CashierSessionRepository _repository;

  CashierSessionBloc({
    required CashierSessionRepository repository,
  })  : _repository = repository,
        super(const CashierSessionInitial()) {
    on<CashierSessionInitialize>(_onInitialize);
    on<CashierSessionCheckIn>(_onCheckIn);
    on<CashierSessionCheckOut>(_onCheckOut);
    on<CashierSessionShowCheckOutDialog>(_onShowCheckOutDialog);
  }

  Future<void> _onInitialize(
    CashierSessionInitialize event,
    Emitter<CashierSessionState> emit,
  ) async {
    emit(const CashierSessionLoading());

    final result = await _repository.getActiveSession(
      userId: event.userId,
      locationId: event.locationId,
    );

    result.fold(
      onSuccess: (session) {
        emit(CashierSessionLoaded(
          activeSession: session,
          showCheckInDialog: session == null, // Show dialog if no active session
        ));
      },
      onError: (failure) {
        emit(CashierSessionError(failure.message));
      },
    );
  }

  Future<void> _onCheckIn(
    CashierSessionCheckIn event,
    Emitter<CashierSessionState> emit,
  ) async {
    emit(const CashierSessionLoading());

    final result = await _repository.checkIn(
      locationId: event.locationId,
      amount: event.amount,
    );

    result.fold(
      onSuccess: (session) {
        emit(CashierSessionLoaded(
          activeSession: session,
          showCheckInDialog: false,
        ));
      },
      onError: (failure) {
        emit(CashierSessionError(failure.message));
      },
    );
  }

  Future<void> _onCheckOut(
    CashierSessionCheckOut event,
    Emitter<CashierSessionState> emit,
  ) async {
    emit(const CashierSessionLoading());

    final result = await _repository.checkOut(
      closingAmount: event.closingAmount,
      closingAmountOnStaff: event.closingAmountOnStaff,
      totalCardSlips: event.totalCardSlips,
      totalCheques: event.totalCheques,
      closingNote: event.closingNote,
      denominations: event.denominations,
    );

    result.fold(
      onSuccess: (_) {
        emit(const CashierSessionCheckOutSuccess());
      },
      onError: (failure) {
        emit(CashierSessionError(failure.message));
      },
    );
  }

  void _onShowCheckOutDialog(
    CashierSessionShowCheckOutDialog event,
    Emitter<CashierSessionState> emit,
  ) {
    if (state is CashierSessionLoaded) {
      final currentState = state as CashierSessionLoaded;
      emit(currentState.copyWith(showCheckOutDialog: true));
    }
  }
}
```

---

## 📦 Step 6: UI Components

### 6.1 Check-in Dialog

**File:** `lib/src/presentation/pages/pos/widgets/cashier_checkin_dialog.dart`

```dart
class CashierCheckInDialog extends StatefulWidget {
  final int locationId;
  final Function(double amount) onCheckIn;

  const CashierCheckInDialog({
    super.key,
    required this.locationId,
    required this.onCheckIn,
  });

  @override
  State<CashierCheckInDialog> createState() => _CashierCheckInDialogState();
}

class _CashierCheckInDialogState extends State<CashierCheckInDialog> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemes.light;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.tr(LocaleKeys.cashierCheckIn),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.tr(LocaleKeys.openingAmount),
                  prefixIcon: const Icon(Icons.money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.tr(LocaleKeys.pleaseEnterAmount);
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return l10n.tr(LocaleKeys.invalidAmount);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.tr(LocaleKeys.cancel)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final amount = double.parse(_amountController.text);
                        widget.onCheckIn(amount);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                    ),
                    child: Text(l10n.tr(LocaleKeys.checkIn)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 6.2 Check-out Dialog

**File:** `lib/src/presentation/pages/pos/widgets/cashier_checkout_dialog.dart`

```dart
class CashierCheckOutDialog extends StatefulWidget {
  final CashierSessionEntity session;
  final String cashierName;
  final String locationName;
  final Function({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
  }) onCheckOut;

  const CashierCheckOutDialog({
    super.key,
    required this.session,
    required this.cashierName,
    required this.locationName,
    required this.onCheckOut,
  });

  @override
  State<CashierCheckOutDialog> createState() => _CashierCheckOutDialogState();
}

class _CashierCheckOutDialogState extends State<CashierCheckOutDialog> {
  final Map<String, TextEditingController> _denominationControllers = {};
  final _noteController = TextEditingController();
  
  // Vietnamese banknotes (1000 to 500000)
  static const List<int> _denominations = [
    500000, 200000, 100000, 50000, 20000, 10000, 5000, 2000, 1000,
  ];

  @override
  void initState() {
    super.initState();
    for (final denom in _denominations) {
      _denominationControllers[denom.toString()] = TextEditingController(
        text: widget.session.denominations?[denom.toString()]?.toString() ?? '0',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _denominationControllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    double total = 0;
    for (final entry in _denominationControllers.entries) {
      final denom = int.tryParse(entry.key) ?? 0;
      final count = int.tryParse(entry.value.text) ?? 0;
      total += denom * count;
    }
    return total;
  }

  Map<String, int> _getDenominations() {
    final Map<String, int> result = {};
    for (final entry in _denominationControllers.entries) {
      final count = int.tryParse(entry.value.text) ?? 0;
      if (count > 0) {
        result[entry.key] = count;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemes.light;
    final totalAmount = _calculateTotal();

    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tr(LocaleKeys.currentSession),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Total amount display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.tr(LocaleKeys.closingAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Helper().formatCurrency(totalAmount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Denominations list
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _denominations.length,
                itemBuilder: (context, index) {
                  final denom = _denominations[index];
                  final controller = _denominationControllers[denom.toString()]!;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            Helper().formatCurrency(denom.toDouble()),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.tr(LocaleKeys.count),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Text(
                            Helper().formatCurrency(
                              (int.tryParse(controller.text) ?? 0) * denom.toDouble(),
                            ),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Note field
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.tr(LocaleKeys.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cashier and location info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.tr(LocaleKeys.cashier)}: ${widget.cashierName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.tr(LocaleKeys.location)}: ${widget.locationName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.tr(LocaleKeys.cancel)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onCheckOut(
                      closingAmount: totalAmount,
                      closingAmountOnStaff: totalAmount, // Assuming all cash
                      totalCardSlips: 0, // Get from payment summary
                      totalCheques: 0, // Get from payment summary
                      closingNote: _noteController.text,
                      denominations: _getDenominations(),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                  ),
                  child: Text(l10n.tr(LocaleKeys.checkOut)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📦 Step 7: Integration vào POS Page

### 7.1 Update POS Page

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

```dart
// In initState or build method
BlocProvider(
  create: (context) => CashierSessionBloc(
    repository: sl.get<CashierSessionRepository>(),
  )..add(CashierSessionInitialize(
        userId: currentUser.id,
        locationId: selectedLocationId,
      )),
  child: BlocListener<CashierSessionBloc, CashierSessionState>(
    listener: (context, state) {
      if (state is CashierSessionLoaded && state.showCheckInDialog) {
        // Show check-in dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CashierCheckInDialog(
            locationId: selectedLocationId,
            onCheckIn: (amount) {
              context.read<CashierSessionBloc>().add(
                    CashierSessionCheckIn(
                      locationId: selectedLocationId,
                      amount: amount,
                    ),
                  );
            },
          ),
        );
      }

      if (state is CashierSessionCheckOutSuccess) {
        // Trigger logout (navigate to login)
        // Similar to pos_online_page logout logic
        context.read<AuthCubit>().logout();
      }

      if (state is CashierSessionError) {
        ToastManager.showError(context, state.message);
      }
    },
    child: // Existing POS page content
  ),
)

// Add check-out button in summary/payment area
ElevatedButton(
  onPressed: () {
    final sessionBloc = context.read<CashierSessionBloc>();
    final session = (sessionBloc.state as CashierSessionLoaded).activeSession;
    
    if (session != null) {
      showDialog(
        context: context,
        builder: (context) => CashierCheckOutDialog(
          session: session,
          cashierName: currentUser.name,
          locationName: selectedLocation.name,
          onCheckOut: (params) {
            sessionBloc.add(
              CashierSessionCheckOut(
                closingAmount: params['closingAmount']!,
                closingAmountOnStaff: params['closingAmountOnStaff']!,
                totalCardSlips: params['totalCardSlips']!,
                totalCheques: params['totalCheques']!,
                closingNote: params['closingNote']!,
                denominations: params['denominations']!,
              ),
            );
          },
        ),
      );
    }
  },
  child: Text(l10n.tr(LocaleKeys.checkOut)),
)
```

---

## 📦 Step 8: Register Dependencies

**File:** `lib/app_config/di.dart`

```dart
void _registerRemoteDataSources(AppConfig config) {
  // ... existing data sources ...
  
  sl.registerLazy<CashierSessionRemoteDataSource>(() => CashierSessionRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        checkInEndpoint: '${config.apiUrl}/cashier/start',
        checkOutEndpoint: '${config.apiUrl}/cashier/end',
      ));
}

void _registerRepositories(AppConfig config) {
  // ... existing repositories ...
  
  sl.registerLazy<CashierSessionRepository>(() => CashierSessionRepositoryImpl(
        remoteDataSource: sl.get<CashierSessionRemoteDataSource>(),
        localDataSource: sl.get<CashierSessionLocalDataSource>(),
      ));
}

void _registerDataSources() {
  // ... existing data sources ...
  
  sl.registerLazy<CashierSessionLocalDataSource>(() => CashierSessionLocalDataSourceImpl(
        dbHelper: sl.get<UserDatabaseHelper>(),
      ));
}
```

---

## 📦 Step 9: Localization Keys

**File:** `lib/src/core/localization/locale_keys.dart`

```dart
// Cashier Session
static const String cashierCheckIn = 'cashier_check_in';
static const String cashierCheckOut = 'cashier_check_out';
static const String openingAmount = 'opening_amount';
static const String closingAmount = 'closing_amount';
static const String currentSession = 'current_session';
static const String count = 'count';
static const String denominations = 'denominations';
```

**File:** `i18n/vi.json`

```json
{
  "cashier_check_in": "Nhận ca",
  "cashier_check_out": "Đóng ca",
  "opening_amount": "Số tiền vào ca",
  "closing_amount": "Tổng tiền đóng ca",
  "current_session": "Phiên làm việc hiện tại",
  "count": "Đếm",
  "denominations": "Mệnh giá"
}
```

**File:** `i18n/en.json`

```json
{
  "cashier_check_in": "Check In",
  "cashier_check_out": "Check Out",
  "opening_amount": "Opening Amount",
  "closing_amount": "Closing Amount",
  "current_session": "Current Session",
  "count": "Count",
  "denominations": "Denominations"
}
```

---

## 📋 Vietnamese Banknotes Denominations

Theo yêu cầu, các mệnh giá từ 1000 VNĐ đến 500000 VNĐ (theo tờ tiền được ban hành bởi nhà nước Việt Nam hiện hành):

- 500,000 VNĐ
- 200,000 VNĐ
- 100,000 VNĐ
- 50,000 VNĐ
- 20,000 VNĐ
- 10,000 VNĐ
- 5,000 VNĐ
- 2,000 VNĐ
- 1,000 VNĐ

---

## 🔄 Flow Diagram

### Check-in Flow:
```
POS Page Init
    │
    ▼
Check Active Session (Local)
    │
    ├─ Has Active Session → Continue
    │
    └─ No Active Session → Show Check-in Dialog
                            │
                            ▼
                        User Enter Amount
                            │
                            ▼
                        Try Remote Check-in
                            │
                    ┌───────┴────────┐
                    │                │
                Success          Failed
                    │                │
                    ▼                ▼
            Save to Local    Save to Local (unsynced)
                    │                │
                    ▼                ▼
                Continue        Continue
```

### Check-out Flow:
```
User Click Check-out
    │
    ▼
Show Check-out Dialog
    │
    ▼
User Enter Denominations & Note
    │
    ▼
Sync Unsynced Sessions
    │
    ▼
Try Remote Check-out
    │
    ├─ Success → Mark Synced → Trigger Logout
    │
    └─ Failed → Save to Local (unsynced) → Show Error
```

---

## ✅ Testing Checklist

- [ ] Check-in dialog hiển thị khi chưa có active session
- [ ] Check-in thành công với mạng
- [ ] Check-in thành công offline (cache local)
- [ ] Check-out dialog hiển thị đúng format
- [ ] Tính toán tổng tiền đóng ca đúng
- [ ] Check-out thành công với mạng
- [ ] Check-out thành công offline (cache local)
- [ ] Sync unsynced sessions khi có mạng
- [ ] Trigger logout sau khi check-out thành công
- [ ] Kiểm tra database schema và data persistence

---

## ⚠️ Important Notes

1. **Offline-First Approach**: Luôn ưu tiên local data, sync khi có mạng
2. **Data Format**: API trả về `closing_amount` dạng string với dấu phẩy, cần parse đúng
3. **Denominations**: Map<String, int> với key là string của mệnh giá
4. **Session Uniqueness**: Mỗi user + location chỉ có 1 active session tại 1 thời điểm
5. **Sync Strategy**: Sync unsynced sessions trước khi check-out
6. **Logout Trigger**: Sau khi check-out thành công, trigger logout như pos_online_page
