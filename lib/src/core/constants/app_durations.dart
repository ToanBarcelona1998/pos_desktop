/// Application duration constants for animations
abstract final class AppDurations {
  // Animation durations
  static const Duration instant = Duration.zero;
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 700);

  // Page transition
  static const Duration pageTransition = Duration(milliseconds: 300);

  // Snackbar duration
  static const Duration snackbarShort = Duration(seconds: 2);
  static const Duration snackbarNormal = Duration(seconds: 4);
  static const Duration snackbarLong = Duration(seconds: 6);

  // Debounce durations
  static const Duration debounceShort = Duration(milliseconds: 300);
  static const Duration debounceNormal = Duration(milliseconds: 500);
  static const Duration debounceLong = Duration(milliseconds: 1000);

  // Timeout durations
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
}









