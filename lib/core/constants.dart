class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl =
      'https://pass-man.site/api'; // Android emulator
  static const String apiBaseUrlDesktop = 'https://pass-man.site/api';

  // Argon2 parameters
  static const int argon2Memory = 65536; // 64 MB
  static const int argon2Iterations = 3;
  static const int argon2Parallelism = 1;
  static const int keyLength = 32; // 256 bits

  // Auto-lock
  static const int autoLockTimeoutSeconds = 300; // 5 minutes
}
