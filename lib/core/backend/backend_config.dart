import 'app_environment.dart';

/// Typed, single-source-of-truth backend configuration.
///
/// The application never reads environment variables directly; it always
/// consults an instance of this model (typically the one produced by
/// [BackendConfig.fromEnvironment]).
///
/// Credentials are provided at compile time via dart-define and are NEVER
/// hardcoded or committed. Only the public/anon key is ever supplied to the
/// client — the `service_role` key must never cross into Flutter code.
class BackendConfig {
  const BackendConfig({
    required this.appEnvRaw,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  /// The raw `APP_ENV` dart-define string.
  final String appEnvRaw;

  /// The Supabase project URL, or empty when not configured.
  final String supabaseUrl;

  /// The public/anon (publishable) Supabase client key, or empty when unset.
  final String supabaseAnonKey;

  /// True only when a Supabase endpoint AND a public anon key are configured
  /// AND `APP_ENV` explicitly resolves to a supported environment.
  ///
  /// An empty/incomplete configuration OR an absent/unrecognised `APP_ENV`
  /// intentionally yields `isAvailable == false` so the existing
  /// guest/local-only application keeps launching normally without any backend.
  bool get isAvailable =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      environment != AppEnvironment.unknown;

  /// The logical [AppEnvironment] for this configuration.
  ///
  /// An absent or unrecognised `APP_ENV` resolves to
  /// [AppEnvironment.unknown] — a safe, non-production behaviour.
  AppEnvironment get environment => AppEnvironment.fromName(appEnvRaw);

  /// Builds the configuration from compile-time dart-define values.
  ///
  /// This is the single place the app reads environment variables. It is
  /// intentionally safe: when a variable is absent the field is empty and
  /// [isAvailable] is false.
  factory BackendConfig.fromEnvironment() => const BackendConfig(
        appEnvRaw: String.fromEnvironment('APP_ENV', defaultValue: ''),
        supabaseUrl: String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
        supabaseAnonKey:
            String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
      );
}
