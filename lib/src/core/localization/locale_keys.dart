/// Localization keys for the application
/// Use these constants instead of hardcoding strings
abstract final class LocaleKeys {
  // Auth
  static const String login = 'login';
  static const String logout = 'logout';
  static const String logOut = 'log_out';
  static const String logIn = 'log_in';
  static const String welcome = 'welcome';
  static const String username = 'username';
  static const String password = 'password';
  static const String pleaseEnterUsername = 'please_enter_username';
  static const String pleaseEnterPassword = 'please_enter_password';
  static const String invalidCredentials = 'invalid_credentials';
  static const String noAccount = 'no_account';
  static const String register = 'register';
  static const String signUp = 'sign_up';
  static const String forgetPassword = 'forget_password';
  static const String quickLogin = 'quick_login';
  static const String confirmPassword = 'confirm_password';
  static const String currentPassword = 'current_password';
  static const String newPassword = 'new_password';
  static const String updatePassword = 'update_password';
  static const String passwordsDoNotMatch = 'passwords_do_not_match';

  // Common
  static const String loading = 'loading';
  static const String loadingData = 'loading_data';
  static const String ok = 'ok';
  static const String cancel = 'cancel';
  static const String yes = 'yes';
  static const String no = 'no';
  static const String save = 'save';
  static const String submit = 'submit';
  static const String update = 'update';
  static const String delete = 'delete';
  static const String edit = 'edit';
  static const String add = 'add';
  static const String close = 'close';
  static const String confirm = 'confirm';
  static const String reset = 'reset';
  static const String refresh = 'refresh';
  static const String search = 'search';
  static const String filter = 'filter';
  static const String sort = 'sort';
  static const String sortBy = 'sort_by';
  static const String select = 'select';
  static const String next = 'next';
  static const String back = 'back';
  static const String export = 'export';
  static const String details = 'details';
  static const String noData = 'no_data';
  static const String required = 'required';
  static const String actions = 'actions';
  static const String status = 'status';
  static const String type = 'type';
  static const String name = 'name';
  static const String description = 'description';
  static const String title = 'title';
  static const String date = 'date';
  static const String note = 'note';
  static const String value = 'value';
  static const String all = 'all';
  static const String none = 'none';

  // Navigation
  static const String home = 'home';
  static const String dashboard = 'dashboard';
  static const String settings = 'settings';
  static const String profile = 'profile';
  static const String reports = 'reports';
  static const String notifications = 'notifications';
  static const String help = 'help';

  // Products
  static const String products = 'products';
  static const String product = 'product';
  static const String productDetails = 'product_details';
  static const String productsList = 'products_list';
  static const String addProduct = 'add_product';
  static const String noProductsFound = 'no_products_found';
  static const String noProductsAvailable = 'no_products_available';
  static const String searchProducts = 'search_products';
  static const String loadingProducts = 'loading_products';
  static const String failedToLoadProducts = 'failed_to_load_products';
  static const String productsRefreshed = 'products_refreshed';
  static const String sku = 'sku';
  static const String price = 'price';
  static const String unitPrice = 'unit_price';
  static const String quantity = 'quantity';
  static const String stock = 'stock';
  static const String inStock = 'in_stock';
  static const String outOfStock = 'out_of_stock';
  static const String lowStock = 'low_stock';
  static const String stockAlerts = 'stock_alerts';
  static const String stockAvailable = 'stock_available';

  // Cart & Checkout
  static const String cart = 'cart';
  static const String cartEmpty = 'cart_empty';
  static const String addToCart = 'add_item_to_cart';
  static const String addedToCart = 'added_to_cart';
  static const String checkout = 'checkout';
  static const String payAndCheckout = 'pay_and_checkout';
  static const String total = 'total';
  static const String subTotal = 'sub_total';
  static const String discount = 'discount';
  static const String discountType = 'discount_type';
  static const String discountAmount = 'discount_amount';
  static const String tax = 'tax';
  static const String totalPayable = 'total_payable';
  static const String totalPaying = 'total_paying';
  static const String priceAfterTax = 'price_after_tax';
  static const String pricePay = 'price_pay';
  static const String changeReturn = 'change_return';
  static const String balance = 'balance';
  static const String remaining = 'remaining';

  // Customer
  static const String customer = 'customer';
  static const String customers = 'customers';
  static const String customerName = 'customer_name';
  static const String selectCustomer = 'select_customer';
  static const String searchCustomer = 'search_customer';
  static const String contacts = 'contacts';
  static const String createContact = 'create_contact';

  // Sales
  static const String sales = 'sales';
  static const String posSales = 'pos_sales';
  static const String recentSales = 'recent_sales';
  static const String allSales = 'all_sales';
  static const String totalSales = 'total_sales';
  static const String numberOfSales = 'number_of_sales';
  static const String salesAmount = 'sales_amount';
  static const String salesChart = 'sales_chart';
  static const String salesDues = 'sales_dues';
  static const String noSalesData = 'no_sales_data';
  static const String noSalesDues = 'no_sales_dues';
  static const String failedToLoadSales = 'failed_to_load_sales';

  // Invoice
  static const String invoice = 'invoice';
  static const String invoiceNo = 'invoice_no';
  static const String invoiceAmount = 'invoice_amount';
  static const String invoiceStatus = 'invoice_status';
  static const String invoiceSuccess = 'invoice_success';
  static const String createInvoice = 'create_invoice';
  static const String printInvoice = 'print_invoice';
  static const String selectInvoiceType = 'select_invoice_type';
  static const String quotation = 'quotation';
  static const String addQuotation = 'add_quotation';
  static const String quotationAdded = 'quotation_added';
  static const String draft = 'draft';
  static const String final_ = 'final';

  // Payment
  static const String payment = 'payment';
  static const String payments = 'payments';
  static const String addPayment = 'add_payment';
  static const String paymentMethod = 'payment_method';
  static const String selectPaymentMethod = 'select_payment_method';
  static const String paymentDetails = 'payment_details';
  static const String paymentStatus = 'payment_status';
  static const String paymentNote = 'payment_note';
  static const String paymentDate = 'payment_date';
  static const String paymentAmount = 'payment_amount';
  static const String paymentSuccessful = 'payment_successful';
  static const String paymentAdded = 'payment_added';
  static const String paymentRemoved = 'payment_removed';
  static const String paymentError = 'payment_error';
  static const String paymentMethodRequired = 'payment_method_required';
  static const String amountRequired = 'amount_required';
  static const String paid = 'paid';
  static const String paidAmount = 'paid_amount';
  static const String dueAmount = 'due_amount';
  static const String due = 'due';
  static const String pending = 'pending';
  static const String pendingAmount = 'pending_amount';
  static const String partial = 'partial';
  static const String overdue = 'overdue';
  static const String cash = 'cash';
  static const String card = 'card';
  static const String cheque = 'cheque';
  static const String bankTransfer = 'bank_transfer';
  static const String multiPayment = 'multi_payment';

  // Purchase
  static const String purchases = 'purchases';
  static const String purchase = 'purchase';
  static const String addPurchase = 'add_purchase';
  static const String totalPurchase = 'total_purchase';
  static const String purchaseDate = 'purchase_date';
  static const String purchaseDues = 'purchase_dues';
  static const String noPurchaseDues = 'no_purchase_dues';
  static const String purchaseSuccess = 'purchase_success';
  static const String purchaseFailed = 'purchase_failed';

  // Expenses
  static const String expenses = 'expenses';
  static const String addExpenses = 'add_expenses';
  static const String expenseAmount = 'expense_amount';
  static const String expenseNote = 'expense_note';
  static const String expenseDetails = 'expense_details';
  static const String expenseCategories = 'expense_categories';
  static const String expenseAddedSuccessfully = 'expense_added_successfully';
  static const String totalExpense = 'total_expense';

  // Brands
  static const String brands = 'brands';
  static const String brand = 'brand';
  static const String allBrands = 'all_brands';
  static const String addBrand = 'add_brand';
  static const String editBrand = 'edit_brand';
  static const String brandName = 'brand_name';
  static const String totalBrands = 'total_brands';
  static const String brandAddedSuccessfully = 'brand_added_successfully';
  static const String brandUpdatedSuccessfully = 'brand_updated_successfully';
  static const String brandDeletedSuccessfully = 'brand_deleted_successfully';
  static const String failedToLoadBrands = 'failed_to_load_brands';
  static const String failedToAddBrand = 'failed_to_add_brand';
  static const String failedToUpdateBrand = 'failed_to_update_brand';
  static const String failedToDeleteBrand = 'failed_to_delete_brand';

  // Categories
  static const String categories = 'categories';
  static const String category = 'category';
  static const String selectCategory = 'select_category';
  static const String subCategories = 'sub_categories';
  static const String selectSubCategory = 'select_sub_category';
  static const String categoryName = 'category_name';
  static const String allCategories = 'all_categories';

  // Units
  static const String units = 'units';
  static const String unit = 'unit';
  static const String totalUnits = 'total_units';
  static const String baseUnits = 'base_units';
  static const String subUnits = 'sub_units';
  static const String unitAddedSuccessfully = 'unit_added_successfully';
  static const String unitUpdatedSuccessfully = 'unit_updated_successfully';
  static const String unitDeletedSuccessfully = 'unit_deleted_successfully';
  static const String failedToLoadUnits = 'failed_to_load_units';

  // Location
  static const String location = 'location';
  static const String locationName = 'location_name';
  static const String selectLocation = 'select_location';
  static const String changeLocation = 'change_location';
  static const String businessLocation = 'business_location';
  static const String selectBranch = 'select_branch';
  static const String pleaseSelectBranch = 'please_select_branch';

  // User
  static const String users = 'users';
  static const String user = 'user';
  static const String addUser = 'add_user';
  static const String editUser = 'edit_user';
  static const String userDetails = 'user_details';
  static const String userType = 'user_type';
  static const String usersList = 'users_list';
  static const String searchUsers = 'search_users';
  static const String firstName = 'first_name';
  static const String lastName = 'last_name';
  static const String middleName = 'middle_name';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String mobileNo = 'mobile_no';
  static const String contactNumber = 'contact_number';
  static const String address = 'address';

  // Sync
  static const String sync = 'sync';
  static const String syncDone = 'sync_done';
  static const String syncFailed = 'sync_failed';
  static const String syncCompleted = 'sync_completed';
  static const String syncInProgress = 'sync_in_progress';
  static const String syncSuccess = 'sync_success';
  static const String pendingSync = 'pending_sync';
  static const String syncAllSalesBeforeLogout = 'sync_all_sales_before_logout';
  static const String logoutWithoutSync = 'logout_without_sync';

  // Date/Time
  static const String today = 'today';
  static const String yesterday = 'yesterday';
  static const String tomorrow = 'tomorrow';
  static const String thisWeek = 'this_week';
  static const String lastWeek = 'last_week';
  static const String thisMonth = 'this_month';
  static const String lastMonth = 'last_month';
  static const String thisYear = 'this_year';
  static const String lastYear = 'last_year';
  static const String last7Days = 'last_7_days';
  static const String last30Days = 'last_30_days';
  static const String last90Days = 'last_90_days';
  static const String customRange = 'custom_range';
  static const String selectRange = 'select_range';

  // Reports
  static const String report = 'report';
  static const String overviewReports = 'overview_reports';
  static const String profitAndLoss = 'profit_and_loss';
  static const String productsStock = 'products_stock';
  static const String netProfit = 'net_profit';
  static const String grossProfit = 'gross_profit';
  static const String statistics = 'statistics';
  static const String overview = 'overview';

  // Errors
  static const String somethingWentWrong = 'something_went_wrong';
  static const String noInternet = 'no_internet';
  static const String checkConnectivity = 'check_connectivity';
  static const String errorLoadingData = 'error_loading_data';
  static const String refreshFailed = 'refresh_failed';
  static const String failedToLoadDashboard = 'failed_to_load_dashboard';
  static const String unauthorised = 'unauthorised';
  static const String noTokenAvailable = 'no_token_available';

  // Confirmation Messages
  static const String areYouSure = 'are_you_sure';
  static const String areYouSureDelete = 'are_you_sure_delete';
  static const String areYouSureCancel = 'are_you_sure_cancel';
  static const String proceedAnyway = 'proceed_anyway';
  static const String printInvoiceConfirmation = 'print_invoice_confirmation';

  // Settings
  static const String language = 'language';
  static const String chooseLanguage = 'choose_language';
  static const String darkTheme = 'dark_theme';
  static const String appVersion = 'app_version';
  static const String version = 'version';

  // Greetings
  static const String goodMorning = 'good_morning';
  static const String goodAfternoon = 'good_afternoon';
  static const String goodEvening = 'good_evening';

  // Suppliers
  static const String suppliers = 'suppliers';
  static const String supplier = 'supplier';
  static const String selectSupplier = 'select_supplier';
  static const String suppliersCustomers = 'suppliers_customers';

  // Customers
  static const String noCustomersFound = 'no_customers_found';
  static const String addCustomer = 'add_customer';

  // Suspended Sales
  static const String suspendedSales = 'suspended_sales';
  static const String continueSale = 'continue';
  static const String suspendedSaleLoaded = 'suspended_sale_loaded';
  static const String suspendedSaleDeleted = 'suspended_sale_deleted';

  // Shipping
  static const String shipment = 'shipment';
  static const String shippingCharges = 'shipping_charges';
  static const String shippingDetails = 'shipping_details';
  static const String shippingAddress = 'shipping_address';
  static const String deliveredTo = 'delivered_to';
  static const String selectShippingStatus = 'select_shipping_status';
  static const String ordered = 'ordered';
  static const String packed = 'packed';
  static const String shipped = 'shipped';
  static const String delivered = 'delivered';
  static const String returned = 'returned';
  static const String cancelled = 'cancelled';

  // Misc
  static const String quickActions = 'quick_actions';
  static const String dataRefreshed = 'data_refreshed';
  static const String comingSoon = 'coming_soon';
  static const String underDevelopment = 'under_development';
  static const String pos = 'pos';
  static const String calculator = 'calculator';
  static const String notes = 'notes';
  static const String todo = 'todo';
  static const String summary = 'summary';
  static const String totalItems = 'total_items';
  static const String items = 'items';

  // POS Online
  static const String posOnline = 'pos_online';
  static const String syncData = 'sync_data';
  static const String authenticationFailed = 'authentication_failed';
  static const String error = 'error';
  static const String loggedOutSuccessfully = 'logged_out_successfully';
  static const String syncCompletedSuccessfully = 'sync_completed_successfully';
  static const String syncError = 'sync_error';
  static const String pendingSynchronization = 'pending_synchronization';
  static const String unsyncedSalesCount = 'unsynced_sales_count';
  static const String syncAndLogout = 'sync_and_logout';
  static const String logoutError = 'logout_error';
  static const String syncingSystemData = 'syncing_system_data';
  static const String syncingUnsyncedSales = 'syncing_unsynced_sales';
  static const String syncing = 'syncing';
  static const String networkConnectionIssue = 'network_connection_issue';
  static const String switchToOfflineMode = 'switch_to_offline_mode';

  // POS Messages
  static const String pleaseSelectCustomerAndAddItems = 'please_select_customer_and_add_items';
  static const String cartIsEmpty = 'cart_is_empty';
  static const String creditSaleCreatedSuccessfully = 'credit_sale_created_successfully';
  static const String draftCreatedSuccessfully = 'draft_created_successfully';
  static const String quotationCreatedSuccessfully = 'quotation_created_successfully';
  static const String saleSuspendedSuccessfully = 'sale_suspended_successfully';
  static const String saleCompletedSuccessfully = 'sale_completed_successfully';
  
  // POS Actions
  static const String suspend = 'suspend';
  static const String credit = 'credit';
  static const String methods = 'methods';
  static const String history = 'history';
  static const String filters = 'filters';
  static const String subtotal = 'subtotal';

  static const String previousPayments = 'previous_payments';
}






