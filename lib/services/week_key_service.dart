import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weekKeyServiceProvider = Provider<WeekKeyService>((ref) {
  return WeekKeyService(FirebaseFunctions.instance);
});

class WeekKeyService {
  WeekKeyService(this._functions);

  final FirebaseFunctions _functions;

  Future<String> fetchWeekKey() async {
    final callable = _functions.httpsCallable('getWeekKey');
    final result = await callable.call();
    final data = _requireMap(result.data, 'getWeekKey');
    final weekKey = data['weekKey'];
    if (weekKey is String && weekKey.isNotEmpty) {
      return weekKey;
    }
    throw StateError('Missing weekKey in getWeekKey response.');
  }

  Map<String, dynamic> _requireMap(Object? payload, String functionName) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError('Unexpected $functionName response payload.');
  }
}
