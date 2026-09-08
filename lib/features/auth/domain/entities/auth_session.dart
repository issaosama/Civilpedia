/// A5.4 — Authenticated session snapshot exposed to the presentation layer.
///
/// The canonical Civilpedia identity is [userId] — the Supabase
/// `auth.users.id` value. Google account identifiers (provider user ids) are
/// NEVER used as the Civilpedia identity: Google is only the authentication
/// provider that produces this session.
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  /// Canonical Civilpedia user id (`auth.users.id`). Never a provider id.
  final String userId;

  /// The authenticated user's email, or empty when the provider omits it.
  final String email;

  /// Display name surfaced in the profile area, or empty when unknown.
  final String displayName;

  /// Optional avatar/photo URL from the provider's auth metadata
  /// (`avatar_url` / `picture`). Used ONLY for `profiles.photo_url` mapping;
  /// never logged and never an identity.
  final String? photoUrl;
}