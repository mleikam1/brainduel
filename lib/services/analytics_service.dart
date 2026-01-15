import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    final sanitizedParameters = _sanitizeParameters(parameters);
    if (kDebugMode) {
      debugPrint('[analytics] $name $sanitizedParameters');
    }
    unawaited(_analytics.logEvent(name: name, parameters: sanitizedParameters));
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?> parameters) {
    final sanitized = <String, Object>{};
    parameters.forEach((key, value) {
      final sanitizedValue = _sanitizeValue(value);
      if (sanitizedValue != null) {
        sanitized[key] = sanitizedValue;
      }
    });
    return sanitized;
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String || value is num) {
      return value;
    }
    if (value is bool) {
      return value.toString();
    }
    if (value is Iterable) {
      return value.map((entry) => entry?.toString() ?? '').join(',');
    }
    if (value is Map) {
      return value.toString();
    }
    return value.toString();
  }
}
