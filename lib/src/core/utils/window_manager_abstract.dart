/// Window type enum
enum WindowType {
  offlineCustomer,
  onlineCustomer,
}

/// Window status
class WindowStatus {
  final bool isOpen;
  final WindowType? type;
  
  WindowStatus({required this.isOpen, this.type});
}

/// Abstract window manager interface for platform-agnostic window management
abstract class WindowManagerAbstract {
  /// Open customer window
  Future<void> openCustomerWindow({
    required WindowType type,
    Map<String, dynamic>? params,
  });
  
  /// Close customer window
  Future<void> closeCustomerWindow();
  
  /// Show customer window (if hidden)
  Future<void> showCustomerWindow();
  
  /// Hide customer window
  Future<void> hideCustomerWindow();
  
  /// Check if customer window is open
  Future<bool> isCustomerWindowOpen();
  
  /// Stream of window status changes
  Stream<WindowStatus> get windowStatusStream;
  
  /// Dispose resources
  void dispose();
}
