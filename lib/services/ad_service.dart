import 'package:flutter/material.dart';
import '../widgets/interstitial_ad_dialog.dart';

class AdService {
  Future<void> showInterstitial(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const InterstitialAdDialog(),
    );
  }
}
