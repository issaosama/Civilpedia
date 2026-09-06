/// Logical runtime environments supported by the backend configuration.
///
/// Selection happens explicitly and deterministically at build time via the
/// `APP_ENV` dart-define. There is intentionally NO implicit production
/// default: an absent or unrecognised value resolves to [unknown], which keeps
/// backend behaviour disabled rather than accidentally targeting a live
/// environment.
enum AppEnvironment {
  development,
  staging,
  production,
  unknown;

  /// Parses a raw environment name into a logical [AppEnvironment].
  ///
  /// Matching is case-insensitive. Anything that is not `development`,
  /// `staging` or `production` resolves to [unknown].
  static AppEnvironment fromName(String name) {
    switch (name.trim().toLowerCase()) {
      case 'development':
        return AppEnvironment.development;
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
        return AppEnvironment.production;
      default:
        return AppEnvironment.unknown;
    }
  }
}
