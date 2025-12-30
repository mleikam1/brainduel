import 'package:flutter/foundation.dart';

class AnalyticsService {
  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    if (kDebugMode) {
      debugPrint('[analytics] $name $parameters');
    }
  }
}
