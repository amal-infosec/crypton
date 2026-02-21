import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../../core/storage_service.dart';
import '../../core/encryption_service.dart';
import '../../core/auth_service.dart';
import '../screens/lock_screen.dart';

class SettingsTab extends StatefulWidget {
  final String activeTab;
  const SettingsTab({super.key, this.activeTab = 'General'});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {

  // ─────────────── Backup helpers ───────────────

  Future<void> _exportData(BuildContext context) async {
    final password = await _promptBackupPassword(context, 'Set Backup Password', isNew: true);
    if (password == null || password.isEmpty) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Encrypting Backup...')));
    try {
      final storage = context.read<StorageService>();
      final data = storage.getBackupData();
      final jsonStr = jsonEncode(data);
      final bytes = utf8.encode(jsonStr);
      final encryptedBytes = EncryptionService.encryptDataWithPassword(Uint8List.fromList(bytes), password);
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'crypton_backup_$dateStr.xtm';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(encryptedBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'CRYPTON Encrypted Backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      final password = await _promptBackupPassword(context, 'Enter Backup Password', isNew: false);
      if (password == null || password.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Decrypting & Restoring...')));
      try {
        final decryptedBytes = EncryptionService.decryptDataWithPassword(bytes, password);
        final jsonStr = utf8.decode(decryptedBytes);
        final data = jsonDecode(jsonStr);
        final storage = context.read<StorageService>();
        await storage.restoreBackup(data);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore Successful!')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid Password or Corrupt File'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<String?> _promptBackupPassword(BuildContext context, String title, {required bool isNew}) async {
    String? password;
    return showDialog<String>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: title,
        children: [
          if (isNew) const Text('This password encrypts your backup. Do not lose it.', style: TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent)),
            ),
            onChanged: (v) => password = v,
          ),
        ],
        actions: [
          _dialogBtn('Cancel', () => Navigator.pop(ctx), outline: true),
          _dialogBtn(isNew ? 'Export' : 'Restore', () => Navigator.pop(ctx, password),
              color: Colors.tealAccent.withOpacity(0.3)),
        ],
      ),
    );
  }

  // ─────────────── Forgot Password ───────────────

  Future<void> _forgotPassword(BuildContext context) async {
    final authService = context.read<AuthService>();
    String? enteredPin;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: '🔑 Verify Identity',
        icon: Icons.lock_person_outlined,
        iconColor: Colors.orangeAccent,
        children: [
          const Text(
            'Enter your current app password to verify your identity. Wrong password will exit the app.',
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Current Password / PIN',
              labelStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent)),
            ),
            onChanged: (v) => enteredPin = v,
          ),
        ],
        actions: [
          _dialogBtn('Cancel', () => Navigator.pop(ctx, false), outline: true),
          _dialogBtn('Verify', () => Navigator.pop(ctx, true), color: Colors.orangeAccent.withOpacity(0.3)),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final (result, _) = await authService.authenticate(enteredPin ?? '');
    if (!context.mounted) return;

    if (result != AuthResult.successReal && result != AuthResult.successFake) {
      // Wrong password — exit app
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _GlassDialog(
          title: '⛔ Access Denied',
          iconColor: Colors.red,
          children: const [
            Text('Incorrect password. The app will now close for security.', style: TextStyle(color: Colors.white70, height: 1.5)),
          ],
          actions: [
            _dialogBtn('Exit App', () { Navigator.pop(ctx); exit(0); }, color: Colors.red.withOpacity(0.35)),
          ],
        ),
      );
      return;
    }

    // Correct — let them set new password (navigate to lock screen setup flow)
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identity verified. Feature: Use lock screen to re-setup PIN.')));
  }

  // ─────────────── Factory Reset ───────────────

  Future<void> _factoryReset(BuildContext context) async {
    // Warning 1
    final warn1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: '⚠️ Factory Reset',
        iconColor: Colors.orange,
        children: const [
          Text(
            'This will erase ALL your data including passwords and notes. This action CANNOT be undone.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ],
        actions: [
          _dialogBtn('Cancel', () => Navigator.pop(ctx, false), outline: true),
          _dialogBtn('I Understand — Continue', () => Navigator.pop(ctx, true), color: Colors.orange.withOpacity(0.3)),
        ],
      ),
    );
    if (warn1 != true || !context.mounted) return;

    // Warning 2
    final warn2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: '🚨 Final Warning',
        iconColor: Colors.deepOrange,
        children: const [
          Text(
            'You are about to permanently destroy all stored data. There is NO recovery option. Export a backup first if needed.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ],
        actions: [
          _dialogBtn('Cancel', () => Navigator.pop(ctx, false), outline: true),
          _dialogBtn('Proceed to Reset', () => Navigator.pop(ctx, true), color: Colors.deepOrange.withOpacity(0.35)),
        ],
      ),
    );
    if (warn2 != true || !context.mounted) return;

    // Password confirmation
    String? enteredPin;
    final authService = context.read<AuthService>();
    final pinConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: '🔒 Confirm with Password',
        iconColor: Colors.red,
        children: [
          const Text('Enter your current password to authorize the reset.', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            autofocus: true, obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Current Password / PIN',
              labelStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
            ),
            onChanged: (v) => enteredPin = v,
          ),
        ],
        actions: [
          _dialogBtn('Cancel', () => Navigator.pop(ctx, false), outline: true),
          _dialogBtn('Reset Now', () => Navigator.pop(ctx, true), color: Colors.red.withOpacity(0.35)),
        ],
      ),
    );
    if (pinConfirmed != true || !context.mounted) return;

    final (result, _) = await authService.authenticate(enteredPin ?? '');
    if (!context.mounted) return;

    if (result != AuthResult.successReal) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password. Reset cancelled.'), backgroundColor: Colors.red));
      return;
    }

    final storage = context.read<StorageService>();
    await storage.clearAll();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LockScreen()),
        (route) => false,
      );
    }
  }

  // ─────────────── Destroy All Data ───────────────

  Future<void> _destroyAllData(BuildContext context) async {
    // Warning 1
    final warn1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: '💣 DESTROY ALL DATA',
        iconColor: Colors.red,
        children: const [
          Text(
            'This operation will PERMANENTLY DELETE every password and note stored in this app. The data is irrecoverable.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ],
        actions: [
          _dialogBtn('Back to Safety', () => Navigator.pop(ctx, false), outline: true),
          _dialogBtn('Continue', () => Navigator.pop(ctx, true), color: Colors.red.withOpacity(0.3)),
        ],
      ),
    );
    if (warn1 != true || !context.mounted) return;

    // Warning 2
    final warn2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: '⛔ Are You Absolutely Sure?',
        iconColor: Colors.red.shade800,
        children: const [
          Text(
            'ALL passwords, notes, and categories will be wiped. No backup will be created. This is your last chance to cancel.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ],
        actions: [
          _dialogBtn('Cancel', () => Navigator.pop(ctx, false), outline: true),
          _dialogBtn('Yes, Delete Everything', () => Navigator.pop(ctx, true), color: Colors.red.withOpacity(0.4)),
        ],
      ),
    );
    if (warn2 != true || !context.mounted) return;

    // Warning 3 — final
    final warn3 = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: '🔥 POINT OF NO RETURN',
        iconColor: Colors.red.shade900,
        children: const [
          Text(
            'Once confirmed, all data is wiped immediately. The app will reset to initial state. This cannot be reversed, ever.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
          SizedBox(height: 12),
          Text('Type carefully. There is no undo.', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
        actions: [
          _dialogBtn('Abort', () => Navigator.pop(ctx, false), outline: true),
          _dialogBtn('DESTROY', () => Navigator.pop(ctx, true), color: Colors.red.withOpacity(0.5)),
        ],
      ),
    );
    if (warn3 != true || !context.mounted) return;

    // Verify password
    String? enteredPin;
    final authService = context.read<AuthService>();
    final pinConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: '🔐 Final Authorization',
        iconColor: Colors.redAccent,
        children: [
          const Text('Enter your password to execute the destruction.', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            autofocus: true, obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password / PIN',
              labelStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
            ),
            onChanged: (v) => enteredPin = v,
          ),
        ],
        actions: [
          _dialogBtn('Cancel', () => Navigator.pop(ctx, false), outline: true),
          _dialogBtn('Execute DESTROY', () => Navigator.pop(ctx, true), color: Colors.red.withOpacity(0.45)),
        ],
      ),
    );
    if (pinConfirmed != true || !context.mounted) return;

    final (result, _) = await authService.authenticate(enteredPin ?? '');
    if (!context.mounted) return;

    if (result != AuthResult.successReal) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password. Operation cancelled.'), backgroundColor: Colors.red));
      return;
    }

    final storage = context.read<StorageService>();
    await storage.clearAll();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LockScreen()),
        (route) => false,
      );
    }
  }

  // ─────────────── Help Dialog ───────────────

  void _showHelp(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved), child: child),
        );
      },
      pageBuilder: (ctx, _, __) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 440,
                constraints: const BoxConstraints(maxHeight: 560),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1735).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.tealAccent.withOpacity(0.25), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.tealAccent.withOpacity(0.1), blurRadius: 40)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08)))),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: Colors.tealAccent.withOpacity(0.12), shape: BoxShape.circle),
                            child: const Icon(Icons.help_outline, color: Colors.tealAccent, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(child: Text('Help & Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.06), shape: const CircleBorder())),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _helpItem('🔒', 'Passwords', 'Store, copy and manage passwords by category. Double-click a tile to open full details.'),
                            _helpItem('📝', 'Notes', 'Create encrypted secure notes. Click a note to open a preview popup.'),
                            _helpItem('🔑', 'Forgot Password', 'Go to Settings → General → Forgot Password. Verify your current PIN to proceed.'),
                            _helpItem('💾', 'Backup & Restore', 'Export an encrypted .xtm backup. Keep the backup password safe — it cannot be recovered.'),
                            _helpItem('💣', 'Destroy / Reset', 'Use Factory Reset to wipe all data and start fresh. Use Destroy for emergency data deletion.'),
                            _helpItem('🛡️', 'Security', 'All data is AES-256 encrypted before being stored locally. Nothing leaves your device.'),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08)))),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent.withOpacity(0.2), foregroundColor: Colors.tealAccent,
                            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text('Got it'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _helpItem(String emoji, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 3),
              Text(body, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5)),
            ]),
          ),
        ],
      ),
    );
  }

  // ─────────────── Build ───────────────

  @override
  Widget build(BuildContext context) {
    switch (widget.activeTab) {
      case 'Security': return _buildSecurityTab(context);
      case 'Import':   return _buildImportTab(context);
      case 'Export':   return _buildExportTab(context);
      case 'About':    return _buildAboutTab(context);
      default:         return _buildGeneralTab(context);
    }
  }

  // ─────────────── General Tab ───────────────

  Widget _buildGeneralTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        _sectionLabel('ACCOUNT RECOVERY'),
        const SizedBox(height: 10),
        _glassTile(icon: Icons.help_outline, label: 'Forgot Password', sub: 'Verify current password to proceed',
            color: Colors.orangeAccent, onTap: () => _forgotPassword(context)),
        const SizedBox(height: 20),
        _sectionLabel('DANGER ZONE'),
        const SizedBox(height: 10),
        _glassTile(icon: Icons.restart_alt, label: 'Factory Reset', sub: 'Erase all data and reset application',
            color: Colors.deepOrange, onTap: () => _factoryReset(context)),
        const SizedBox(height: 10),
        _glassTile(icon: Icons.local_fire_department, label: 'DESTROY', sub: 'Permanently delete all passwords & notes',
            color: Colors.red, onTap: () => _destroyAllData(context)),
        const SizedBox(height: 20),
        _sectionLabel('SUPPORT'),
        const SizedBox(height: 10),
        _glassTile(icon: Icons.help_center_outlined, label: 'Help & Guide', sub: 'How to use Crypton',
            color: Colors.blueAccent, onTap: () => _showHelp(context)),
      ],
    );
  }

  // ─────────────── Import Tab ───────────────

  Widget _buildImportTab(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'name': '1Password',  'sub': '1pux, 1pif', 'initials': '1P',  'color': const Color(0xFF0A55D1)},
      {'name': 'Bitwarden',  'sub': 'json',        'icon': Icons.security,      'color': const Color(0xFF175DDC)},
      {'name': 'Brave',      'sub': 'csv',         'icon': Icons.public,        'color': const Color(0xFFFF4A00)},
      {'name': 'Chrome',     'sub': 'csv',         'icon': Icons.public,        'color': const Color(0xFF4285F4)},
      {'name': 'Dashlane',   'sub': 'zip, csv',    'initials': 'D',   'color': const Color(0xFF0F3542)},
      {'name': 'Edge',       'sub': 'csv',         'icon': Icons.public,        'color': const Color(0xFF0078D7)},
      {'name': 'Enpass',     'sub': 'json',        'icon': Icons.security,      'color': const Color(0xFF0F9D58)},
      {'name': 'Firefox',    'sub': 'csv',         'icon': Icons.public,        'color': const Color(0xFFFF7139)},
      {'name': 'Kaspersky',  'sub': 'txt',         'icon': Icons.security,      'color': const Color(0xFF00A88E)},
      {'name': 'KeePass',    'sub': 'xml',         'icon': Icons.lock,          'color': const Color(0xFF1D5A79)},
      {'name': 'Keeper',     'sub': 'csv',         'initials': 'K',   'color': const Color(0xFFF1C40F)},
      {'name': 'LastPass',   'sub': 'csv',         'icon': Icons.more_horiz,    'color': const Color(0xFFD32D27)},
      {'name': 'NordPass',   'sub': 'csv',         'icon': Icons.security,      'color': const Color(0xFF1B1B1B)},
      {'name': 'Proton Pass','sub': 'json',        'icon': Icons.shield,        'color': const Color(0xFFD1C4E9)},
      {'name': 'Roboform',   'sub': 'csv',         'icon': Icons.assignment,    'color': const Color(0xFF2E7D32)},
      {'name': 'Safari',     'sub': 'csv',         'icon': Icons.explore,       'color': const Color(0xFF1EA362)},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Import from another password manager',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Select your existing password manager to import your vault.',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 1.3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, i) {
                final item = items[i];
                Widget badge;
                if (item['icon'] != null) {
                  badge = Icon(item['icon'] as IconData, color: item['color'] as Color, size: 26);
                } else {
                  badge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item['initials'] as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  );
                }
                return _ImportCard(badge: badge, name: item['name'] as String, sub: item['sub'] as String);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── Export Tab ───────────────

  Widget _buildExportTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        _sectionLabel('ENCRYPTED BACKUP'),
        const SizedBox(height: 12),
        _glassTile(
          icon: Icons.download,
          label: 'Export Encrypted Backup',
          sub: 'Save your entire vault to an encrypted .xtm file',
          color: Colors.tealAccent,
          onTap: () => _exportData(context),
        ),
        const SizedBox(height: 24),
        _sectionLabel('RESTORE'),
        const SizedBox(height: 12),
        _glassTile(
          icon: Icons.upload,
          label: 'Import Encrypted Backup',
          sub: 'Restore from a previously exported .xtm backup file',
          color: Colors.tealAccent,
          onTap: () => _importData(context),
        ),
        const SizedBox(height: 24),
        _infoTile(
          icon: Icons.info_outline,
          label: 'Backup Password Required',
          sub: 'Your backup is password-protected. The backup password is separate from your vault PIN.',
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  // ─────────────── Security Tab ───────────────

  Widget _buildSecurityTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        _sectionLabel('SECURITY STANDARDS'),
        const SizedBox(height: 10),
        _infoTile(icon: Icons.enhanced_encryption, label: 'AES-256 Encryption',
            sub: 'All data is encrypted using AES-256-CBC before storage', color: Colors.tealAccent),
        const SizedBox(height: 10),
        _infoTile(icon: Icons.fingerprint, label: 'Local Authentication',
            sub: 'Biometric and PIN-based vault unlocking', color: Colors.purpleAccent),
        const SizedBox(height: 10),
        _infoTile(icon: Icons.storage, label: 'On-Device Storage Only',
            sub: 'No cloud sync. All data stays on your device', color: Colors.greenAccent),
        const SizedBox(height: 10),
        _infoTile(icon: Icons.key, label: 'Master Key Isolation',
            sub: 'Real and decoy vaults use separate cryptographic keys', color: Colors.amberAccent),
        const SizedBox(height: 20),
        _sectionLabel('SECURITY PRACTICES'),
        const SizedBox(height: 10),
        _infoTile(icon: Icons.content_paste_off, label: 'Clipboard Auto-Clear',
            sub: 'Copied passwords are wiped from clipboard after 30 seconds', color: Colors.cyanAccent),
        const SizedBox(height: 10),
        _infoTile(icon: Icons.visibility_off, label: 'Masked Passwords',
            sub: 'Passwords are never shown in plain text in list views', color: Colors.orangeAccent),
        const SizedBox(height: 10),
        _infoTile(icon: Icons.no_photography, label: 'Screenshot Protection',
            sub: 'Sensitive screens may block screen capture on supported platforms', color: Colors.redAccent),
        const SizedBox(height: 20),
        _sectionLabel('PRIVACY NOTICE'),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.security_update_warning, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  const Text('Do Not Expose App Secrets', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
                const SizedBox(height: 10),
                const Text(
                  '• Do not share your PIN or backup password with anyone.\n'
                  '• Do not install the app from unofficial sources.\n'
                  '• Do not grant unnecessary permissions to screen readers.\n'
                  '• Your master PIN is the single point of access — protect it.',
                  style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.7),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────── About Tab ───────────────

  Widget _buildAboutTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        // App logo & name
        Center(
          child: Column(
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.45), blurRadius: 28, spreadRadius: 2),
                    BoxShadow(color: const Color(0xFF2DD4BF).withOpacity(0.2), blurRadius: 16),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset('assets/icon/icon.png', width: 88, height: 88, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              const Text('CRYPTON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26, letterSpacing: 4)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.tealAccent.withOpacity(0.25)),
                ),
                child: const Text('Secure Password & Notes Vault', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _sectionLabel('APP INFORMATION'),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _aboutRow('App Name', 'Crypton'),
                  _divider(),
                  _aboutRow('Developer', 'IU_MTX'),
                  _divider(),
                  _aboutRow('Version', 'v1.1 DE'),
                  _divider(),
                  _aboutRow('Copyright', '© AURYNTRIX'),
                  _divider(),
                  _aboutRow('Build', 'Proprietary — Internal Distribution Only'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _sectionLabel('BUILD NOTICE'),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.09)),
              ),
              child: const Text(
                'This build of Crypton is intended exclusively for authorized personal use. '
                'Redistribution, reverse engineering, or commercial deployment of this software '
                'without explicit written consent from AURYNTRIX is strictly prohibited. '
                'Use of this application constitutes acceptance of these terms.',
                style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.7),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.white.withOpacity(0.07), height: 1);

  // ─────────────── Reusable widgets ───────────────

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _glassTile({required IconData icon, required String label, required String sub,
      required Color color, VoidCallback? onTap}) {
    return _HoverTile(icon: icon, label: label, sub: sub, color: color, onTap: onTap);
  }

  Widget _infoTile({required IconData icon, required String label, required String sub, required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 3),
              Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ─────────────── Hoverable Tile ───────────────

class _HoverTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback? onTap;

  const _HoverTile({required this.icon, required this.label, required this.sub, required this.color, this.onTap});

  @override
  State<_HoverTile> createState() => _HoverTileState();
}

class _HoverTileState extends State<_HoverTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? widget.color.withOpacity(0.35) : Colors.white.withOpacity(0.09),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered ? [BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 12)] : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _hovered ? widget.color.withOpacity(0.18) : Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: _hovered ? widget.color : Colors.white54, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.label, style: TextStyle(
                  color: _hovered ? Colors.white : Colors.white.withOpacity(0.88),
                  fontWeight: FontWeight.w600, fontSize: 14,
                )),
                const SizedBox(height: 3),
                Text(widget.sub, style: TextStyle(
                  color: _hovered ? Colors.white54 : Colors.white30, fontSize: 12)),
              ])),
              if (widget.onTap != null)
                AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.chevron_right, color: widget.color, size: 20),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────── Reusable Glass Dialog ───────────────

class _GlassDialog extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget> children;
  final List<Widget> actions;

  const _GlassDialog({
    required this.title,
    this.icon,
    this.iconColor,
    required this.children,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1735).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: (iconColor ?? Colors.tealAccent).withOpacity(0.25), width: 1.5),
                  boxShadow: [BoxShadow(color: (iconColor ?? Colors.tealAccent).withOpacity(0.1), blurRadius: 40)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07)))),
                      child: Row(children: [
                        if (icon != null) ...[
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: (iconColor ?? Colors.tealAccent).withOpacity(0.12), shape: BoxShape.circle),
                            child: Icon(icon, color: iconColor ?? Colors.tealAccent, size: 20),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17))),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                      child: Row(
                        children: actions.map((a) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: a))).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _dialogBtn(String label, VoidCallback onTap, {bool outline = false, Color? color}) {
  if (outline) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white60,
        side: BorderSide(color: Colors.white.withOpacity(0.15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
  return ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color ?? Colors.tealAccent.withOpacity(0.2),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
    child: Text(label, style: const TextStyle(fontSize: 13)),
  );
}

// ─────────────── Import Card ───────────────

class _ImportCard extends StatefulWidget {
  final Widget badge;
  final String name;
  final String sub;
  const _ImportCard({required this.badge, required this.name, required this.sub});

  @override
  State<_ImportCard> createState() => _ImportCardState();
}

class _ImportCardState extends State<_ImportCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['csv', 'json', 'txt', 'xml', 'zip', '1pux', '1pif'],
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? Colors.white.withOpacity(0.25) : Colors.white12,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered ? [BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 10)] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.badge,
              const SizedBox(height: 10),
              Text(widget.name, style: TextStyle(
                color: _hovered ? Colors.white : Colors.white.withOpacity(0.85),
                fontSize: 13, fontWeight: FontWeight.w500,
              )),
              const SizedBox(height: 3),
              Text(widget.sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
