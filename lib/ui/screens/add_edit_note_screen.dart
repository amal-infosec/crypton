import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../core/encryption_service.dart';
import '../../core/storage_service.dart';
import '../../models/data_models.dart';

class AddEditNoteScreen extends StatefulWidget {
  final SecureNote? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String _category = 'Personal';
  bool _isStealth = false;

  final List<String> _categories = [
    'Personal',
    'Work',
    'Ideas',
    'Developer',
    'Forum',
    'Software',
    'Streaming',
    'YouTube',
    'Cybersecurity',
    'Banking',
    'Secret'
  ];

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleController = TextEditingController(text: n?.title);
    _contentController = TextEditingController();
    _category = n?.category ?? 'Personal';
    _isStealth = n?.isStealth ?? false;

    if (n != null) {
        _decryptContent(n);
    }
  }
  
  void _decryptContent(SecureNote n) {
      try {
          final encService = Provider.of<EncryptionService>(context, listen: false);
          _contentController.text = encService.decryptString(n.encryptedContent);
      } catch (e) {
          _contentController.text = 'Error Decrypting Content';
      }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final storage = context.read<StorageService>();
      final encService = context.read<EncryptionService>();
      
      final encryptedContent = encService.encryptString(_contentController.text);
      
      if (widget.note != null) {
        // Edit existing
        final note = widget.note!;
        note.title = _titleController.text;
        note.encryptedContent = encryptedContent;
        note.category = _category;
        note.isStealth = _isStealth;
        note.updatedAt = DateTime.now();
        await storage.saveNote(note);
      } else {
        // Create new
        final note = SecureNote(
          title: _titleController.text,
          encryptedContent: encryptedContent,
          category: _category,
          isStealth: _isStealth,
        );
        await storage.saveNote(note);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final storage = context.read<StorageService>();
      await storage.deleteNote(widget.note!);
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
        title: Text(widget.note == null ? 'New Private Note' : 'Edit Note', 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.note != null)
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
                      constraints: BoxConstraints(maxWidth: isAndroid ? double.infinity : 600),
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
      children: [
        _buildGlassTextField(
           controller: _titleController, 
           label: 'Title', 
           icon: Icons.title, 
           validator: (v) => v!.isEmpty ? 'Required' : null
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
        SwitchListTile(
          title: const Text('Stealth Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: const Text('Hide this note in the normal vault view', style: TextStyle(color: Colors.white54, fontSize: 12)),
          secondary: Icon(Icons.security, color: _isStealth ? Colors.tealAccent : Colors.white70),
          value: _isStealth,
          activeColor: Colors.tealAccent,
          onChanged: (v) => setState(() => _isStealth = v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _buildGlassTextField(
            controller: _contentController,
            label: 'Confidential Content',
            icon: Icons.notes,
            maxLines: null,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
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
            child: const Text('Save Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      expands: maxLines == null,
      textAlignVertical: maxLines == null ? TextAlignVertical.top : TextAlignVertical.center,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        alignLabelWithHint: maxLines == null,
        prefixIcon: maxLines == null ? Padding(
          padding: const EdgeInsets.only(bottom: 200.0), 
          child: Icon(icon, color: Colors.white70)
        ) : Icon(icon, color: Colors.white70),
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
