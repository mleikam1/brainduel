import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    if (kDebugMode) {
      debugPrint('[analytics] $name $parameters');
    }
    unawaited(_analytics.logEvent(name: name, parameters: parameters));
  }
}
