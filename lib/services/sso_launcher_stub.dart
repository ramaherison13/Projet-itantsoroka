import 'package:url_launcher/url_launcher.dart';

void redirectToSsoUrl(String url) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
