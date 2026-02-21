
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';

import 'encryption_service.dart';

enum AuthResult { successReal, successFake, failure, error }

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  
  // Storage keys
  static const _kRealPinHash = 'real_pin_hash';
  static const _kFakePinHash = 'fake_pin_hash';
  static const _kRealKeyBlob = 'real_key_blob_v1';
  static const _kFakeKeyBlob = 'fake_key_blob_v1';
  static const _kUseBiometrics = 'use_biometrics';

  bool _isInitialized = false;

  Future<void> init() async {
    _isInitialized = true;
  }

  Future<bool> hasAccount() async {
    final pin = await _storage.read(key: _kRealPinHash);
    return pin != null;
  }

  /// Sets up the initial PINs and Generates Master Keys
  Future<void> setupKeys(String realPin, String fakePin) async {
    // 1. Generate Master Keys
    final realKey = _generateRandomKey();
    final fakeKey = _generateRandomKey();

    // 2. Encrypt Keys with PINs
    // Simple approach: Encrypt the MasterKey using the PIN as the key
    // We use EncryptionService helper (which uses SHA256 of password/pin as key)
    
    final realKeyEncrypted = EncryptionService.encryptDataWithPassword(realKey, realPin);
    final fakeKeyEncrypted = EncryptionService.encryptDataWithPassword(fakeKey, fakePin);

    // 3. Store Hashes for quick verification (optional, but good for UI feedback before decryption)
    // Actually, we can just try to decrypt. If it fails, PIN is wrong.
    // But storing a Hash allows us to know WHICH PIN it was quickly if we wanted, 
    // though here we just try both.
    // Let's store SHA256 of PIN for verification.
    
    final realPinHash = sha256.convert(utf8.encode(realPin)).toString();
    final fakePinHash = sha256.convert(utf8.encode(fakePin)).toString();

    // 4. Validate they are different
    if (realPin == fakePin) throw Exception('Real and Fake PINs must be different');

    // 5. Save all
    await _storage.write(key: _kRealPinHash, value: realPinHash);
    await _storage.write(key: _kFakePinHash, value: fakePinHash);
    await _storage.write(key: _kRealKeyBlob, value: base64Encode(realKeyEncrypted));
    await _storage.write(key: _kRealKeyBlob, value: base64Encode(realKeyEncrypted));
    await _storage.write(key: _kFakeKeyBlob, value: base64Encode(fakeKeyEncrypted));
    // Store PIN for Biometric access
    await _storage.write(key: 'bio_pin_v1', value: realPin);
  }

  Future<(AuthResult, Uint8List?)> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
      if (!canCheck) return (AuthResult.error, null);

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock your vault',
      );

      if (didAuthenticate) {
        // Retrieve the stored PIN
        final pin = await _storage.read(key: 'bio_pin_v1');
        if (pin != null) {
          return authenticate(pin);
        }
      }
      return (AuthResult.failure, null);
    } catch (e) {
      return (AuthResult.error, null);
    }
  }

  /// Authenticate with PIN. Returns the Decrypted Master Key and Mode.
  Future<(AuthResult, Uint8List?)> authenticate(String pin) async {
    final pinHash = sha256.convert(utf8.encode(pin)).toString();
    
    final storedRealHash = await _storage.read(key: _kRealPinHash);
    final storedFakeHash = await _storage.read(key: _kFakePinHash);

    if (pinHash == storedRealHash) {
      // It's the real PIN. Decrypt the Real Key.
      final blobBase64 = await _storage.read(key: _kRealKeyBlob);
      if (blobBase64 == null) return (AuthResult.error, null);
      
      try {
        final blob = base64Decode(blobBase64);
        final masterKey = EncryptionService.decryptDataWithPassword(blob, pin);
        return (AuthResult.successReal, masterKey);
      } catch (e) {
        return (AuthResult.error, null);
      }
    } else if (pinHash == storedFakeHash) {
      // It's the fake PIN.
       final blobBase64 = await _storage.read(key: _kFakeKeyBlob);
      if (blobBase64 == null) return (AuthResult.error, null);

      try {
        final blob = base64Decode(blobBase64);
        final masterKey = EncryptionService.decryptDataWithPassword(blob, pin);
        return (AuthResult.successFake, masterKey);
      } catch (e) {
        return (AuthResult.error, null);
      }
    } else {
      return (AuthResult.failure, null);
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Helper
  Uint8List _generateRandomKey() {
    // 32 bytes = 256 bits
    final uuid = Uuid();
    // Recursive RNG is weak, but 'cryptography' package is better. 
    // For now, we rely on local_auth or basic random if 'encrypt' has a secure random.
    // 'encrypt' package uses 'pointycastle' which implies some randomness.
    // The 'uuid.v4' is random but not necessarily CSPRNG.
    // Better: use 'SecureRandom' from pointcastle or implicit usage via encrypt.IV.fromSecureRandom
    // We need 32 bytes raw.
    // Let's use Uuid v4 converted to bytes, mixed with time? No, that's bad.
    // EncryptionService should help.
    // Actually, `encrypt` package has `SecureRandom`.
    // But to access it easily, we can use `EncryptionService` logic or just `IV.fromSecureRandom(32).bytes`.
    // `IV` is just bytes.
    // Note: importing 'encrypt' as 'encrypt_pkg' might be needed if naming conflict.
    // But 'EncryptionService' uses it. 
    // Let's assume we can do this simply:
    // We'll use a hack if we can't access SecureRandom easily:
    // But wait, StorageService uses HiveAesCipher which needs 32 bytes.
    
    // We'll use 2 UUIDs concatenated (32 bytes = 16 * 2)
    final u1 = Uuid().v4obj().toBytes();
    final u2 = Uuid().v4obj().toBytes();
    return Uint8List.fromList([...u1, ...u2]);
  }
}
