import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/logger_service.dart';
import 'backend_config.dart';

/// The single initialization/service boundary for Supabase.
///
/// Feature code in later phases MUST reach Supabase through a repository ->
/// data source chain, never by invoking the global `Supabase` API directly.
/// This service owns the only `Supabase.initialize(...)` call in the
/// application.
///
/// When no backend configuration is present the service stays unavailable and
/// does nothing, so the existing guest/local application continues exactly as
/// before.
class SupabaseService {
  SupabaseService({BackendConfig? config})
      : _config = config ?? BackendConfig.fromEnvironment();

  final BackendConfig _config;

  bool _isInitialized = false;

  /// The backend configuration this service was created with.
  BackendConfig get config => _config;

  /// Whether Supabase has been successfully initialized.
  bool get isInitialized => _isInitialized;

  /// Whether a valid backend configuration is available.
  ///
  /// This is false until a Supabase URL AND anon key are both configured AND
  /// `APP_ENV` resolves to a supported environment (development, staging or
  /// production). A missing/unknown `APP_ENV` keeps the backend unavailable.
  bool get isAvailable => _config.isAvailable;

  /// Initializes the Supabase client boundary when configuration allows it.
  ///
  /// Safe behavior:
  /// - No configuration  -> returns without action; [isInitialized] stays false.
  /// - Configured        -> initializes Supabase; failures are logged and never
  ///   bubble up to prevent breaking application startup.
  ///
  /// [initialize] is injectable for offline, deterministic tests; production
  /// callers omit it and use the real `Supabase.initialize`.
  Future<void> init({
    Future<void> Function({
      required String url,
      required String publishableKey,
    })? initialize,
  }) async {
    if (!_config.isAvailable) {
      LoggerService.debug(
        'Supabase backend not configured; service stays unavailable.',
      );
      _isInitialized = false;
      return;
    }

    final initFn = initialize ?? _defaultInitialize;
    try {
      await initFn(
        url: _config.supabaseUrl,
        publishableKey: _config.supabaseAnonKey,
      );
      _isInitialized = true;
      LoggerService.info(
        'Supabase backend initialized for environment: ${_config.environment.name}.',
      );
    } catch (error) {
      LoggerService.error('Supabase initialization failed', error);
      _isInitialized = false;
    }
  }

  static Future<void> _defaultInitialize({
    required String url,
    required String publishableKey,
  }) {
    return Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}
