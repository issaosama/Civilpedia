class SentryConfig {
  const SentryConfig._();

  static const String dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static bool get isEnabled => dsn.isNotEmpty;
}
