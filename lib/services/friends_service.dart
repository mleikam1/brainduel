import 'dart:convert';
import '../models/friend_profile.dart';
import 'network_client.dart';
import 'sha256.dart';

class FriendsService {
  FriendsService({
    NetworkClient? client,
    Uri? baseUri,
  })  : _client = client ?? createNetworkClient(),
        _baseUri = baseUri ?? _defaultBaseUri();

  final NetworkClient _client;
  final Uri _baseUri;

  static Uri _defaultBaseUri() {
    final base = Uri.base;
    if (base.hasScheme && (base.scheme == 'http' || base.scheme == 'https')) {
      return base.replace(path: '', query: '', fragment: '');
    }
    return Uri.parse('https://brainduel.app');
  }

  List<String> hashPhoneNumbers(Iterable<String> phoneNumbers) {
    return phoneNumbers
        .map(_normalizePhoneNumber)
        .where((value) => value.isNotEmpty)
        .map(sha256Hex)
        .toSet()
        .toList();
  }

  Future<FriendProfile> followByLink(String followCode) async {
    final uri = _baseUri.replace(path: '/api/friends/follow-link');
    final response = await _client.post(
      uri: uri,
      headers: _jsonHeaders(),
      body: jsonEncode({'code': followCode}),
    );
    if (response.statusCode != 200) {
      throw Exception('Follow failed (${response.statusCode})');
    }
    final payloadRaw = jsonDecode(response.body);
    if (payloadRaw is! Map) {
      throw StateError('Invalid friend payload.');
    }
    final payload = Map<String, dynamic>.from(payloadRaw as Map);
    final friendRaw = payload['friend'];
    final friendJson = friendRaw is Map
        ? Map<String, dynamic>.from(friendRaw as Map)
        : const <String, dynamic>{};
    return FriendProfile.fromJson(friendJson);
  }

  Future<List<FriendProfile>> matchContacts(List<String> hashedContacts) async {
    if (hashedContacts.isEmpty) return [];
    final uri = _baseUri.replace(path: '/api/friends/contacts/match');
    final response = await _client.post(
      uri: uri,
      headers: _jsonHeaders(),
      body: jsonEncode({'hashes': hashedContacts}),
    );
    if (response.statusCode != 200) {
      throw Exception('Match failed (${response.statusCode})');
    }
    final payloadRaw = jsonDecode(response.body);
    if (payloadRaw is! Map) {
      throw StateError('Invalid contacts payload.');
    }
    final payload = Map<String, dynamic>.from(payloadRaw as Map);
    final rawMatches = payload['matches'];
    List<Map<String, dynamic>> matches;
    if (rawMatches == null) {
      matches = const [];
    } else if (rawMatches is List) {
      matches = List<Map<String, dynamic>>.from(
        rawMatches.map((match) {
          if (match is! Map) {
            throw StateError('Invalid friend match payload.');
          }
          return Map<String, dynamic>.from(match as Map);
        }),
      );
    } else {
      throw StateError('Invalid friend matches payload.');
    }
    return matches.map(FriendProfile.fromJson).toList();
  }

  Map<String, String> _jsonHeaders() => const {'Content-Type': 'application/json'};

  String _normalizePhoneNumber(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }
}
