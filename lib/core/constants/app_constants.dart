/// Uygulama genelinde kullanılan sabitler
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Via';
  static const String appVersion = '1.0.0';

  // Firebase Collection İsimleri
  static const String usersCollection = 'users';
  static const String tripsCollection = 'trips';
  static const String placesCollection = 'places';

  // SharedPreferences Anahtarları
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyUserId = 'user_id';
  static const String keyIsAnonymous = 'is_anonymous';

  // Animasyon Süreleri
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Gezi Tercihleri
  static const List<String> travelPreferences = [
    'Kültür & Tarih',
    'Doğa & Manzara',
    'Yemek & Mutfak',
    'Macera & Spor',
    'Alışveriş',
    'Gece Hayatı',
    'Müze & Sanat',
    'Mimari',
  ];

  // Gemini Firebase Function URL (Cloud Function adı)
  static const String generateTripFunctionName = 'generateTrip';
  static const String getPlaceInfoFunctionName = 'getPlaceInfo';

  // Padding & Radius
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusCircular = 999.0;

  // Max gün sayısı
  static const int maxTripDays = 30;
  static const int minTripDays = 1;
}
