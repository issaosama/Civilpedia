import 'package:url_launcher/url_launcher.dart';

/// W5.4 — smallest presentation/service boundary for external contact actions.
///
/// Lives under presentation (not domain): launching an external application is
/// platform/presentation infrastructure, not business domain logic. The detail
/// screen depends on this abstraction so widget tests can inject a fake and
/// never open a real external app.
abstract class DirectoryContactLauncher {
  /// Attempts to open the phone dialer for [trimmedPhone].
  ///
  /// Returns true only when the launch was performed successfully. Returns
  /// false when the platform cannot launch the URI (guarded via
  /// [canLaunchUrl]) or the launch failed.
  Future<bool> launchPhone(String trimmedPhone);

  /// Attempts to open WhatsApp for [digits] via `https://wa.me/<digits>`.
  ///
  /// [digits] must already be the ASCII-digit-only extraction of a whatsapp
  /// value. Returns true only when the launch was performed successfully.
  Future<bool> launchWhatsApp(String digits);
}

/// Production implementation backed by the existing [url_launcher] dependency.
///
/// No pubspec change: [url_launcher] is already a dependency and is already
/// used with the same `canLaunchUrl` guard + external mode in
/// `profile_screen.dart`.
class UrlLauncherDirectoryContactLauncher implements DirectoryContactLauncher {
  const UrlLauncherDirectoryContactLauncher();

  @override
  Future<bool> launchPhone(String trimmedPhone) async {
    final uri = Uri(scheme: 'tel', path: trimmedPhone);
    return _launch(uri);
  }

  @override
  Future<bool> launchWhatsApp(String digits) async {
    final uri = Uri.parse('https://wa.me/$digits');
    return _launch(uri);
  }

  Future<bool> _launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// W5.4 WhatsApp contract — safe interpretation.
///
/// The persisted `whatsapp` value is not strongly typed (number vs URL vs
/// handle). W5.4 extracts ASCII digits only, without inferring a country code
/// and without reinterpreting meaningful leading country digits. An empty
/// digit result means the value is NOT launchable.
String extractWhatsAppDigits(String raw) {
  final trimmed = raw.trim();
  final buffer = StringBuffer();
  for (final codeUnit in trimmed.codeUnits) {
    if (codeUnit >= 48 /* '0' */ && codeUnit <= 57 /* '9' */) {
      buffer.writeCharCode(codeUnit);
    }
  }
  return buffer.toString();
}
