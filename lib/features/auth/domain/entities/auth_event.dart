import 'auth_session.dart';

enum AuthEventType {
  sessionRestored,
  signedIn,
  signedOut,
  tokenRefreshed,
  sessionReplaced,
  sessionLost,
}

class AuthEvent {
  const AuthEvent({
    required this.type,
    this.session,
  });

  final AuthEventType type;
  final AuthSession? session;
}
