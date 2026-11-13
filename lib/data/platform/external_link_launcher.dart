import 'package:url_launcher/url_launcher.dart';

/// Opens links outside the app (system browser), e.g. the GitHub repository.
class ExternalLinkLauncher {
  /// Returns false when no app could open [uri].
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
