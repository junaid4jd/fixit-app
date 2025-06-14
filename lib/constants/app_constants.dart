class AppConstants {
  // App Information
  static const String appName = 'Fixit Oman';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Fixit Oman LLC';

  // Theme Colors
  static const int primaryColorValue = 0xFF4169E1;
  static const int secondaryColorValue = 0xFF3A5FCD;

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String serviceProvidersCollection = 'service_providers';
  static const String bookingsCollection = 'bookings';
  static const String categoriesCollection = 'categories';
  static const String citiesCollection = 'cities';
  static const String reviewsCollection = 'reviews';
  static const String notificationsCollection = 'notifications';
  static const String identityVerificationsCollection = 'identity_verifications';
  static const String adminsCollection = 'admins';
  static const String chatMessagesCollection = 'chat_messages';

  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String workPhotosPath = 'work_photos';
  static const String documentsPath = 'documents';
  static const String categoryIconsPath = 'category_icons';

  // User Roles
  static const String roleUser = 'user';
  static const String roleServiceProvider = 'service_provider';
  static const String roleAdmin = 'admin';

  // Booking Status
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusRejected = 'rejected';

  // Default Values
  static const double defaultHourlyRate = 15.0;
  static const int defaultExperience = 1;
  static const double defaultRating = 5.0;
  static const int maxRating = 5;
  static const int minExperience = 1;
  static const int maxExperience = 30;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxCommentLength = 250;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Commission & Pricing
  static const double platformCommission = 0.10; // 10%
  static const double minimumBookingAmount = 10.0;
  static const double maximumBookingAmount = 1000.0;

  // Cities in Oman
  static const List<String> omanCities = [
    'Muscat',
    'Salalah',
    'Sohar',
    'Nizwa',
    'Sur',
    'Bahla',
    'Ibri',
    'Seeb',
    'Barka',
    'Rustaq',
    'Al Buraimi',
    'Muttrah',
    'Bawshar',
    'As Suwayq',
    'Saham',
    'Shinas',
    'Izki',
    'Bid Bid',
    'Khasab',
    'Mirbat',
  ];

  // Service Categories
  static const List<String> defaultServiceCategories = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'AC Repair',
    'Appliance Repair',
    'Cleaning',
    'Gardening',
    'Tiles & Flooring',
    'Handyman Services',
  ];

  // Notification Types
  static const String notificationBookingRequest = 'booking_request';
  static const String notificationBookingAccepted = 'booking_accepted';
  static const String notificationBookingRejected = 'booking_rejected';
  static const String notificationBookingCompleted = 'booking_completed';
  static const String notificationBookingCancelled = 'booking_cancelled';
  static const String notificationNewMessage = 'new_message';
  static const String notificationVerificationUpdate = 'verification_update';
  static const String notificationPromotion = 'promotion';

  // Error Messages
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorWeakPassword = 'Password must be at least 6 characters.';
  static const String errorUserNotFound = 'User not found.';
  static const String errorWrongPassword = 'Incorrect password.';
  static const String errorEmailInUse = 'Email is already registered.';
  static const String errorPermissionDenied = 'Permission denied.';
  static const String errorUnauthorized = 'Unauthorized access.';

  // Success Messages
  static const String successRegistration = 'Account created successfully!';
  static const String successLogin = 'Logged in successfully!';
  static const String successBooking = 'Booking created successfully!';
  static const String successProfileUpdate = 'Profile updated successfully!';
  static const String successPasswordReset = 'Password reset email sent!';
  static const String successVerification = 'Verification submitted successfully!';

  // Image Quality & Size
  static const int imageQuality = 80;
  static const double maxImageSize = 2.0; // MB
  static const int thumbnailSize = 200;
  static const int profileImageSize = 400;

  // Time & Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy at hh:mm a';

  // Animation Durations (in milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 400;
  static const int longAnimationDuration = 800;

  // API & Network
  static const int requestTimeout = 30; // seconds
  static const int retryAttempts = 3;

  // Local Storage Keys
  static const String keyUserRole = 'user_role';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyDarkMode = 'dark_mode';
  static const String keyLanguage = 'language';

  // Support Information
  static const String supportEmail = 'support@fixit-oman.com';
  static const String supportPhone = '+968 9999 9999';
  static const String websiteUrl = 'https://fixit-oman.com';
  static const String privacyPolicyUrl = 'https://fixit-oman.com/privacy';
  static const String termsOfServiceUrl = 'https://fixit-oman.com/terms';
}

class AppStrings {
  // Common
  static const String loading = 'Loading...';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String view = 'View';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String sort = 'Sort';
  static const String selectAll = 'Select All';
  static const String clearAll = 'Clear All';
  static const String noData = 'No data available';
  static const String comingSoon = 'Coming Soon';

  // Authentication
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String phoneNumber = 'Phone Number';

  // Navigation
  static const String home = 'Home';
  static const String bookings = 'Bookings';
  static const String profile = 'Profile';
  static const String notifications = 'Notifications';
  static const String settings = 'Settings';
  static const String help = 'Help';
  static const String about = 'About';

  // Booking
  static const String bookService = 'Book Service';
  static const String serviceDetails = 'Service Details';
  static const String selectDate = 'Select Date';
  static const String selectTime = 'Select Time';
  static const String address = 'Address';
  static const String description = 'Description';
  static const String estimatedCost = 'Estimated Cost';
  static const String finalCost = 'Final Cost';
  static const String payNow = 'Pay Now';
  static const String rateService = 'Rate Service';

  // Service Provider
  static const String handyman = 'Handyman';
  static const String hourlyRate = 'Hourly Rate';
  static const String experience = 'Experience';
  static const String rating = 'Rating';
  static const String verified = 'Verified';
  static const String available = 'Available';
  static const String unavailable = 'Unavailable';
  static const String workPhotos = 'Work Photos';
  static const String reviews = 'Reviews';

  // Admin
  static const String dashboard = 'Dashboard';
  static const String userManagement = 'User Management';
  static const String serviceProviderManagement = 'Service Provider Management';
  static const String categoryManagement = 'Category Management';
  static const String analytics = 'Analytics';
  static const String reports = 'Reports';
  static const String verifications = 'Verifications';

  // Validation Messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String invalidPhoneNumber = 'Please enter a valid phone number';
}

class AppRoutes {
  static const String splash = '/';
  static const String roleSelection = '/role-selection';
  static const String userSignIn = '/user-signin';
  static const String userSignUp = '/user-signup';
  static const String userHome = '/user-home';
  static const String serviceProviderSignIn = '/sp-signin';
  static const String serviceProviderSignUp = '/sp-signup';
  static const String serviceProviderHome = '/sp-home';
  static const String adminSignIn = '/admin-signin';
  static const String adminDashboard = '/admin-dashboard';
  static const String booking = '/booking';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String payment = '/payment';
}