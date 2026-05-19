import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/app_background.dart';
import 'lock_screen.dart';
import 'package:animations/animations.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isLoading = false;

  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);
    try {
      final box = await Hive.openBox('app_settings');
      await box.put('terms_accepted', true);
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LockScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Security & Privacy',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        _buildFeatureRow(
                          icon: Icons.lock_outline,
                          title: 'Local-Only Encryption',
                          description: 'Your data never leaves this device. We do not use any cloud syncing, meaning only you hold the keys to your vault.',
                        ),
                        const SizedBox(height: 24),
                        
                        _buildFeatureRow(
                          icon: Icons.visibility_off_outlined,
                          title: 'Zero Telemetry',
                          description: 'We do not collect analytics, telemetry, or crash reports. Your usage remains 100% private and anonymous.',
                        ),
                        const SizedBox(height: 24),

                        _buildFeatureRow(
                          icon: Icons.shield_outlined,
                          title: 'OS-Level Protections',
                          description: 'Standard system vulnerabilities are mitigated. On Android, background snapshots and screen capturing are restricted by default.',
                        ),
                        
                        const SizedBox(height: 48),
                        
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : ElevatedButton(
                                onPressed: _acceptTerms,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Accept & Continue',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
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
        ),
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
