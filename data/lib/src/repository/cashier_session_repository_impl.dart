import 'package:domain/domain.dart';

import '../../data.dart';
import '../core/exception_handler.dart';
import '../data_source/local/cashier_session_local_data_source.dart';
import '../data_source/remote/cashier_session_remote_data_source.dart';
import '../mapper/cashier_session_mapper.dart';

/// Implementation of CashierSessionRepository
class CashierSessionRepositoryImpl implements CashierSessionRepository {
  final CashierSessionRemoteDataSource _remoteDataSource;
  final CashierSessionLocalDataSource _localDataSource;
  final CashierSessionMapper _mapper;
  final SellRepository _sellRepository;

  CashierSessionRepositoryImpl({
    required CashierSessionRemoteDataSource remoteDataSource,
    required CashierSessionLocalDataSource localDataSource,
    CashierSessionMapper? mapper,
    required SellRepository sellRepository,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _mapper = mapper ?? const CashierSessionMapper(),
        _sellRepository = sellRepository;

  @override
  Future<Result<CashierSessionEntity?>> getActiveSession({
    required int userId,
    required int locationId,
  }) async {
    try {
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
    required int userId,
  }) async {
    try {
      try {
        final remoteSession = await _remoteDataSource.checkIn(
          locationId: locationId,
          amount: amount,
        );
        await _localDataSource.saveSession(remoteSession);
        return Success(_mapper.toEntity(remoteSession));
      } catch (e) {
        Logger.logE('Check-in failed, saving to local', e);

        // If remote fails, create local session
        final localSession = CashierSessionModel(
          userId: userId,
          locationId: locationId,
          openingAmount: amount,
          startTime: DateTime.now(),
          status: 'active',
          isSynced: false,
        );

        await _localDataSource.saveSession(localSession);
        return Success(_mapper.toEntity(localSession));
      }
    } catch (e) {
      Logger.logE('Error in check-in', e);
      return Error(ExceptionHandler.handleException(e));
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
    required int userId,
    required int locationId,
  }) async {
    try {
      // Step 1: Sync unsynced sessions first
      await syncUnsyncedSessions();

      // Step 2: Sync unsynced sells before checkout
      // This ensures all sales data is synced to server before closing the session
      final syncResult = await _sellRepository.syncSells();
      final result = syncResult.fold(
        onSuccess: (_) async{
          // Step 3: Try remote check-out - BẮT BUỘC phải thành công
          // Không lưu local nếu remote fail
          final remoteSession = await _remoteDataSource.checkOut(
            closingAmount: closingAmount,
            closingAmountOnStaff: closingAmountOnStaff,
            totalCardSlips: totalCardSlips,
            totalCheques: totalCheques,
            closingNote: closingNote,
            denominations: denominations,
          );

          // Step 4: Update local session after successful remote check-out
          await _localDataSource.updateSession(remoteSession);
          if (remoteSession.id != null) {
            await _localDataSource.markSessionAsSynced(remoteSession.id!);
          }

          return Success(_mapper.toEntity(remoteSession));
        },
        onError: (failure) {
          Logger.logE(
              'Failed to sync some sells before checkout: ${failure.message}',
              null);
          throw Error(failure);
        },
      );

      return result;

    } catch (e) {
      Logger.logE('Check-out failed - must retry', e);
      // Không lưu local khi checkout fail
      // Return error để user phải retry
      return Error(ExceptionHandler.handleException(e));
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
            if (session.id != null) {
              await _localDataSource.markSessionAsSynced(session.id!);
            }
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
            if (session.id != null) {
              await _localDataSource.markSessionAsSynced(session.id!);
            }
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

  @override
  Future<Result<CashierSessionEntity>> saveSessionLocally({
    required int userId,
    required int locationId,
    required double openingAmount,
    required DateTime startTime,
    bool isSynced = true,
  }) async {
    try {
      final session = CashierSessionModel(
        userId: userId,
        locationId: locationId,
        openingAmount: openingAmount,
        startTime: startTime,
        status: 'active',
        isSynced: isSynced,
      );

      await _localDataSource.saveSession(session);

      // Get the saved session to return with id
      final savedSession = await _localDataSource.getActiveSession(
        userId: userId,
        locationId: locationId,
      );

      if (savedSession == null) {
        return const Error(
            UnknownFailure(message: 'Failed to save session locally'));
      }

      return Success(_mapper.toEntity(savedSession));
    } catch (e) {
      Logger.logE('Error saving session locally', e);
      return Error(UnknownFailure(message: e.toString()));
    }
  }
}
