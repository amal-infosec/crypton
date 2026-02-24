
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class EncryptionService {
  late encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv; // Fixed IV for simplicity in local DB, or random per entry. 
  // Ideally, use random IV and store it with ciphertext. For Hive fields, we might use a fixed one or prepend it.
  
  // For this implementation, we will use a generated key for database fields
  // and separate logic for file export/import.

  bool _isInitialized = false;

  // Initialize with a 32-byte key
  void init(Uint8List key) {
    final keySpec = encrypt.Key(key);
    _encrypter = encrypt.Encrypter(encrypt.AES(keySpec, mode: encrypt.AESMode.cbc));
    // For simplicity in this local-only app, we might use a fixed IV or derived.
    // BETTER SECURE APPROACH: Generate random IV for every encryption, prepend it to result.
    _isInitialized = true;
  }

  String encryptString(String plainText) {
    if (!_isInitialized) throw Exception('EncryptionService not initialized');
    final iv = encrypt.IV.fromLength(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    // Combine method: IV + Ciphertext (Base64)
    return '${iv.base64}:${encrypted.base64}';
  }

  String decryptString(String encryptedText) {
    if (!_isInitialized) throw Exception('EncryptionService not initialized');
    final parts = encryptedText.split(':');
    if (parts.length != 2) throw Exception('Invalid encrypted format');

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    
    return _encrypter.decrypt(encrypted, iv: iv);
  }

  /// Encrypts raw bytes (for file export)
  /// Uses a user-provided password to derive a key (PBKDF2 equivalent logic or simple hashing for MVP)
  static Uint8List encryptDataWithPassword(Uint8List data, String password) {
    // Derive key from password
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    // Return IV + Encrypted Data
    final combined = BytesBuilder();
    combined.add(iv.bytes);
    combined.add(encrypted.bytes);
    return combined.toBytes();
  }

  static Uint8List decryptDataWithPassword(Uint8List data, String password) {
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    // Extract IV (first 16 bytes)
    final iv = encrypt.IV(data.sublist(0, 16));
    final encryptedBytes = encrypt.Encrypted(data.sublist(16));

    return Uint8List.fromList(encrypter.decryptBytes(encryptedBytes, iv: iv));
  }

  /// Encrypts a file and saves it to a new location
  Future<void> encryptFile(String sourcePath, String destPath, Uint8List key) async {
    final bytes = await File(sourcePath).readAsBytes();
    final keySpec = encrypt.Key(key);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(keySpec, mode: encrypt.AESMode.cbc));
    
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    final combined = BytesBuilder()..add(iv.bytes)..add(encrypted.bytes);
    await File(destPath).writeAsBytes(combined.toBytes());
  }

  /// Decrypts a file as bytes (for Image.memory)
  Future<Uint8List> decryptFileToMemory(String sourcePath, Uint8List key) async {
    final data = await File(sourcePath).readAsBytes();
    final keySpec = encrypt.Key(key);
    final encrypter = encrypt.Encrypter(encrypt.AES(keySpec, mode: encrypt.AESMode.cbc));

    final iv = encrypt.IV(data.sublist(0, 16));
    final encryptedBytes = encrypt.Encrypted(data.sublist(16));

    return Uint8List.fromList(encrypter.decryptBytes(encryptedBytes, iv: iv));
  }

  /// Decrypts a file to a temporary disk location (for Video players)
  Future<void> decryptFileToDisk(String sourcePath, String destPath, Uint8List key) async {
    final bytes = await decryptFileToMemory(sourcePath, key);
    await File(destPath).writeAsBytes(bytes);
  }

  /// Decrypts a file to disk using a background Isolate for better performance on large files
  Future<void> decryptFileToDiskIsolate(String sourcePath, String destPath, Uint8List key) async {
    // Large files can block the UI thread during decryption.
    // Use compute to offload to a background isolate.
    await compute(_decryptFileIsolateWrapper, {
      'sourcePath': sourcePath,
      'destPath': destPath,
      'key': key,
    });
  }

  // Static wrapper because compute needs a top-level or static function
  static Future<void> _decryptFileIsolateWrapper(Map<String, dynamic> params) async {
    final String sourcePath = params['sourcePath'];
    final String destPath = params['destPath'];
    final Uint8List key = params['key'];

    final data = await File(sourcePath).readAsBytes();
    final keySpec = encrypt.Key(key);
    final encrypter = encrypt.Encrypter(encrypt.AES(keySpec, mode: encrypt.AESMode.cbc));

    final iv = encrypt.IV(data.sublist(0, 16));
    final encryptedBytes = encrypt.Encrypted(data.sublist(16));

    final decrypted = encrypter.decryptBytes(encryptedBytes, iv: iv);
    await File(destPath).writeAsBytes(decrypted);
  }
}
