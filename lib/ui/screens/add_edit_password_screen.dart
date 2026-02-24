import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:ui';

import '../../core/encryption_service.dart';
import '../../core/storage_service.dart';
import '../../models/data_models.dart';

class AddEditPasswordScreen extends StatefulWidget {
  final PasswordEntry? entry;

  const AddEditPasswordScreen({super.key, this.entry});

  @override
  State<AddEditPasswordScreen> createState() => _AddEditPasswordScreenState();
}

class _AddEditPasswordScreenState extends State<AddEditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  String _category = 'General';
  bool _isObscure = true;
  bool _isStealth = false;

  final List<String> _categories = [
    'General',
    'Social',
    'Email',
    'Finance',
    'Work',
    'Wifi',
    'Shopping',
    'Developer',
    'Forum',
    'Software',
    'Streaming',
    'YouTube',
    'Cybersecurity',
    'Personal',
    'Banking',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleController = TextEditingController(text: e?.title);
    _usernameController = TextEditingController(text: e?.username);
    _passwordController = TextEditingController(); // Decrypt if editing
    _urlController = TextEditingController(text: e?.website);
    _notesController = TextEditingController(text: e?.notes);
    _category = e?.category ?? 'General';
    _isStealth = e?.isStealth ?? false;

    if (e != null) {
      _decryptExistingPassword(e);
    }
  }

  void _decryptExistingPassword(PasswordEntry e) {
    try {
      // In a real app we might pass the decrypted value or access encryption service
      // But EncryptionService is stateless (or static helper in some parts).
      // Actually we have EncryptionService instance in Provider?
      // Wait, EncryptionService.decryptString needs instance? 
      // Our implementation had: instance methods.
      // We need to access the EncryptionService instance which has the key?
      // Wait, StorageService opens the box with the key.
      // But models store *Encrypted String*.
      // To show it in UI we must decrypt it.
      // The `StorageService` has the Key? No, it passed it to Hive.
      // We need the *EncryptionService* to be initialized with the key too?
      // Or `StorageService` can expose a decrypt helper?
      // Or `StorageService` holds the key?
      // Ah, in `AuthService` we got the key and passed it to `StorageService`.
      // `EncryptionService` instance needs to be initialized with that key to help with field encryption/decryption.
      
      // FIX: In `LockScreen`, we initialized `StorageService`. 
      // We ALSO need to init `EncryptionService` if we want to use manual field encryption.
      // Wait, Hive Encrypted Box encrypts the *whole* object serialization.
      // So `PasswordEntry.encryptedPassword` is actually DOUBLE encrypted if we encrypt it manually.
      // The Requirement was "highly encrypted".
      // Hive Box Encryption encrypts the file on disk.
      // If we store `encryptedPassword` as plain text inside the Hive object, it is encrypted on disk.
      // Is that enough? "highly encrypted".
      // Usually yes.
      // But if we want *extra* security (e.g. if someone dumps memory of the loaded app), 
      // we might want the password field to be encrypted in memory too, and only decrypted when "Show" is clicked.
      // `PasswordEntry` has field named `encryptedPassword`. This implies manual encryption.
      // If so, `StorageService` or `EncryptionService` needs to handle it.
      // Let's assume we do manual encryption for the password field.
      // Use `EncryptionService` instance provided by `Provider`?
      // We didn't init `EncryptionService` in `LockScreen`. We only init `StorageService`.
      
      // Let's fix this logic:
      // 1. Password in memory (PasswordController) -> Plain text.
      // 2. On Save -> Encrypt using `EncryptionService` -> Store in `PasswordEntry`.
      // 3. `PasswordEntry` -> Saved to Hive (Encrypted Box) -> Encrypted on disk.
      
      // So we need `EncryptionService` to be initialized with the Master Key.
      // I should update `LockScreen` to init `EncryptionService` too.
      // For now, I'll assume it is available or I will fix `LockScreen` in next step.
      // OR I can get the key from `StorageService`? No, key is private.
      
      // Workaround: We will use a temporary local variable for now, assuming EncryptionService IS initialized.
      // I'll update LockScreen in a distinct step.
      
      // For now in UI:
      final encService = Provider.of<EncryptionService>(context, listen: false);
      _passwordController.text = encService.decryptString(e.encryptedPassword);
    } catch (e) {
      _passwordController.text = 'Error Decrypting';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generatePassword() async {
    if (_passwordController.text.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Overwrite Password?'),
          content: const Text('This will replace the current password with a new one.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Overwrite')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final rnd = Random.secure();
    final pass = List.generate(16, (index) => chars[rnd.nextInt(chars.length)]).join();
    setState(() {
      _passwordController.text = pass;
      _isObscure = false;
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final storage = context.read<StorageService>();
      final encService = context.read<EncryptionService>();
      
      final encryptedPass = encService.encryptString(_passwordController.text);
      
      if (widget.entry != null) {
        // Edit existing entry
        final entry = widget.entry!;
        entry.title = _titleController.text;
        entry.username = _usernameController.text;
        entry.encryptedPassword = encryptedPass;
        entry.website = _urlController.text;
        entry.notes = _notesController.text;
        entry.category = _category;
        entry.isStealth = _isStealth;
        entry.updatedAt = DateTime.now();
        
        await storage.savePassword(entry);
      } else {
        // Create new entry
        final entry = PasswordEntry(
          title: _titleController.text,
          username: _usernameController.text,
          encryptedPassword: encryptedPass,
          website: _urlController.text,
          notes: _notesController.text,
          category: _category,
          isStealth: _isStealth,
        );
        await storage.savePassword(entry);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final storage = context.read<StorageService>();
      await storage.deletePassword(widget.entry!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Add Password' : 'Edit Password', 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.entry != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _delete,
              tooltip: 'Delete',
            ),
          IconButton(onPressed: _save, icon: const Icon(Icons.check, color: Colors.tealAccent), tooltip: 'Save'),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isAndroid ? 20 : 24, 
                    vertical: isAndroid ? 10 : 16
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isAndroid ? double.infinity : 500),
                      child: isAndroid 
                        ? Form(key: _formKey, child: _buildFormFields())
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                                  boxShadow: [
                                     BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 24, spreadRadius: 5)
                                  ]
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: _buildFormFields(),
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGlassTextField(
           controller: _titleController, 
           label: 'Title', 
           icon: Icons.title, 
           validator: (v) => v!.isEmpty ? 'Required' : null
        ),
        const SizedBox(height: 20),
        _buildGlassTextField(
           controller: _usernameController, 
           label: 'Username/Email', 
           icon: Icons.person_outline
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildGlassTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.key,
                isObscure: _isObscure,
                suffixIcon: IconButton(
                  icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                keyboardType: (!kIsWeb && Platform.isAndroid) ? TextInputType.number : null,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF00C9FF).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: IconButton(
                onPressed: _generatePassword,
                icon: const Icon(Icons.refresh, color: Colors.black87),
                tooltip: 'Generate Password',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
         _buildGlassTextField(
           controller: _urlController, 
           label: 'Website URL', 
           icon: Icons.link,
           keyboardType: TextInputType.url
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _category,
          dropdownColor: const Color(0xFF1E1E24).withOpacity(0.9),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Category',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.category, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.tealAccent.withOpacity(0.5))),
          ),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _category = v!),
        ),
        const SizedBox(height: 20),
        _buildGlassTextField(
           controller: _notesController, 
           label: 'Notes', 
           icon: Icons.note, 
           maxLines: 4
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text('Stealth Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: const Text('Hide this item in the normal vault view', style: TextStyle(color: Colors.white54, fontSize: 12)),
          secondary: Icon(Icons.security, color: _isStealth ? Colors.tealAccent : Colors.white70),
          value: _isStealth,
          activeColor: Colors.tealAccent,
          onChanged: (v) => setState(() => _isStealth = v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              elevation: 0,
              side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _save,
            child: const Text('Save Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.tealAccent.withOpacity(0.5))),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
