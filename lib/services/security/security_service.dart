import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class SecurityService {
  final enc.Key _key;

  SecurityService({String? passphrase})
      : _key = (passphrase != null && passphrase.isNotEmpty)
            ? enc.Key(Uint8List.fromList(sha256.convert(utf8.encode(passphrase)).bytes))
            : enc.Key.fromUtf8("SOVISecureAcousticFileTransfer32");

  /// Calculate real SHA-256 hash of raw file bytes
  static String calculateSha256(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Encrypt payload data with AES-256-GCM
  /// Output format: IV/Nonce (16B) + Ciphertext + Tag
  Uint8List encrypt(Uint8List plaintext) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plaintext, iv: iv);

    final builder = BytesBuilder();
    builder.add(iv.bytes);
    builder.add(encrypted.bytes);
    return builder.toBytes();
  }

  /// Decrypt payload data with AES-256-GCM
  Uint8List decrypt(Uint8List combinedData) {
    if (combinedData.length < 16) {
      throw const FormatException("Payload too short for AES-GCM decryption");
    }

    final iv = enc.IV(combinedData.sublist(0, 16));
    final cipherText = combinedData.sublist(16);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.gcm));
    final decryptedBytes = encrypter.decryptBytes(enc.Encrypted(cipherText), iv: iv);

    return Uint8List.fromList(decryptedBytes);
  }
}
