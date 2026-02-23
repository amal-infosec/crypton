import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../core/storage_service.dart';
import '../../core/encryption_service.dart';
import 'add_edit_password_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  dynamic _selectedEntry;

  IconData _getIconForCategory(String c) {
    switch (c) {
      case 'Social': return Icons.people_outline;
      case 'Email': return Icons.email_outlined;
      case 'Finance': return Icons.account_balance_wallet_outlined;
      case 'Work': return Icons.work_outline;
      case 'Wifi': return Icons.wifi;
      case 'Shopping': return Icons.shopping_cart;
      case 'Developer': return Icons.code;
      case 'Forum': return Icons.forum_outlined;
      case 'Software': return Icons.terminal;
      case 'Streaming': return Icons.movie_filter_outlined;
      case 'YouTube': return Icons.play_circle_outline;
      case 'Cybersecurity': return Icons.security_rounded;
      case 'Personal': return Icons.person_pin_outlined;
      case 'Banking': return Icons.account_balance;
      case 'General': return Icons.category_outlined;
      case 'Other': return Icons.category_outlined;
      default: return Icons.lock_outline;
    }
  }

  Color _getColorForCategory(String c) {
    switch (c) {
      case 'Social': return const Color(0xFF42A5F5);
      case 'Email': return const Color(0xFFEF5350);
      case 'Finance': return const Color(0xFF66BB6A);
      case 'Work': return const Color(0xFF8D6E63);
      case 'Wifi': return const Color(0xFFFFA726);
      case 'Shopping': return const Color(0xFFAB47BC);
      case 'All': return const Color(0xFFB388FF);
      case 'Developer': return Colors.tealAccent;
      case 'Forum': return Colors.lightBlueAccent;
      case 'Software': return Colors.indigoAccent;
      case 'Streaming': return Colors.pinkAccent;
      case 'YouTube': return Colors.redAccent;
      case 'Cybersecurity': return Colors.lightGreenAccent;
      case 'Personal': return Colors.orangeAccent;
      case 'Banking': return Colors.amberAccent;
      case 'General': return const Color(0xFFBDBDBD);
      case 'Other': return const Color(0xFFBDBDBD);
      default: return Colors.tealAccent;
    }
  }

  void _copyPassword(BuildContext context, dynamic entry) {
    final encService = context.read<EncryptionService>();
    try {
      final pass = encService.decryptString(entry.encryptedPassword);
      Clipboard.setData(ClipboardData(text: pass));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password copied! Clears in 30s'), duration: Duration(seconds: 2)));
      Future.delayed(const Duration(seconds: 30), () => Clipboard.setData(const ClipboardData(text: '')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error decrypting')));
    }
  }

  /// Fluid spring-like popup — double-click a tile to open this
  void _showPasswordPopup(BuildContext context, dynamic entry, Color catColor) {
    final icon = _getIconForCategory(entry.category);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.50),
      transitionDuration: const Duration(milliseconds: 420),
      transitionBuilder: (ctx, anim, _, child) {
        // Spring-feel: overshoot slightly then settle
        final spring = CurvedAnimation(parent: anim, curve: const ElasticOutCurve(0.75));
        final fade   = CurvedAnimation(parent: anim, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(spring),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (ctx, anim, _) {
        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: 440,
                  constraints: const BoxConstraints(maxHeight: 560),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1735).withOpacity(0.93),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: catColor.withOpacity(0.28), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: catColor.withOpacity(0.18), blurRadius: 48, spreadRadius: 0),
                      BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 32),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header ──
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.14),
                                shape: BoxShape.circle,
                                border: Border.all(color: catColor.withOpacity(0.4), width: 1.5),
                                boxShadow: [BoxShadow(color: catColor.withOpacity(0.2), blurRadius: 16)],
                              ),
                              child: Icon(icon, color: catColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(entry.category,
                                      style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.06),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Body ──
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _popupField(Icons.person_outline, 'USERNAME', entry.username, catColor),
                              const SizedBox(height: 16),
                              _popupMaskedField(Icons.lock_outline, 'PASSWORD', catColor),
                              if ((entry.website ?? '').isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _popupField(Icons.language, 'WEBSITE', entry.website!, catColor),
                              ],
                              if ((entry.notes ?? '').isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _popupField(Icons.notes_outlined, 'NOTES', entry.notes!, catColor, multiline: true),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // ── Actions ──
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close, size: 15),
                                label: const Text('Close'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white60,
                                  side: BorderSide(color: Colors.white.withOpacity(0.14)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _copyPassword(ctx, entry),
                                icon: const Icon(Icons.copy, size: 15),
                                label: const Text('Copy Password'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: catColor.withOpacity(0.3),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => AddEditPasswordScreen(entry: entry)));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.08),
                                foregroundColor: Colors.white70,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                              ),
                              child: const Icon(Icons.edit_outlined, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _popupField(IconData icon, String label, String value, Color catColor, {bool multiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 12, color: catColor.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          child: Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: multiline ? 5 : 1,
            overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _popupMaskedField(IconData icon, String label, Color catColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 12, color: catColor.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          child: Row(
            children: [
              const Text('••••••••••••',
                style: TextStyle(color: Colors.white54, fontSize: 18, letterSpacing: 3)),
              const Spacer(),
              Text('Tap Copy below', style: TextStyle(color: catColor.withOpacity(0.6), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPanel({required Widget child, double? width}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.tealAccent, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
      ],
    );
  }

  Widget _buildDecoBottomTip(String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withOpacity(0.6), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 13),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final all = storage.getPasswords();
    final list = widget.category == 'All' ? all : all.where((e) => e.category == widget.category).toList();
    final catColor = _getColorForCategory(widget.category);
    final catIcon = _getIconForCategory(widget.category);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.category,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;

              if (isMobile) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildGlassPanel(
                        child: Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.15), shape: BoxShape.circle,
                                border: Border.all(color: catColor.withOpacity(0.4), width: 1),
                              ),
                              child: Icon(catIcon, color: catColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text('${list.length} items', style: TextStyle(color: catColor.withOpacity(0.7), fontSize: 13)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPasswordScreen())),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: catColor.withOpacity(0.3),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: list.isEmpty
                        ? Center(child: Text('No passwords in ${widget.category}', style: const TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final entry = list[index];
                              return _PasswordTile(
                                entry: entry,
                                isSelected: false,
                                catColor: catColor,
                                getIcon: _getIconForCategory,
                                onTap: () => _showPasswordPopup(context, entry, catColor),
                                onDoubleTap: () => _showPasswordPopup(context, entry, catColor),
                                onCopy: () => _copyPassword(context, entry),
                              );
                            },
                          ),
                    ),
                  ],
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── LEFT PANEL ───
                    SizedBox(
                      width: 200,
                      child: _buildGlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: catColor.withOpacity(0.4), width: 1.5),
                                boxShadow: [BoxShadow(color: catColor.withOpacity(0.3), blurRadius: 20)],
                              ),
                              child: Icon(catIcon, color: catColor, size: 30),
                            ),
                            const SizedBox(height: 16),
                            Text(widget.category,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${list.length} ${list.length == 1 ? 'item' : 'items'}',
                                style: TextStyle(color: catColor, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('VAULT', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
                            ),
                            const SizedBox(height: 8),
                            _infoRow(Icons.shield_outlined, 'AES-256 Encrypted'),
                            const SizedBox(height: 8),
                            _infoRow(Icons.timer_outlined, 'Clipboard: 30s'),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const AddEditPasswordScreen())),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add New', style: TextStyle(fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: catColor.withOpacity(0.3),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const Spacer(),
                            _buildDecoBottomTip('Double-click a tile\nto view details', Icons.mouse, catColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // ─── CENTER LIST ───
                    Expanded(
                      child: list.isEmpty
                          ? _buildGlassPanel(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(catIcon, size: 48, color: catColor.withOpacity(0.5)),
                                    const SizedBox(height: 16),
                                    Text('No ${widget.category} passwords',
                                        style: const TextStyle(color: Colors.white54, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    const Text('Tap "Add New" to get started',
                                        style: TextStyle(color: Colors.white30, fontSize: 13)),
                                  ],
                                ),
                              ),
                            )
                          : ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final entry = list[index];
                                  final isSelected = _selectedEntry == entry;
                                  return _PasswordTile(
                                    entry: entry,
                                    isSelected: isSelected,
                                    catColor: catColor,
                                    getIcon: _getIconForCategory,
                                    // Single click → preview in right panel
                                    onTap: () => setState(() => _selectedEntry = isSelected ? null : entry),
                                    // Double click → popup
                                    onDoubleTap: () => _showPasswordPopup(context, entry, catColor),
                                    onCopy: () => _copyPassword(context, entry),
                                  );
                                },
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),

                    // ─── RIGHT PANEL ───
                    SizedBox(
                      width: 200,
                      child: _buildGlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                transitionBuilder: (child, anim) => FadeTransition(
                                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                                  child: SlideTransition(
                                    position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                    child: child,
                                  ),
                                ),
                                child: _selectedEntry == null
                                    ? _buildEmptyPreview(catColor)
                                    : _buildFilledPreview(catColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPreview(Color catColor) {
    return Column(
      key: const ValueKey('empty'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [catColor.withOpacity(0.6), Colors.purple.withOpacity(0.3)],
          ).createShader(bounds),
          child: const Icon(Icons.touch_app_outlined, size: 42, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text('Click to select',
          style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text('Double-click to\nopen full details',
          style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.white12),
        const SizedBox(height: 16),
        _buildInfoTip(Icons.ads_click, 'Single: preview here', _getColorForCategory(widget.category)),
        const SizedBox(height: 10),
        _buildInfoTip(Icons.open_in_full, 'Double: full popup', _getColorForCategory(widget.category)),
        const SizedBox(height: 10),
        _buildInfoTip(Icons.copy_outlined, 'Copy from popup', _getColorForCategory(widget.category)),
        const Spacer(),
        _buildDecoBottomTip('Click Copy to secure\nclipboard access', Icons.copy_outlined, _getColorForCategory(widget.category)),
      ],
    );
  }

  Widget _buildFilledPreview(Color catColor) {
    return Column(
      key: const ValueKey('filled'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: catColor.withOpacity(0.2),
              child: Icon(_getIconForCategory(_selectedEntry!.category), color: catColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_selectedEntry!.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: Colors.white12),
        const SizedBox(height: 12),
        Text('USERNAME', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(_selectedEntry!.username,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Text('CATEGORY', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: catColor.withOpacity(0.14), borderRadius: BorderRadius.circular(8)),
          child: Text(_selectedEntry!.category, style: TextStyle(color: catColor, fontSize: 12)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showPasswordPopup(context, _selectedEntry!, catColor),
            icon: const Icon(Icons.open_in_full, size: 15),
            label: const Text('Open Details', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: catColor.withOpacity(0.3),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _copyPassword(context, _selectedEntry!),
            icon: const Icon(Icons.copy, size: 15),
            label: const Text('Copy Password', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withOpacity(0.18)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const Spacer(),
        _buildDecoBottomTip('Double-click tile for\nfull details popup', Icons.mouse, catColor),
      ],
    );
  }
}

/// Each tile is its own StatefulWidget — AnimatedContainer isolates rebuilds
class _PasswordTile extends StatefulWidget {
  final dynamic entry;
  final bool isSelected;
  final Color catColor;
  final IconData Function(String) getIcon;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onCopy;

  const _PasswordTile({
    required this.entry,
    required this.isSelected,
    required this.catColor,
    required this.getIcon,
    required this.onTap,
    required this.onDoubleTap,
    required this.onCopy,
  });

  @override
  State<_PasswordTile> createState() => _PasswordTileState();
}

class _PasswordTileState extends State<_PasswordTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() { _hovered = false; _pressed = false; }),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()..scale(_pressed ? 0.975 : 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.catColor.withOpacity(0.16)
                  : _hovered
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? widget.catColor.withOpacity(0.50)
                    : _hovered
                        ? Colors.white.withOpacity(0.18)
                        : Colors.white.withOpacity(0.07),
                width: widget.isSelected ? 1.5 : 1,
              ),
              boxShadow: widget.isSelected
                  ? [BoxShadow(color: widget.catColor.withOpacity(0.14), blurRadius: 14)]
                  : _hovered
                      ? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)]
                      : [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? widget.catColor.withOpacity(0.22)
                          : _hovered
                              ? Colors.white.withOpacity(0.10)
                              : Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.getIcon(widget.entry.category),
                      color: widget.isSelected ? widget.catColor : Colors.white54, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.entry.title,
                          style: TextStyle(
                            color: widget.isSelected ? Colors.white : Colors.white.withOpacity(0.88),
                            fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(widget.entry.username,
                          style: TextStyle(
                            color: widget.isSelected
                                ? Colors.white60
                                : _hovered
                                    ? Colors.white38
                                    : Colors.white24,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedOpacity(
                    opacity: _hovered || widget.isSelected ? 1.0 : 0.25,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TileAction(
                          icon: Icons.copy,
                          color: widget.catColor,
                          onTap: widget.onCopy,
                          tooltip: 'Copy Password',
                        ),
                        const SizedBox(width: 2),
                        _TileAction(
                          icon: Icons.open_in_full,
                          color: Colors.white54,
                          onTap: widget.onDoubleTap,
                          tooltip: 'Open Details',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TileAction extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _TileAction({required this.icon, required this.color, required this.onTap, required this.tooltip});

  @override
  State<_TileAction> createState() => _TileActionState();
}

class _TileActionState extends State<_TileAction> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _hover ? widget.color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon,
              color: _hover ? widget.color : Colors.white38, size: 16),
          ),
        ),
      ),
    );
  }
}
