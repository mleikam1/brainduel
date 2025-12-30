import 'dart:convert';
import 'dart:typed_data';

String sha256Hex(String input) {
  final bytes = utf8.encode(input);
  final message = Uint8List.fromList(bytes);
  final length = message.length;
  final bitLength = length * 8;
  final paddingLength = ((56 - (length + 1) % 64) + 64) % 64;
  final padded = Uint8List(length + 1 + paddingLength + 8);
  padded.setAll(0, message);
  padded[length] = 0x80;
  final byteData = ByteData.view(padded.buffer);
  byteData.setUint64(padded.length - 8, bitLength, Endian.big);

  var h0 = 0x6a09e667;
  var h1 = 0xbb67ae85;
  var h2 = 0x3c6ef372;
  var h3 = 0xa54ff53a;
  var h4 = 0x510e527f;
  var h5 = 0x9b05688c;
  var h6 = 0x1f83d9ab;
  var h7 = 0x5be0cd19;

  final w = List<int>.filled(64, 0);

  for (var chunk = 0; chunk < padded.length; chunk += 64) {
    for (var i = 0; i < 16; i++) {
      w[i] = byteData.getUint32(chunk + i * 4, Endian.big);
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = _toUint32(w[i - 16] + s0 + w[i - 7] + s1);
    }

    var a = h0;
    var b = h1;
    var c = h2;
    var d = h3;
    var e = h4;
    var f = h5;
    var g = h6;
    var h = h7;

    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ (~e & g);
      final temp1 = _toUint32(h + s1 + ch + _k[i] + w[i]);
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = _toUint32(s0 + maj);

      h = g;
      g = f;
      f = e;
      e = _toUint32(d + temp1);
      d = c;
      c = b;
      b = a;
      a = _toUint32(temp1 + temp2);
    }

    h0 = _toUint32(h0 + a);
    h1 = _toUint32(h1 + b);
    h2 = _toUint32(h2 + c);
    h3 = _toUint32(h3 + d);
    h4 = _toUint32(h4 + e);
    h5 = _toUint32(h5 + f);
    h6 = _toUint32(h6 + g);
    h7 = _toUint32(h7 + h);
  }

  return [
    h0,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    h7,
  ].map((value) => value.toUnsigned(32).toRadixString(16).padLeft(8, '0')).join();
}

int _rotr(int value, int shift) {
  return (value >> shift) | ((value << (32 - shift)) & 0xffffffff);
}

int _toUint32(int value) => value & 0xffffffff;

const List<int> _k = [
  0x428a2f98,
  0x71374491,
  0xb5c0fbcf,
  0xe9b5dba5,
  0x3956c25b,
  0x59f111f1,
  0x923f82a4,
  0xab1c5ed5,
  0xd807aa98,
  0x12835b01,
  0x243185be,
  0x550c7dc3,
  0x72be5d74,
  0x80deb1fe,
  0x9bdc06a7,
  0xc19bf174,
  0xe49b69c1,
  0xefbe4786,
  0x0fc19dc6,
  0x240ca1cc,
  0x2de92c6f,
  0x4a7484aa,
  0x5cb0a9dc,
  0x76f988da,
  0x983e5152,
  0xa831c66d,
  0xb00327c8,
  0xbf597fc7,
  0xc6e00bf3,
  0xd5a79147,
  0x06ca6351,
  0x14292967,
  0x27b70a85,
  0x2e1b2138,
  0x4d2c6dfc,
  0x53380d13,
  0x650a7354,
  0x766a0abb,
  0x81c2c92e,
  0x92722c85,
  0xa2bfe8a1,
  0xa81a664b,
  0xc24b8b70,
  0xc76c51a3,
  0xd192e819,
  0xd6990624,
  0xf40e3585,
  0x106aa070,
  0x19a4c116,
  0x1e376c08,
  0x2748774c,
  0x34b0bcb5,
  0x391c0cb3,
  0x4ed8aa4a,
  0x5b9cca4f,
  0x682e6ff3,
  0x748f82ee,
  0x78a5636f,
  0x84c87814,
  0x8cc70208,
  0x90befffa,
  0xa4506ceb,
  0xbef9a3f7,
  0xc67178f2,
];
