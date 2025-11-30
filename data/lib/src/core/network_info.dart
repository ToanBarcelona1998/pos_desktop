import 'dart:async';
import 'dart:io';

/// Abstract class for network information
abstract class NetworkInfo {
  /// Check if device is connected to internet
  Future<bool> get isConnected;

  /// Quick check - uses cached status if available
  bool get isConnectedSync;

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged;

  /// Force refresh connectivity status
  Future<bool> refreshConnectivity();
}

/// Implementation of NetworkInfo with fast local fallback
class NetworkInfoImpl implements NetworkInfo {
  static const Duration _checkTimeout = Duration(milliseconds: 800);
  static const Duration _cacheValidityDuration = Duration(seconds: 30);

  bool? _cachedStatus;
  DateTime? _lastCheckTime;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  NetworkInfoImpl() {
    // Initial check
    _checkConnectivity();
  }

  @override
  bool get isConnectedSync {
    // Return cached status immediately if available and recent
    if (_cachedStatus != null && _isCacheValid) {
      return _cachedStatus!;
    }
    // Trigger async check and return optimistic false for faster local data access
    _checkConnectivity();
    return _cachedStatus ?? false;
  }

  @override
  Future<bool> get isConnected async {
    // Return cached status if still valid
    if (_cachedStatus != null && _isCacheValid) {
      return _cachedStatus!;
    }
    return _checkConnectivity();
  }

  bool get _isCacheValid {
    if (_lastCheckTime == null) return false;
    return DateTime.now().difference(_lastCheckTime!) < _cacheValidityDuration;
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(_checkTimeout);
      
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateStatus(connected);
      return connected;
    } on SocketException catch (_) {
      _updateStatus(false);
      return false;
    } on TimeoutException catch (_) {
      _updateStatus(false);
      return false;
    } catch (_) {
      _updateStatus(false);
      return false;
    }
  }

  void _updateStatus(bool connected) {
    final changed = _cachedStatus != connected;
    _cachedStatus = connected;
    _lastCheckTime = DateTime.now();
    
    if (changed) {
      _connectivityController.add(connected);
    }
  }

  @override
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  @override
  Future<bool> refreshConnectivity() async {
    _cachedStatus = null;
    _lastCheckTime = null;
    return _checkConnectivity();
  }

  void dispose() {
    _connectivityController.close();
  }
}
