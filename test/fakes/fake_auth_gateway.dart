import 'dart:async';

import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';

/// Deterministic [AuthGateway] fake for widget/unit tests (A5.4).
///
/// No Google or Supabase is involved. Behavior is scripted per test. Tests may
/// inject [AuthEvent]s through [emit] to drive the canonical event stream
/// consumed by [AuthProvider] (simulating the Supabase auth stream); by
/// default the stream stays silent so scripted `restoreSession`/`signIn*`
/// paths remain the deterministic driver.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    this.available = true,
    this.restoredSession,
    this.signInResult,
    this.restoreError,
    this.signInError,
    this.signOutError,
    this.blockAccountAuthority = false,
    this.onSignIn,
    this.onSignOut,
    Stream<AuthEvent>? events,
  }) : _controller = StreamController<AuthEvent>.broadcast() {
    final injected = events;
    if (injected != null) {
      injected.listen(
        (e) {
          if (!_controller.isClosed) _controller.add(e);
        },
      );
    }
  }

  bool available;
  AuthSession? restoredSession;
  AuthSession? signInResult;
  Object? restoreError;
  Object? signInError;
  Object? signOutError;
  bool blockAccountAuthority = false;
  int signInCalls = 0;
  int signOutCalls = 0;
  final StreamController<AuthEvent> _controller;

  /// Called before returning [signInResult], useful for asserting state.
  void Function(FakeAuthGateway gateway)? onSignIn;
  void Function(FakeAuthGateway gateway)? onSignOut;

  /// Emits a canonical auth event into [authEvents].
  void emit(AuthEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  void close() {
    if (!_controller.isClosed) _controller.close();
  }

  @override
  bool get isAvailable => available;

  @override
  bool get canAccountAuthorityBeGranted => !blockAccountAuthority;

  @override
  bool get isAuthObservationAvailable => true;

  @override
  bool get isLogoutCleanupBlocked => false;

  @override
  Future<bool> retryAuthCleanup() async => false;

  @override
  Stream<AuthEvent> get authEvents => _controller.stream;

  @override
  Future<AuthSession?> restoreSession() async {
    if (restoreError != null) throw restoreError!;
    return restoredSession;
  }

  @override
  Future<AuthSession?> signInWithGoogle() async {
    signInCalls++;
    onSignIn?.call(this);
    if (signInError != null) throw signInError!;
    return signInResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    onSignOut?.call(this);
    if (signOutError != null) throw signOutError!;
  }

  @override
  void dispose() {}
}

/// Convenience sessions for assertions.
const fakeSession = AuthSession(
  userId: 'uuid-0000-0000',
  email: 'eng@civilpedia.com',
  displayName: 'م. أحمد',
);

/// A second account whose session must never leak onto a device bound to
/// [fakeSession].
const fakeSessionOther = AuthSession(
  userId: 'uuid-other-0000',
  email: 'other@civilpedia.com',
  displayName: 'Other Engineer',
);