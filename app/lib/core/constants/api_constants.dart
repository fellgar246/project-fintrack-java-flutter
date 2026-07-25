/// Base URL de la API. Configurable en build/run con:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`
/// (el emulador Android no resuelve `localhost` al host, usa `10.0.2.2`).
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api/v1',
);
