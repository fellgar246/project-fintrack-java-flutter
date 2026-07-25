/// API base URL. Configurable at build/run time with:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`
/// (the Android emulator doesn't resolve `localhost` to the host, use `10.0.2.2`).
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api/v1',
);
