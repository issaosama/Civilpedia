import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_recovery_library.dart';
import '../network/remote_operation_policy.dart';
import '../services/logger_service.dart';
import 'backend_config.dart';

enum SupabaseServiceState { unavailable, initializing, ready }

/// The single initialization/service boundary for Supabase.
///
/// Feature code reaches Supabase through repository/gateway boundaries. The
/// service owns the only `Supabase.initialize(...)` call and exposes dynamic
/// readiness so the same dependency graph remains usable when a bounded
/// startup wait expires and initialization later succeeds.
class SupabaseService extends ChangeNotifier {
  SupabaseService({
    BackendConfig? config,
    FlutterAuthClientOptions? authOptions,
    LocalStorage? recoveryDelegate,
  })  : _config = config ?? BackendConfig.fromEnvironment(),
        _authOptions = authOptions,
        _recoveryDelegate = recoveryDelegate;

  final BackendConfig _config;
  final FlutterAuthClientOptions? _authOptions;
  final LocalStorage? _recoveryDelegate;
  AuthRecoveryStorageCoordinator? _recoveryCoordinator;

  bool _isInitialized = false;
  SupabaseServiceState _state = SupabaseServiceState.unavailable;
  InfrastructureFailure? _initializationFailure;
  Future<void>? _initializationOperation;
  bool _disposed = false;

  BackendConfig get config => _config;

  bool get isInitialized => _isInitialized;

  SupabaseServiceState get state => _state;

  InfrastructureFailure? get initializationFailure => _initializationFailure;

  /// The current recovery state. Re-reads from the coordinator on every access
  /// so later state changes are reflected immediately.
  ///
  /// `null` when the service was initialized with a custom [initialize]
  /// function that bypasses the recovery foundation (test seams).
  AuthRecoveryState? get recoveryState => _recoveryCoordinator?.readRecoveryState();

  /// The single recovery serialization boundary used during initialization.
  ///
  /// Later C2/C3 recovery must use this exact coordinator so that journal
  /// transitions and SDK persisted-session access share one queue.
  AuthRecoveryStorageCoordinator? get recoveryCoordinator => _recoveryCoordinator;

  /// Whether valid build-time backend configuration is present. Runtime
  /// request availability still requires [isInitialized].
  bool get isAvailable => _config.isAvailable;

  /// Starts or joins the one Supabase initialization operation and bounds how
  /// long the local application waits for it. If the deadline expires, this
  /// method returns safely with an unavailable state so `runApp` can proceed.
  /// The same operation may still complete later; a late success transitions
  /// this service to [SupabaseServiceState.ready].
  Future<void> init({
    Future<void> Function({
      required String url,
      required String publishableKey,
    })?
    initialize,
    Duration timeout = RemoteOperationPolicy.serviceInitialization,
  }) async {
    if (!_config.isAvailable) {
      LoggerService.debug(
        'Supabase backend not configured; service stays unavailable.',
      );
      _isInitialized = false;
      _initializationFailure = const InfrastructureFailure(
        InfrastructureFailureKind.serviceUnavailable,
      );
      _setState(SupabaseServiceState.unavailable);
      return;
    }
    if (_isInitialized) return;

    final operation = _initializationOperation ??=
        _runInitialization(initialize);
    try {
      await runWithRemoteDeadline(operation, timeout: timeout);
    } on InfrastructureFailureException catch (error) {
      _isInitialized = false;
      _initializationFailure = error.failure;
      _setState(SupabaseServiceState.unavailable);
      LoggerService.warning(
        'Supabase initialization exceeded the application deadline; '
        'local startup continues.',
      );
    }
  }

  Future<void> _runInitialization(
    Future<void> Function({required String url, required String publishableKey})?
    initFn,
  ) async {
    _initializationFailure = null;
    _recoveryCoordinator = null;
    _setState(SupabaseServiceState.initializing);
    try {
      if (initFn != null) {
        await initFn(
          url: _config.supabaseUrl,
          publishableKey: _config.supabaseAnonKey,
        );
      } else {
        await _initializeWithRecoveryGuard();
      }
      _isInitialized = true;
      _initializationFailure = null;
      _setState(SupabaseServiceState.ready);
      LoggerService.info(
        'Supabase backend initialized for environment: '
        '${_config.environment.name}.',
      );
    } catch (error) {
      _isInitialized = false;
      _initializationFailure = classifyInfrastructureFailure(error);
      _setState(SupabaseServiceState.unavailable);
      LoggerService.error('Supabase initialization failed', error);
    } finally {
      _initializationOperation = null;
    }
  }

  Future<void> _initializeWithRecoveryGuard() async {
    final url = _config.supabaseUrl;
    final projectIdentity = AuthRecoveryStorageCoordinator.projectIdentityFromUrl(url);

    final delegate = _recoveryDelegate ??
        SharedPreferencesLocalStorage(
          persistSessionKey:
              'sb-${Uri.parse(url).host.split(".").first}-auth-token',
        );
    _recoveryCoordinator = await AuthRecoveryStorageCoordinator.open(
      projectIdentity: projectIdentity,
      delegate: delegate,
    );

    final baseOptions = _authOptions ?? const FlutterAuthClientOptions();
    final authOptions = baseOptions.copyWith(
      localStorage: _recoveryCoordinator!.sdkLocalStorage,
    );

    await _defaultInitialize(
      url: url,
      publishableKey: _config.supabaseAnonKey,
      authOptions: authOptions,
    );
  }

  void _setState(SupabaseServiceState next) {
    if (_state == next) return;
    _state = next;
    if (!_disposed) notifyListeners();
  }

  static Future<void> _defaultInitialize({
    required String url,
    required String publishableKey,
    required FlutterAuthClientOptions authOptions,
  }) {
    return Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      authOptions: authOptions,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
