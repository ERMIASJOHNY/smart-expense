class AppConstants {
  static const double padding = 24.0;
  static const double borderRadius = 16.0;

  // Cybersecurity Validation Regex
  // At least 10 characters, at least one uppercase, one lowercase, one number and one special character
  static final RegExp passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{10,}$',
  );

  static final RegExp emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );
}
