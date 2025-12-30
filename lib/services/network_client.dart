import 'network_client_stub.dart'
    if (dart.library.io) 'network_client_io.dart'
    if (dart.library.html) 'network_client_web.dart';

class NetworkResponse {
  NetworkResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

abstract class NetworkClient {
  Future<NetworkResponse> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  });
}

NetworkClient createNetworkClient() => createNetworkClientImpl();
