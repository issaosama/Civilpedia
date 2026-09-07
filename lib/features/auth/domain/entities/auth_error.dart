/// A5.4 — App-level authentication errors surfaced to the UI.
///
/// The provider keeps the application usable on failure: a restore failure
/// degrades silently to GUEST, while [unavailable] and [signInFailed] produce
/// a localized message at the configured entry point.
enum AuthError {
  /// The Supabase backend is not configured / not initialized in this build.
  unavailable,

  /// Google sign-in started but did not complete (network, provider, token).
  signInFailed,
}