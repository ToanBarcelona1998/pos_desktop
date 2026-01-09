# Giải Pháp: WebView Popup Issue & Multi-Currency Invoice Printing

## 📋 Tổng Quan

Tài liệu này giải quyết 2 vấn đề:
1. **WebView Popup Issue**: Popup nhập số tiền vào ca trong POS online không hoạt động sau khi xác nhận
2. **Multi-Currency Invoice**: Cho phép in hóa đơn bằng VNĐ hoặc USD với tỉ giá được cache

---

## 🔍 Phân Tích Vấn Đề WebView Popup

### Nguyên Nhân Có Thể

1. **WebView không hỗ trợ popup windows mặc định**
   - `InAppWebView` mặc định không tự động mở popup windows
   - Cần implement `onCreateWindow` callback để handle popup

2. **JavaScript handlers không được setup cho popup**
   - Popup window có thể cần JavaScript handlers riêng
   - Communication giữa main window và popup window bị gián đoạn

3. **WebView settings thiếu cấu hình cho popup**
   - Cần enable `supportMultipleWindows: true`
   - Cần enable `javaScriptCanOpenWindowsAutomatically: true`

4. **Popup bị block bởi security policies**
   - CORS issues
   - Content Security Policy (CSP) blocking

### Giải Pháp

#### 1. Enable Popup Support trong WebView Settings

**File:** `lib/src/presentation/pages/pos_online/pos_online_page.dart`

```dart
InAppWebViewSettings settings = InAppWebViewSettings(
  isInspectable: false,
  mediaPlaybackRequiresUserGesture: false,
  allowsInlineMediaPlayback: true,
  iframeAllow: "camera; microphone",
  iframeAllowFullscreen: true,
  // Thêm các settings sau:
  supportMultipleWindows: true,  // Enable popup windows
  javaScriptCanOpenWindowsAutomatically: true,  // Allow JS to open windows
  useShouldOverrideUrlLoading: true,  // Handle URL loading
);
```

#### 2. Implement onCreateWindow Callback

**File:** `lib/src/presentation/pages/pos_online/pos_online_page.dart`

Thêm vào `InAppWebView` widget:

```dart
InAppWebView(
  // ... existing code ...
  onCreateWindow: (controller, createWindowAction) async {
    // Tạo một dialog hoặc window mới để hiển thị popup
    if (mounted) {
      return await _handlePopupWindow(createWindowAction);
    }
    return false;
  },
  // ... existing code ...
)
```

#### 3. Implement Popup Handler Method

**File:** `lib/src/presentation/pages/pos_online/pos_online_page.dart`

Thêm method mới:

```dart
Future<bool> _handlePopupWindow(CreateWindowAction createWindowAction) async {
  try {
    // Option 1: Mở popup trong dialog
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: createWindowAction.request.url,
              headers: _requiredHeaders,
            ),
            onLoadStop: (controller, url) async {
              // Setup JavaScript handlers cho popup window
              await _setupPopupJavaScriptHandlers(controller);
            },
            onCloseWindow: (controller) {
              Navigator.of(context).pop(true);
            },
          ),
        ),
      ),
    ) ?? false;

    // Option 2: Mở popup trong window mới (nếu cần)
    // final popupWindow = await WindowManagerUtils.createNewWindow(
    //   WindowArguments(
    //     type: WindowType.popup,
    //     params: {'url': createWindowAction.request.url.toString()},
    //   ),
    // );
    // return popupWindow != null;
  } catch (e) {
    Logger.logE('Error handling popup window', e);
    return false;
  }
}

Future<void> _setupPopupJavaScriptHandlers(InAppWebViewController controller) async {
  // Setup các JavaScript handlers cần thiết cho popup
  // Ví dụ: handle form submission, close popup, etc.
  
  controller.addJavaScriptHandler(
    handlerName: 'closePopup',
    callback: (args) {
      Navigator.of(context).pop(true);
      return 'closed';
    },
  );

  controller.addJavaScriptHandler(
    handlerName: 'submitForm',
    callback: (args) async {
      // Handle form submission từ popup
      // Có thể cần gửi data về main window
      if (webViewController != null) {
        await webViewController!.evaluateJavascript(
          source: '''
            if (window.handlePopupSubmit) {
              window.handlePopupSubmit(${jsonEncode(args)});
            }
          ''',
        );
      }
      Navigator.of(context).pop(true);
      return 'submitted';
    },
  );
}
```

#### 4. Alternative: Handle Popup bằng JavaScript Injection

Nếu popup là form dialog, có thể inject JavaScript để intercept form submission:

```dart
final String _popupHandlerScript = '''
(function() {
  // Intercept form submissions in popups
  document.addEventListener('submit', function(e) {
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('submitForm', {
        formData: new FormData(e.target)
      });
      e.preventDefault();
    }
  });

  // Intercept window.close() calls
  const originalClose = window.close;
  window.close = function() {
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('closePopup');
    } else {
      originalClose.call(window);
    }
  };
})();
''';

// Inject vào webview khi load
onLoadStop: (controller, url) async {
  await controller.evaluateJavascript(source: _popupHandlerScript);
  // ... existing code ...
}
```

---

## 💰 Giải Pháp Multi-Currency Invoice Printing

### Kiến Trúc Tổng Quan

```
┌─────────────────┐
│  Exchange Rate  │
│     API/Service │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Exchange Rate  │
│  Local Storage  │
│  (SharedPrefs)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Print Invoice  │
│     Dialog      │
│  (Currency      │
│   Selector)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Currency       │
│  Converter      │
│  Service        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Print Service  │
│  (Format với    │
│   currency)     │
└─────────────────┘
```

### Implementation Steps

#### Step 1: Tạo Exchange Rate Entity & Model

**File:** `domain/lib/src/entity/exchange_rate_entity.dart`

```dart
class ExchangeRateEntity {
  final String fromCurrency;  // "VND"
  final String toCurrency;   // "USD"
  final double rate;          // Tỉ giá: 1 USD = ? VND
  final DateTime? lastUpdated;
  final String? source;       // "api", "manual"

  const ExchangeRateEntity({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    this.lastUpdated,
    this.source,
  });
}
```

**File:** `data/lib/src/model/exchange_rate_model.dart`

```dart
class ExchangeRateModel extends BaseModel {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime? lastUpdated;
  final String? source;

  ExchangeRateModel({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    this.lastUpdated,
    this.source,
  });

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      fromCurrency: json['from_currency'] ?? 'VND',
      toCurrency: json['to_currency'] ?? 'USD',
      rate: (json['rate'] ?? 0.0).toDouble(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'])
          : null,
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_currency': fromCurrency,
      'to_currency': toCurrency,
      'rate': rate,
      'last_updated': lastUpdated?.toIso8601String(),
      'source': source,
    };
  }
}
```

#### Step 2: Tạo Exchange Rate Repository

**File:** `domain/lib/src/repository/exchange_rate_repository.dart`

```dart
abstract class ExchangeRateRepository {
  Future<Either<Failure, ExchangeRateEntity>> getExchangeRate({
    String fromCurrency = 'VND',
    String toCurrency = 'USD',
  });

  Future<Either<Failure, void>> saveExchangeRate(ExchangeRateEntity rate);

  Future<Either<Failure, ExchangeRateEntity?>> getCachedExchangeRate({
    String fromCurrency = 'VND',
    String toCurrency = 'USD',
  });
}
```

**File:** `data/lib/src/repository/exchange_rate_repository_impl.dart`

```dart
class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  final ExchangeRateRemoteDataSource remoteDataSource;
  final ExchangeRateLocalDataSource localDataSource;

  ExchangeRateRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, ExchangeRateEntity>> getExchangeRate({
    String fromCurrency = 'VND',
    String toCurrency = 'USD',
  }) async {
    try {
      // Try to get from API first
      final remoteResult = await remoteDataSource.getExchangeRate(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );

      return remoteResult.fold(
        onSuccess: (model) async {
          final entity = _mapper.toEntity(model);
          // Cache the rate
          await localDataSource.saveExchangeRate(model);
          return Right(entity);
        },
        onError: (failure) async {
          // Fallback to cached rate
          final cachedResult = await getCachedExchangeRate(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
          );
          return cachedResult.fold(
            onSuccess: (cached) {
              if (cached != null) {
                return Right(cached);
              }
              return Left(failure);
            },
            onError: (_) => Left(failure),
          );
        },
      );
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveExchangeRate(
      ExchangeRateEntity rate) async {
    try {
      final model = _mapper.toModel(rate);
      await localDataSource.saveExchangeRate(model);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExchangeRateEntity?>> getCachedExchangeRate({
    String fromCurrency = 'VND',
    String toCurrency = 'USD',
  }) async {
    try {
      final model = await localDataSource.getExchangeRate(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );
      if (model != null) {
        return Right(_mapper.toEntity(model));
      }
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
```

#### Step 3: Tạo Exchange Rate Data Sources

**File:** `data/lib/src/data_source/remote/exchange_rate_remote_data_source.dart`

```dart
abstract class ExchangeRateRemoteDataSource {
  Future<Either<Failure, ExchangeRateModel>> getExchangeRate({
    String fromCurrency = 'VND',
    String toCurrency = 'USD',
  });
}

class ExchangeRateRemoteDataSourceImpl
    implements ExchangeRateRemoteDataSource {
  final ApiClient apiClient;

  ExchangeRateRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Either<Failure, ExchangeRateModel>> getExchangeRate({
    String fromCurrency = 'VND',
    String toCurrency = 'USD',
  }) async {
    try {
      // Option 1: Call your own API
      final response = await apiClient.get(
        '/api/exchange-rate',
        queryParameters: {
          'from': fromCurrency,
          'to': toCurrency,
        },
      );

      if (response.statusCode == 200) {
        final model = ExchangeRateModel.fromJson(response.data);
        return Right(model);
      }

      return Left(ServerFailure(
        message: 'Failed to fetch exchange rate',
        statusCode: response.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
```

**File:** `data/lib/src/data_source/local/exchange_rate_local_data_source.dart`

```dart
abstract class ExchangeRateLocalDataSource {
  Future<ExchangeRateModel?> getExchangeRate({
    String fromCurrency = 'VND',
    String toCurrency = 'USD',
  });

  Future<void> saveExchangeRate(ExchangeRateModel rate);

  Future<void> clearCache();
}

class ExchangeRateLocalDataSourceImpl
    implements ExchangeRateLocalDataSource {
  final SharedPreferences _prefs;

  ExchangeRateLocalDataSourceImpl({required SharedPreferences prefs})
      : _prefs = prefs;

  static const String _keyPrefix = 'exchange_rate_';

  String _getKey(String from, String to) =>
      '$_keyPrefix${from}_$to';

  @override
  Future<ExchangeRateModel?> getExchangeRate({
    String fromCurrency = 'VND',
    String toCurrency = 'USD',
  }) async {
    final key = _getKey(fromCurrency, toCurrency);
    final jsonString = _prefs.getString(key);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return ExchangeRateModel.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveExchangeRate(ExchangeRateModel rate) async {
    final key = _getKey(rate.fromCurrency, rate.toCurrency);
    final jsonString = jsonEncode(rate.toJson());
    await _prefs.setString(key, jsonString);
  }

  @override
  Future<void> clearCache() async {
    final keys = _prefs.getKeys()
        .where((k) => k.startsWith(_keyPrefix))
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
```

#### Step 4: Tạo Currency Converter Service

**File:** `lib/src/core/services/currency_converter_service.dart`

```dart
class CurrencyConverterService {
  final ExchangeRateRepository _exchangeRateRepository;

  CurrencyConverterService({
    ExchangeRateRepository? exchangeRateRepository,
  }) : _exchangeRateRepository =
            exchangeRateRepository ?? sl.get<ExchangeRateRepository>();

  /// Convert amount from VND to USD
  Future<double?> convertToUSD(double amountVND) async {
    final rateResult = await _exchangeRateRepository.getExchangeRate(
      fromCurrency: 'VND',
      toCurrency: 'USD',
    );

    return rateResult.fold(
      onSuccess: (rate) => amountVND / rate.rate,
      onError: (_) => null,
    );
  }

  /// Convert amount from USD to VND
  Future<double?> convertToVND(double amountUSD) async {
    final rateResult = await _exchangeRateRepository.getExchangeRate(
      fromCurrency: 'VND',
      toCurrency: 'USD',
    );

    return rateResult.fold(
      onSuccess: (rate) => amountUSD * rate.rate,
      onError: (_) => null,
    );
  }

  /// Format currency with symbol
  String formatCurrency(
    double amount, {
    String currency = 'VND',
    String? customSymbol,
  }) {
    final symbol = customSymbol ?? _getCurrencySymbol(currency);
    final formatted = Helper().formatCurrency(amount);
    return '$formatted $symbol';
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'VND':
        return '₫';
      default:
        return currency;
    }
  }

  /// Get cached exchange rate
  Future<ExchangeRateEntity?> getCachedRate() async {
    final result = await _exchangeRateRepository.getCachedExchangeRate();
    return result.fold(
      onSuccess: (rate) => rate,
      onError: (_) => null,
    );
  }
}
```

#### Step 5: Tạo Currency Selection Dialog

**File:** `lib/src/presentation/widgets/dialog/currency_selection_dialog.dart`

```dart
class CurrencySelectionDialog extends StatelessWidget {
  final ExchangeRateEntity? exchangeRate;
  final Function(String selectedCurrency) onCurrencySelected;

  const CurrencySelectionDialog({
    super.key,
    this.exchangeRate,
    required this.onCurrencySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemes.light;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr(LocaleKeys.selectCurrency),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (exchangeRate != null) ...[
              Text(
                '${l10n.tr(LocaleKeys.exchangeRate)}: 1 USD = ${Helper().formatCurrency(exchangeRate!.rate)} VND',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            _buildCurrencyOption(
              context,
              currency: 'VND',
              symbol: '₫',
              label: 'Vietnamese Dong',
            ),
            const SizedBox(height: 12),
            _buildCurrencyOption(
              context,
              currency: 'USD',
              symbol: '\$',
              label: 'US Dollar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(
    BuildContext context, {
    required String currency,
    required String symbol,
    required String label,
  }) {
    final theme = AppThemes.light;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onCurrencySelected(currency);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Step 6: Update Print Service để Support Multi-Currency

**File:** `lib/src/core/services/print_service.dart`

Thêm parameter `currency` và update format:

```dart
static Future<void> printInvoice({
  required int sellId,
  int? taxId,
  required BuildContext context,
  required String name,
  required String cashier,
  required String unit,
  required int locationId,
  required AppLocalizations l10n,
  required List<ProductEntity> products,
  String currency = 'VND',  // Thêm parameter mới
  ExchangeRateEntity? exchangeRate,  // Thêm parameter mới
}) async {
  // ... existing code ...

  final Uint8List pdfBytes = await _buildPdf(
    products: products,
    layoutBill: billEntity,
    sell: sellEntity,
    contact: contactEntity,
    unit: unit,
    l10n: l10n,
    cashier: cashier,
    currency: currency,  // Pass currency
    exchangeRate: exchangeRate,  // Pass exchange rate
  );

  // ... existing code ...
}
```

Update `_buildPdf` method:

```dart
static Future<Uint8List> _buildPdf({
  required List<ProductEntity> products,
  required LayoutBillEntity layoutBill,
  required SellEntity sell,
  required String unit,
  required String cashier,
  ContactEntity? contact,
  required AppLocalizations l10n,
  String currency = 'VND',  // Thêm parameter
  ExchangeRateEntity? exchangeRate,  // Thêm parameter
}) {
  // ... existing code ...

  // Convert amounts nếu currency là USD
  final double conversionRate = exchangeRate?.rate ?? 1.0;
  final bool isUSD = currency.toUpperCase() == 'USD';
  final String currencySymbol = isUSD ? '\$' : '₫';

  // Update total calculation với currency conversion
  final double total = sell.sellLines.fold(0, (e, s) {
    // ... existing discount calculation ...
    final lineTotal = subtotal - discount;
    final convertedTotal = isUSD ? lineTotal / conversionRate : lineTotal;
    return e + convertedTotal;
  });

  // Update payment lines với currency conversion
  final paymentLines = sell.payments.map((payment) {
    final amount = payment.amount ?? 0.0;
    final convertedAmount = isUSD ? amount / conversionRate : amount;
    return payment.copyWith(amount: convertedAmount);
  }).toList();

  // ... trong PDF generation, update formatCurrency calls:
  // Thay vì: Helper().formatCurrency(lineTotal)
  // Dùng: _formatCurrencyWithSymbol(lineTotal, currencySymbol, isUSD, conversionRate)

  // ... existing code ...
}

static String _formatCurrencyWithSymbol(
  double amount,
  String symbol,
  bool isUSD,
  double conversionRate,
) {
  final convertedAmount = isUSD ? amount / conversionRate : amount;
  final formatted = Helper().formatCurrency(convertedAmount);
  return '$formatted $symbol';
}
```

#### Step 7: Update Print Invoice Flow

**File:** `lib/src/presentation/pages/pos/pos_bloc.dart` hoặc nơi gọi print invoice

```dart
Future<void> _printInvoice(int sellId) async {
  final currencyConverter = sl.get<CurrencyConverterService>();
  
  // Get cached exchange rate
  final exchangeRate = await currencyConverter.getCachedRate();
  
  // Show currency selection dialog
  final selectedCurrency = await showDialog<String>(
    context: context,
    builder: (context) => CurrencySelectionDialog(
      exchangeRate: exchangeRate,
      onCurrencySelected: (currency) {
        Navigator.of(context).pop(currency);
      },
    ),
  );

  if (selectedCurrency == null) return; // User cancelled

  // If USD selected but no exchange rate, fetch it
  ExchangeRateEntity? rate = exchangeRate;
  if (selectedCurrency == 'USD' && rate == null) {
    final rateResult = await _exchangeRateRepository.getExchangeRate();
    rate = rateResult.fold(
      onSuccess: (r) => r,
      onError: (_) => null,
    );
    
    if (rate == null) {
      // Show error: Cannot get exchange rate
      ToastManager.showError(context, 'Cannot fetch exchange rate');
      return;
    }
  }

  // Print with selected currency
  await PrintService.printInvoice(
    sellId: sellId,
    // ... other parameters ...
    currency: selectedCurrency,
    exchangeRate: rate,
  );
}
```

#### Step 8: Register Dependencies

**File:** `lib/app_config/di.dart`

```dart
void _registerRepositories() {
  // ... existing repositories ...

  sl.registerLazy<ExchangeRateRepository>(() => ExchangeRateRepositoryImpl(
        remoteDataSource: sl.get<ExchangeRateRemoteDataSource>(),
        localDataSource: sl.get<ExchangeRateLocalDataSource>(),
      ));
}

void _registerServices() {
  // ... existing services ...

  sl.registerLazy<CurrencyConverterService>(() => CurrencyConverterService(
        exchangeRateRepository: sl.get<ExchangeRateRepository>(),
      ));
}

void _registerDataSources() {
  // ... existing data sources ...

  sl.registerLazy<ExchangeRateRemoteDataSource>(
    () => ExchangeRateRemoteDataSourceImpl(
      apiClient: sl.get<ApiClient>(),
    ),
  );

  sl.registerLazy<ExchangeRateLocalDataSource>(
    () => ExchangeRateLocalDataSourceImpl(
      prefs: sl.get<SharedPreferences>(),
    ),
  );
}
```

#### Step 9: Add Localization Keys

**File:** `lib/src/core/localization/locale_keys.dart`

```dart
class LocaleKeys {
  // ... existing keys ...
  
  static const selectCurrency = 'select_currency';
  static const exchangeRate = 'exchange_rate';
  static const vietnameseDong = 'vietnamese_dong';
  static const usDollar = 'us_dollar';
}
```

**File:** `lib/src/core/localization/app_localizations.dart` (hoặc translation files)

```json
{
  "select_currency": "Chọn loại tiền tệ",
  "exchange_rate": "Tỉ giá",
  "vietnamese_dong": "Đồng Việt Nam",
  "us_dollar": "Đô la Mỹ"
}
```

---

## 📝 Testing Checklist

### WebView Popup Testing

- [ ] Test popup hiển thị khi click button "Nhập số tiền vào ca"
- [ ] Test form input trong popup hoạt động bình thường
- [ ] Test submit form trong popup gửi data về main window
- [ ] Test close popup bằng nút X hoặc window.close()
- [ ] Test popup hoạt động trên cả Windows và Linux

### Multi-Currency Testing

- [ ] Test fetch exchange rate từ API
- [ ] Test cache exchange rate vào SharedPreferences
- [ ] Test load cached exchange rate khi offline
- [ ] Test currency selection dialog hiển thị đúng
- [ ] Test convert VND sang USD đúng với tỉ giá
- [ ] Test format currency với symbol đúng (₫ hoặc $)
- [ ] Test print invoice với VND
- [ ] Test print invoice với USD
- [ ] Test error handling khi không có exchange rate

---

## ⚠️ Lưu Ý

1. **Exchange Rate API**: Cần xác định API endpoint để lấy tỉ giá. Có thể:
   - Tạo API endpoint riêng trong backend
   - Sử dụng third-party API (như ExchangeRate-API, Fixer.io)
   - Cho phép admin nhập tỉ giá thủ công

2. **Exchange Rate Update**: Nên có cơ chế update tỉ giá định kỳ:
   - Auto-refresh mỗi X giờ
   - Manual refresh button
   - Background sync service

3. **Currency Precision**: USD thường có 2 decimal places, VND thường không có decimal. Cần format đúng.

4. **Historical Rates**: Có thể cần lưu tỉ giá theo thời gian để tính lại hóa đơn cũ.

5. **Multiple Currencies**: Hiện tại chỉ support VND và USD. Có thể mở rộng sau.

---

## 🚀 Implementation Priority

### Phase 1: WebView Popup Fix (High Priority)
1. Enable popup support trong WebView settings
2. Implement `onCreateWindow` callback
3. Test với popup thực tế

### Phase 2: Exchange Rate Infrastructure (Medium Priority)
1. Tạo Entity, Model, Repository
2. Tạo Data Sources (Remote & Local)
3. Register dependencies
4. Test API và caching

### Phase 3: Currency Selection UI (Medium Priority)
1. Tạo Currency Selection Dialog
2. Integrate vào print flow
3. Test UI/UX

### Phase 4: Print Service Update (Low Priority)
1. Update PrintService với currency support
2. Update PDF generation với currency conversion
3. Test print output

---

## 📚 References

- InAppWebView Documentation: https://inappwebview.dev/docs/
- Flutter Printing Package: https://pub.dev/packages/printing
- Exchange Rate APIs:
  - https://exchangerate-api.com/
  - https://fixer.io/
  - https://currencylayer.com/
