import 'dart:convert';
import 'dart:io';
import 'network_client.dart';

class _IoNetworkClient implements NetworkClient {
  _IoNetworkClient({HttpClient? httpClient}) : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  @override
  Future<NetworkResponse> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    final request = await _httpClient.postUrl(uri);
    headers.forEach(request.headers.set);
    request.add(utf8.encode(body));
    final response = await request.close();
    final responseBody = await utf8.decodeStream(response);
    return NetworkResponse(statusCode: response.statusCode, body: responseBody);
  }
}

NetworkClient createNetworkClientImpl() => _IoNetworkClient();
