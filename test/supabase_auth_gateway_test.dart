import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/features/auth/data/supabase_auth_gateway.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_error.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';

void main() {
  const devConfig = BackendConfig(
    appEnvRaw: 'development',
    supabaseUrl: 'https://project.supabase.co',
    supabaseAnonKey: 'anon-key',
    googleServerClientId: 'g-web-client-id.apps.googleusercontent.com',
  );

  const unconfigured = BackendConfig(
    appEnvRaw: '',
    supabaseUrl: '',
    supabaseAnonKey: '',
  );

  SupabaseAuthGateway gatewayFor(BackendConfig config) =>
      SupabaseAuthGateway(service: SupabaseService(config: config));

  test('isAvailable is false when the backend is not configured', () {
    expect(gatewayFor(unconfigured).isAvailable, isFalse);
    expect(gatewayFor(devConfig).isAvailable, isFalse,
        reason: 'config present but Supabase not initialized');
  });

  test(
      'isAvailable additionally requires the Google client id'
      ' (config alone is not enough)', () {
    const noGoogle = BackendConfig(
      appEnvRaw: 'development',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'anon-key',
    );
    // No Google client id → gateway unavailable even though backend configured.
    expect(gatewayFor(noGoogle).isAvailable, isFalse);
  });

  test('signInWithGoogle on an unavailable gateway throws AuthGatewayException',
      () {
    final gateway = gatewayFor(unconfigured);
    expect(
      () => gateway.signInWithGoogle(),
      throwsA(
        isA<AuthGatewayException>().having(
          (e) => e.error,
          'error',
          AuthError.unavailable,
        ),
      ),
    );
  });

  test('signOut is a safe no-op when the gateway is unavailable', () async {
    final gateway = gatewayFor(unconfigured);
    await gateway.signOut();
    expect(gateway.isAvailable, isFalse);
  });
}
