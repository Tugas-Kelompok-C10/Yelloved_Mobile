class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cindy-olivia-yelloved.pws.cs.ui.ac.id',
  );
}
