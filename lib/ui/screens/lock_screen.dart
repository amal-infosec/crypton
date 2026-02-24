import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'dart:ui';

import '../../core/auth_service.dart';
import '../../core/storage_service.dart';
import '../../core/encryption_service.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _passController = TextEditingController();
  final FocusNode _passFocusNode = FocusNode();
  bool _obscureText = true;
  String _statusMessage = 'Enter Password';
  bool _isSetupMode = false;

  // Setup flow state
  int _setupStep = 0; // 0: Real, 1: Confirm Real, 2: Fake, 3: Confirm Fake
  String _tempRealPin = '';
  String _tempFakePin = '';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccount();
  }

  @override
  void dispose() {
    _passController.dispose();
    _passFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAccount() async {
    final authQuery = context.read<AuthService>();
    await authQuery.init(); // Ensure init
    final hasAccount = await authQuery.hasAccount();

    setState(() {
      _isLoading = false;
      _isSetupMode = !hasAccount;
      if (_isSetupMode) {
        _statusMessage = 'Create Master Password';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _passFocusNode.requestFocus();
        });
      } else {
        // Delay keyboard focus on mobile to allow biometrics to show first
        if (kIsWeb || (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
            _passFocusNode.requestFocus();
          });
        }
        _tryBiometricAuth(); 
      }
    });
  }

  Future<void> _tryBiometricAuth() async {
    final authService = context.read<AuthService>();
    final (result, key) = await authService.authenticateWithBiometrics();

    if (!mounted) return;
    if (result == AuthResult.successReal && key != null) {
      context.read<EncryptionService>().init(key);
      await context.read<StorageService>().init(key, isFakeMode: false);
      _navToHome();
    }
  }

  Future<void> _submitPassword() async {
    final pin = _passController.text;
    if (pin.isEmpty) {
      _showError('Password cannot be empty');
      return;
    }

    final authService = context.read<AuthService>();
    final storageService = context.read<StorageService>();

    if (_isSetupMode) {
      // Setup Flow
      switch (_setupStep) {
        case 0: // Create Real
          _tempRealPin = pin;
          setState(() {
            _passController.clear();
            _setupStep++;
            _statusMessage = 'Confirm Master Password';
          });
          _passFocusNode.requestFocus();
          break;
        case 1: // Confirm Real
          if (pin == _tempRealPin) {
            setState(() {
              _passController.clear();
              _setupStep++;
              _statusMessage = 'Create Duress Password (Fake)';
            });
            _passFocusNode.requestFocus();
          } else {
            _showError('Passwords do not match');
            setState(() {
              _passController.clear();
              _setupStep = 0;
              _statusMessage = 'Create Master Password';
            });
            _passFocusNode.requestFocus();
          }
          break;
        case 2: // Create Fake
          _tempFakePin = pin;
          if (_tempFakePin == _tempRealPin) {
            _showError('Fake Password must be different!');
            setState(() {
              _passController.clear();
            });
            _passFocusNode.requestFocus();
            return;
          }
          setState(() {
            _passController.clear();
            _setupStep++;
            _statusMessage = 'Confirm Duress Password';
          });
          _passFocusNode.requestFocus();
          break;
        case 3: // Confirm Fake
          if (pin == _tempFakePin) {
            // Saving...
            setState(() => _isLoading = true);
            await authService.setupKeys(_tempRealPin, _tempFakePin);

            // Auto login real
            final (result, key) = await authService.authenticate(_tempRealPin);
            if (!mounted) return;
            if (result == AuthResult.successReal && key != null) {
              context.read<EncryptionService>().init(key);
              await storageService.init(key, isFakeMode: false);
              _navToHome();
            }
          } else {
            _showError('Passwords do not match');
            setState(() {
              _passController.clear();
              _setupStep = 2;
              _statusMessage = 'Create Duress Password (Fake)';
            });
            _passFocusNode.requestFocus();
          }
          break;
      }
    } else {
      // Auth Flow
      setState(() => _isLoading = true);

      final (result, key) = await authService.authenticate(pin);
      if (!mounted) return;

      if (result == AuthResult.successReal && key != null) {
        context.read<EncryptionService>().init(key);
        await storageService.init(key, isFakeMode: false);
        _navToHome();
      } else if (result == AuthResult.successFake && key != null) {
        context.read<EncryptionService>().init(key);
        await storageService.init(key, isFakeMode: true);
        _navToHome();
      } else {
        setState(() {
          _isLoading = false;
          _passController.clear();
        });
        _passFocusNode.requestFocus();
        _showError('Incorrect Password');
      }
    }
  }

  void _navToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF020617)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ...[
             // Simplified background for mobile to reduce lag
          ] else ...[
            Positioned(
              top: -150,
              left: -150,
              child: Container(
                width: 700,
                height: 700,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.35),
                      const Color(0xFF6366F1).withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -250,
              right: -200,
              child: Container(
                width: 800,
                height: 800,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.35),
                      const Color(0xFF8B5CF6).withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ],
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06), 
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 64,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 48),
                            TextField(
                              controller: _passController,
                              focusNode: _passFocusNode,
                              obscureText: _obscureText,
                              autofocus: false,
                              onSubmitted: (_) => _submitPassword(),
                              keyboardType: (!kIsWeb && Platform.isAndroid) ? TextInputType.number : TextInputType.text,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: GoogleFonts.outfit(
                                  fontSize: 16,
                                  letterSpacing: 1,
                                  color: Colors.white54,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.white70,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureText = !_obscureText,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.black,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _submitPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Continue',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            if (!_isSetupMode) ...[
                              const SizedBox(height: 24),
                              TextButton.icon(
                                onPressed: _tryBiometricAuth,
                                icon: const Icon(
                                  Icons.fingerprint,
                                  color: Colors.white70,
                                ),
                                label: const Text(
                                  'Use Biometrics',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
