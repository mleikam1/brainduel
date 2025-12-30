import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/challenge.dart';
import '../models/challenge_result.dart';

class ShareService {
  Future<void> shareChallengeResult({
    required BuildContext context,
    required ChallengeResult result,
    required ChallengeMetadata metadata,
  }) async {
    final shareText = _buildShareText(result: result, metadata: metadata);
    if (kIsWeb) {
      await _shareWeb(context, shareText);
      return;
    }
    await Share.share(shareText);
  }

  String _buildShareText({
    required ChallengeResult result,
    required ChallengeMetadata metadata,
  }) {
    final challengeUrl = _challengeLink(result.challengeId);
    return 'I scored ${result.points} pts in "${metadata.title}" (${metadata.topic}). '
        '${metadata.taunt} '
        'Think you can beat me? $challengeUrl';
  }

  Uri _challengeLink(String challengeId) {
    final base = Uri.base;
    if (base.hasScheme && (base.scheme == 'http' || base.scheme == 'https')) {
      return base.replace(path: '/c/$challengeId', query: '', fragment: '');
    }
    return Uri.parse('https://brainduel.app/c/$challengeId');
  }

  Future<void> _shareWeb(BuildContext context, String shareText) async {
    try {
      await Share.share(shareText);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share link copied to clipboard.')),
        );
      }
    }
  }
}
