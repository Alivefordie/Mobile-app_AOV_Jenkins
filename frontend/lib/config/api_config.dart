class ApiConfig {
  const ApiConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
    //defaultValue: 'http://localhost:3000',
  );

  static const profileUserId = String.fromEnvironment(
    'PROFILE_USER_ID',
    defaultValue: '33ca0640-a0ea-4283-84e3-e5deb8c724bb',
  );
}
