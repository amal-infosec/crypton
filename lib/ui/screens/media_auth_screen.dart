
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/storage_service.dart';

class MediaAuthScreen extends StatefulWidget {
  final bool isSettingUp;
  const MediaAuthScreen({super.key, this.isSettingUp = false});

  @override
  State<MediaAuthScreen> createState() => _MediaAuthScreenState();
}

class _MediaAuthScreenState extends State<MediaAuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _error = '';

  Future<void> _handleAction() async {
    final auth = context.read<AuthService>();
    final storage = context.read<StorageService>();
    
    if (widget.isSettingUp) {
      if (_pinController.text.length < 4) {
        setState(() => _error = 'PIN must be at least 4 digits');
        return;
      }
      await auth.setupMediaPIN(_pinController.text);
      storage.setMediaUnlocked(true);
      if (mounted) Navigator.pop(context);
    } else {
      final success = await auth.authenticateMedia(_pinController.text);
      if (success) {
        storage.setMediaUnlocked(true);
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _error = 'Invalid Media Vault PIN');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 400, // Fixed width for desktop/tablet feels more like an alert box
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.45), blurRadius: 20, spreadRadius: 1),
                  BoxShadow(color: const Color(0xFF2DD4BF).withOpacity(0.2), blurRadius: 12),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.white.withOpacity(0.05),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.tealAccent, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.isSettingUp ? 'Secure Media Vault' : 'Media Vault Locked',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isSettingUp ? 'Set a dedicated PIN for your media' : 'Enter PIN to access your private media',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              obscureText: true,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 20),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _handleAction(),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white54,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.withOpacity(0.2),
                      foregroundColor: Colors.tealAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(widget.isSettingUp ? 'Enable' : 'Unlock', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
