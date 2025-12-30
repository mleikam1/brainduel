import 'network_client.dart';

class _UnsupportedNetworkClient implements NetworkClient {
  @override
  Future<NetworkResponse> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    throw UnsupportedError('Network client is unavailable on this platform.');
  }
}

NetworkClient createNetworkClientImpl() => _UnsupportedNetworkClient();
