
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/storage_service.dart';

class StealthAuthScreen extends StatefulWidget {
  const StealthAuthScreen({super.key});

  @override
  State<StealthAuthScreen> createState() => _StealthAuthScreenState();
}

class _StealthAuthScreenState extends State<StealthAuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _error = '';

  Future<void> _unlock() async {
    final auth = context.read<AuthService>();
    final storage = context.read<StorageService>();
    
    final success = await auth.authenticateStealth(_pinController.text);
    if (success) {
      storage.setStealthUnlocked(true);
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stealth Vault Unlocked'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _error = 'Invalid Stealth PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
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
                child: Image.asset('assets/icon/icon.png', width: 64, height: 64, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Stealth Authorization',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter secondary PIN to reveal hidden items',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              onSubmitted: (_) => _unlock(),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _unlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.withOpacity(0.2),
                  foregroundColor: Colors.tealAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Unlock Partition', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
