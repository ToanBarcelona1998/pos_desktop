/// Defines API endpoints used across mobile and desktop platforms.
abstract final class ApiEndPoints {
  static String baseUrl = 'https://sandbox.oman.digityze.asia';
  static String apiUrl = '/connector/api';

  //#region used by http

  /// Auth endpoints
  static String loginUrl = '$baseUrl/oauth/token';
  static String getUser = '$baseUrl$apiUrl/user/loggedin';

  /// Attendance endpoints
  static String checkIn = '$baseUrl$apiUrl/clock-in';
  static String checkOut = '$baseUrl$apiUrl/clock-out';
  static String getAttendance = '$baseUrl$apiUrl/get-attendance/';

  /// Contact endpoints
  static String contact = '$baseUrl$apiUrl/contactapi';
  static String getContact = '$contact?type=customer&per_page=750';
  static String addContact = '$contact?type=customer';
  // Contact payment
  static String customerDue = '$contact/';
  static String addContactPayment = '$contact-payment';

  //#endregion

  //#region used by Dio

  /// Notifications
  static String allNotifications = '$apiUrl/notifications';

  /// Brands
  static String allBrands = '$apiUrl/brand';

  /// Purchases
  static String purchases = '$apiUrl/purchases';

  /// Products
  static String products = '$apiUrl/product';

  /// Sell endpoints
  static String sell = '$apiUrl/sell'; // Added sell endpoint


//#endregion
}