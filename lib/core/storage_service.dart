
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/data_models.dart';

class StorageService extends ChangeNotifier {
  late Box<PasswordEntry> _passwordBox;
  late Box<SecureNote> _noteBox;
  bool _isInitialized = false;
  bool _isFakeMode = false;

  bool get isFakeMode => _isFakeMode;

  /// Initialize Hive and open boxes with the provided encryption key
  Future<void> init(List<int> encryptionKey, {bool isFakeMode = false}) async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PasswordEntryAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SecureNoteAdapter());

    _isFakeMode = isFakeMode;
    final boxPrefix = isFakeMode ? 'fake_' : '';

    _passwordBox = await Hive.openBox<PasswordEntry>(
      '${boxPrefix}passwords',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    _noteBox = await Hive.openBox<SecureNote>(
      '${boxPrefix}notes',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

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
    return _passwordBox.values.toList();
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
    return _noteBox.values.toList();
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
    _isInitialized = false;
  }
  
  Future<void> clearAll() async {
     await _passwordBox.clear();
     await _passwordBox.clear();
     await _noteBox.clear();
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
}
