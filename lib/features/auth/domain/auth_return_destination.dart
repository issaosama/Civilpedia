import '../../../routes/app_routes.dart';

/// V1-R08 (finding 12/21, final pass) — Allowlist resolver for the `?return=`
/// destination captured by the protected-route redirect.
///
/// A return destination is accepted ONLY when it is:
/// * root-relative (always starts with `/`),
/// * not a scheme URL (no `https:`, `customscheme:`, …),
/// * not a protocol-relative URL (`//`),
/// * carrying no authority/host,
/// * free of `..` traversal, and
/// * an EXACT canonical shape from the allowlisted protected families
///   (business applications, business manage, staff applications, user
///   profile) — a prefix match is never enough, so lookalike paths such as
///   `/user/profile-evil` or `/staff/applications-evil` are rejected.
///
/// Everything else resolves to null, and the caller falls back to the default
/// authenticated destination.
abstract final class AuthReturnDestination {
  /// Sentinel for "any single non-empty path segment" in a canonical shape
  /// (e.g. the `:applicationId` detail segment).
  static const _anySegment = '*';

  /// Canonical allowed shapes, expressed as exact segment lists so a longer
  /// or lookalike path can never slip through a prefix comparison. Built from
  /// the [AppRoutes] constants (single source of truth).
  static final List<List<String>> _allowedShapes = _buildShapes();

  static List<List<String>> _buildShapes() {
    final applications = _segments(AppRoutes.businessApplications);
    final manage = _segments(AppRoutes.businessManage);
    final staff = _segments(AppRoutes.staffApplications);
    final userProfile = _segments(AppRoutes.userProfile);
    final detail = <String>[_anySegment];
    return [
      applications, // /business/applications
      [...applications, 'new'], // /business/applications/new
      [...applications, 'claim'], // /business/applications/claim
      [...applications, _anySegment], // /business/applications/:applicationId
      manage, // /business/manage
      [...manage, _anySegment], // /business/manage/:entityId
      staff, // /staff/applications
      [...staff, _anySegment], // /staff/applications/:applicationId
      userProfile, // /user/profile
      [...userProfile, AppRoutes.profileEditSegment], // /user/profile/edit
    ];
  }

  /// Splits a canonical root-relative [path] into non-empty segments.
  static List<String> _segments(String path) =>
      path.split('/').where((s) => s.isNotEmpty).toList(growable: false);

  /// Resolves the raw `?return=` value to a safe root-relative path, or null
  /// to keep the caller's default destination.
  static String? resolve(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final decoded = Uri.tryParse(raw);
    if (decoded == null) return null;
    if (!decoded.path.startsWith('/')) return null; // scheme/relative stripped
    if (decoded.hasScheme) return null; // e.g. https://…, customscheme://…
    if (decoded.authority.isNotEmpty) return null; // authority/host present
    final segments = decoded.pathSegments;
    if (segments.any((segment) => segment == '..')) return null; // traversal
    for (final shape in _allowedShapes) {
      if (_matches(segments, shape)) return decoded.path;
    }
    return null;
  }

  /// Exact segment-wise match. [_anySegment] matches any single non-empty
  /// segment; a `..` segment was already rejected above.
  static bool _matches(List<String> segments, List<String> shape) {
    if (segments.length != shape.length) return false;
    for (var i = 0; i < shape.length; i++) {
      if (shape[i] == _anySegment) continue;
      if (segments[i] != shape[i]) return false;
    }
    return true;
  }
}