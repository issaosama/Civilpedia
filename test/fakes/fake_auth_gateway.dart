import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';

/// Deterministic [AuthGateway] fake for widget/unit tests (A5.4).
///
/// No Google or Supabase is involved. Behavior is scripted per test.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    this.available = true,
    this.restoredSession,
    this.signInResult,
    this.restoreError,
    this.signInError,
    this.signOutError,
    this.onSignIn,
    this.onSignOut,
  });

  bool available;
  AuthSession? restoredSession;
  AuthSession? signInResult;
  Object? restoreError;
  Object? signInError;
  Object? signOutError;
  int signInCalls = 0;
  int signOutCalls = 0;

  /// Called before returning [signInResult], useful for asserting state.
  void Function(FakeAuthGateway gateway)? onSignIn;
  void Function(FakeAuthGateway gateway)? onSignOut;

  @override
  bool get isAvailable => available;

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
}

/// Convenience sessions for assertions.
const fakeSession = AuthSession(
  userId: 'uuid-0000-0000',
  email: 'eng@civilpedia.com',
  displayName: 'م. أحمد',
);