import 'dart:html' as html;
import 'network_client.dart';

class _WebNetworkClient implements NetworkClient {
  @override
  Future<NetworkResponse> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    final request = await html.HttpRequest.request(
      uri.toString(),
      method: 'POST',
      requestHeaders: headers,
      sendData: body,
    );
    return NetworkResponse(statusCode: request.status ?? 0, body: request.responseText ?? '');
  }
}

NetworkClient createNetworkClientImpl() => _WebNetworkClient();
