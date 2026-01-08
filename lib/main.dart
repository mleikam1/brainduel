import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    // Firebase: initialize for native platforms using google-services.json.
    await Firebase.initializeApp();
  }
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  runApp(const ProviderScope(child: TriviaApp()));
}
