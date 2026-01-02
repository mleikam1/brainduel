import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  Future<void> showPostQuizInterstitial({required VoidCallback onCompleted}) async {
    final adUnitId = _interstitialAdUnitId();
    if (adUnitId.isEmpty) {
      onCompleted();
      return;
    }

    final completer = Completer<void>();
    bool finished = false;

    void finish() {
      if (finished) return;
      finished = true;
      onCompleted();
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              finish();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              finish();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          finish();
        },
      ),
    );

    return completer.future;
  }

  String _interstitialAdUnitId() {
    if (kIsWeb) return '';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-3940256099942544/1033173712';
      case TargetPlatform.iOS:
        return 'ca-app-pub-3940256099942544/4411468910';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return '';
    }
  }
}
