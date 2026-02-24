import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/data_models.dart';

class StorageService extends ChangeNotifier {
  late Box<PasswordEntry> _passwordBox;
  late Box<SecureNote> _noteBox;
  late Box<SecureMedia> _mediaBox;
  bool _isInitialized = false;
  bool _isFakeMode = false;
  bool _isStealthUnlocked = false;
  bool _isMediaUnlocked = false;

  bool get isFakeMode => _isFakeMode;
  bool get isStealthUnlocked => _isStealthUnlocked;
  bool get isMediaUnlocked => _isMediaUnlocked;

  /// Initialize Hive and open boxes with the provided encryption key
  Future<void> init(List<int> encryptionKey, {bool isFakeMode = false}) async {
    if (_isInitialized) return;

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PasswordEntryAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SecureNoteAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SecureMediaAdapter());

    _isFakeMode = isFakeMode;
    final boxPrefix = isFakeMode ? 'fake_' : '';

    // Open boxes in parallel to significantly reduce initialization time
    final results = await Future.wait([
      Hive.openBox<PasswordEntry>(
        '${boxPrefix}passwords',
        encryptionCipher: HiveAesCipher(encryptionKey),
      ),
      Hive.openBox<SecureNote>(
        '${boxPrefix}notes',
        encryptionCipher: HiveAesCipher(encryptionKey),
      ),
      Hive.openBox<SecureMedia>(
        '${boxPrefix}media',
        encryptionCipher: HiveAesCipher(encryptionKey),
      ),
    ]);

    _passwordBox = results[0] as Box<PasswordEntry>;
    _noteBox = results[1] as Box<SecureNote>;
    _mediaBox = results[2] as Box<SecureMedia>;

    _isInitialized = true;
    
    if (isFakeMode && _passwordBox.isEmpty) {
      await _populateFakeData();
    }
  }

  Future<void> _populateFakeData() async {
    // Generate some believable fake data
    final fakes = [
      PasswordEntry(title: 'Facebook', username: 'john.doe', encryptedPassword: 'fake_encrypted_pw', category: 'Social'),
      PasswordEntry(title: 'Gmail', username: 'john.doe@gmail.com', encryptedPassword: 'fake_encrypted_pw', category: 'Email'),
      PasswordEntry(title: 'Bank of America', username: 'johnd', encryptedPassword: 'fake_encrypted_pw', category: 'Finance'),
    ];
    await _passwordBox.addAll(fakes);
  }

  // --- Password Methods ---

  List<PasswordEntry> getPasswords() {
    final all = _passwordBox.values.toList();
    if (_isStealthUnlocked) return all;
    return all.where((p) => p.isStealth != true).toList();
  }

  Future<void> savePassword(PasswordEntry entry) async {
    if (entry.isInBox) {
      await entry.save();
    } else {
      await _passwordBox.add(entry);
    }
    notifyListeners();
  }

  Future<void> deletePassword(PasswordEntry entry) async {
    await entry.delete();
    notifyListeners();
  }

  // --- Note Methods ---
  
  List<SecureNote> getNotes() {
    final all = _noteBox.values.toList();
    if (_isStealthUnlocked) return all;
    return all.where((n) => n.isStealth != true).toList();
  }

  Future<void> saveNote(SecureNote note) async {
    if (note.isInBox) {
      await note.save();
    } else {
      await _noteBox.add(note);
    }
    notifyListeners();
  }

  Future<void> deleteNote(SecureNote note) async {
    await note.delete();
    notifyListeners();
  }

  Future<void> close() async {
    await _passwordBox.close();
    await _noteBox.close();
    await _mediaBox.close();
    _isInitialized = false;
  }
  
  Future<void> clearAll() async {
     await _passwordBox.clear();
     await _noteBox.clear();
     await _mediaBox.clear();
     notifyListeners();
  }

  // --- Backup / Restore ---
  
  Map<String, dynamic> getBackupData() {
    return {
      'passwords': _passwordBox.values.map((e) => e.toJson()).toList(),
      'notes': _noteBox.values.map((e) => e.toJson()).toList(),
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> restoreBackup(Map<String, dynamic> data) async {
    // Optional: Decide whether to Merge or Replace.
    // Logic: Replace for simplicity and consistency with 'importing to new device'.
    
    await _passwordBox.clear();
    await _noteBox.clear();

    if (data['passwords'] != null) {
      final List pws = data['passwords'];
      await _passwordBox.addAll(pws.map((e) => PasswordEntry.fromJson(e)));
    }
    
    if (data['notes'] != null) {
      final List nts = data['notes'];
      await _noteBox.addAll(nts.map((e) => SecureNote.fromJson(e)));
    }
    notifyListeners();
  }

  Future<void> addAllPasswords(List<PasswordEntry> entries) async {
    await _passwordBox.addAll(entries);
    notifyListeners();
  }

  // --- Media Methods ---

  List<SecureMedia> getMedia() {
    final all = _mediaBox.values.toList();
    if (_isMediaUnlocked) return all;
    return all.where((m) => m.isStealth != true).toList();
  }

  Future<void> saveMedia(SecureMedia media) async {
    if (media.isInBox) {
      await media.save();
    } else {
      await _mediaBox.add(media);
    }
    notifyListeners();
  }

  Future<void> deleteMedia(SecureMedia media) async {
    try {
      // 1. Delete physical file
      final appDocDir = await getApplicationDocumentsDirectory();
      final filePath = p.join(appDocDir.path, '.vault', media.fileName);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting physical media file: $e');
    }

    // 2. Delete from Hive
    await media.delete();
    notifyListeners();
  }

  // --- Stealth Methods ---

  void setStealthUnlocked(bool unlocked) {
    _isStealthUnlocked = unlocked;
    notifyListeners();
  }

  void setMediaUnlocked(bool unlocked) {
    _isMediaUnlocked = unlocked;
    notifyListeners();
  }
}
