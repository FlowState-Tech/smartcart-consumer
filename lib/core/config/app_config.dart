/// App-wide configuration. Override at build time with dart-define:
/// `flutter run --dart-define=API_BASE_URL=... --dart-define=GOOGLE_MAPS_API_KEY=...`
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://smartcart-api-production.up.railway.app/api/v1',
  );

  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
}
