import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Only external menu actions belong here. Account and demo states stay local.
class MenuLinks {
  const MenuLinks({this.isWeb = kIsWeb, this.platform});
  final bool isWeb;
  final TargetPlatform? platform;

  static const destinations = {
    'Test Guide':
        'https://es-mktg-assets.s3.eu-west-2.amazonaws.com/guide/englishscore-coreskills-guide-mobile.pdf',
    'Help': 'https://www.englishscore.com/help',
    'Privacy Policy': 'https://www.englishscore.com/privacy-policy',
    'Our Rules': 'https://www.englishscore.com/terms-of-use',
    '💜 EnglishScore': 'https://apps.apple.com/app/id1499806063',
  };
  static const reviewUrl =
      'itms-apps://apps.apple.com/app/id1499806063?action=write-review';

  Future<bool> _launch(String url) async {
    try {
      // Launch directly in the tap handler; preflight checks can consume the
      // browser's user gesture and cause a new-tab request to be blocked.
      return await launchUrl(
        Uri.parse(url),
        mode:
            isWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        webOnlyWindowName: isWeb ? '_blank' : null,
      );
    } catch (_) {
      // The caller presents a failure dialog containing the destination URL.
      return false;
    }
  }

  Future<bool> open(String title) async {
    final url = destinations[title];
    if (url == null) throw ArgumentError.value(title, 'title');
    if (title == '💜 EnglishScore' &&
        !isWeb &&
        (platform ?? defaultTargetPlatform) == TargetPlatform.iOS) {
      if (await _launch(reviewUrl)) return true;
    }
    return _launch(url);
  }
}
