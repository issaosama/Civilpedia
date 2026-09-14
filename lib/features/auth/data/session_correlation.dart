import 'dart:convert';

/// A non-secret correlation handle for an auth session.
///
/// Used by recovery operations to refer to the session that was current when a
/// risky auth mutation started. It is intentionally weaker than a full session
/// snapshot and contains no access/refresh/id tokens or OAuth credentials.
class SessionCorrelation {
  const SessionCorrelation({
    required this.userId,
    this.expiresAt,
    this.sessionId,
    this.projectIdentity,
  });

  final String userId;

  /// Unix epoch seconds expiration from the session metadata.
  final int? expiresAt;

  /// Non-secret GoTrue `session_id` claim from the access-token JWT payload.
  ///
  /// Never a bearer token, refresh token, or signature-bearing material.
  final String? sessionId;

  /// Stable non-secret identity of the configured Supabase project authority.
  final String? projectIdentity;

  /// Whether a `session_id` was successfully extracted.
  bool get hasSessionId => sessionId != null && sessionId!.isNotEmpty;

  /// Whether this correlation is sufficient to authorize destructive cleanup
  /// ownership decisions.
  ///
  /// userId + expiresAt alone are NOT sufficient. C2/C3 must remain blocked
  /// from destructive cleanup unless a session_id and project identity are
  /// present and match.
  bool get isSufficientForDestructiveCleanup =>
      hasSessionId &&
      projectIdentity != null &&
      projectIdentity!.isNotEmpty &&
      userId.isNotEmpty;

  /// Extracts only the non-secret identity metadata from a GoTrue session JSON
  /// string. Throws [FormatException] if the payload cannot yield a user id.
  factory SessionCorrelation.fromSessionJson(
    String sessionJson, {
    String? projectIdentity,
  }) {
    final map = jsonDecode(sessionJson) as Map<String, dynamic>?;
    if (map == null) {
      throw const FormatException('Session JSON payload was null');
    }
    final userMap = map['user'] as Map<String, dynamic>?;
    final userId = userMap?['id'] as String?;
    if (userId == null || userId.isEmpty) {
      throw const FormatException('Session JSON missing user.id');
    }
    final expiresAt = map['expires_at'] as int?;
    final sessionId = _extractSessionId(map['access_token']);
    return SessionCorrelation(
      userId: userId,
      expiresAt: expiresAt,
      sessionId: sessionId,
      projectIdentity: projectIdentity,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        if (expiresAt != null) 'expiresAt': expiresAt,
        if (sessionId != null) 'sessionId': sessionId,
        if (projectIdentity != null) 'projectIdentity': projectIdentity,
      };

  factory SessionCorrelation.fromMap(Map<String, dynamic> map) {
    final userId = map['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      throw const FormatException('Session correlation missing userId');
    }
    return SessionCorrelation(
      userId: userId,
      expiresAt: map['expiresAt'] as int?,
      sessionId: map['sessionId'] as String?,
      projectIdentity: map['projectIdentity'] as String?,
    );
  }

  /// True when [other] refers to the same project + user + session_id.
  ///
  /// Missing session_id or project identity makes the correlation explicitly
  /// non-matching for destructive ownership.
  bool matches(SessionCorrelation other) {
    if (!isSufficientForDestructiveCleanup ||
        !other.isSufficientForDestructiveCleanup) {
      return false;
    }
    return projectIdentity == other.projectIdentity &&
        userId == other.userId &&
        sessionId == other.sessionId;
  }

  @override
  String toString() =>
      'SessionCorrelation(userId: $userId, expiresAt: $expiresAt, '
      'sessionId: ${sessionId == null ? null : '<present>'}, '
      'projectIdentity: $projectIdentity)';

  /// Safely extracts the non-secret `session_id` claim from a GoTrue
  /// access-token JWT without validating the signature.
  static String? _extractSessionId(Object? accessToken) {
    if (accessToken is! String || accessToken.isEmpty) return null;
    final parts = accessToken.split('.');
    if (parts.length != 3) return null;
    final payloadBase64 = parts[1];
    var normalized = payloadBase64;
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    try {
      final payloadBytes = base64Url.decode(normalized);
      final payload = jsonDecode(utf8.decode(payloadBytes))
          as Map<String, dynamic>?;
      final id = payload?['session_id'] as String?;
      return id == null || id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }
}
