import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../core/storage_service.dart';
import 'add_edit_note_screen.dart';

class NoteCategoryDetailScreen extends StatefulWidget {
  final String category;
  const NoteCategoryDetailScreen({super.key, required this.category});

  @override
  State<NoteCategoryDetailScreen> createState() => _NoteCategoryDetailScreenState();
}

class _NoteCategoryDetailScreenState extends State<NoteCategoryDetailScreen> {

  IconData _getIconForCategory(String c) {
    switch (c) {
      case 'Personal': return Icons.person_pin_outlined; // Match updated icon
      case 'Work': return Icons.work_outline;
      case 'Ideas': return Icons.lightbulb_outline;
      case 'Secret': return Icons.security;
      case 'All': return Icons.description;
      case 'Developer': return Icons.code;
      case 'Forum': return Icons.forum_outlined;
      case 'Software': return Icons.terminal;
      case 'Streaming': return Icons.movie_filter_outlined;
      case 'YouTube': return Icons.play_circle_outline;
      case 'Cybersecurity': return Icons.security_rounded;
      case 'Banking': return Icons.account_balance;
      default: return Icons.note_outlined;
    }
  }

  Color _getColorForCategory(String c) {
    switch (c) {
      case 'Personal': return Colors.orangeAccent;
      case 'Work': return const Color(0xFF5C6BC0);
      case 'Ideas': return const Color(0xFFFFCA28);
      case 'Secret': return const Color(0xFF78909C);
      case 'All': return const Color(0xFF81D4FA);
      case 'Developer': return Colors.tealAccent;
      case 'Forum': return Colors.lightBlueAccent;
      case 'Software': return Colors.indigoAccent;
      case 'Streaming': return Colors.pinkAccent;
      case 'YouTube': return Colors.redAccent;
      case 'Cybersecurity': return Colors.lightGreenAccent;
      case 'Banking': return Colors.amberAccent;
      default: return Colors.tealAccent;
    }
  }

  void _showNotePopup(BuildContext context, dynamic note, Color catColor) {
    final icon = _getIconForCategory(note.category);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.50),
      transitionDuration: const Duration(milliseconds: 420),
      transitionBuilder: (ctx, anim, secondAnim, child) {
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
      pageBuilder: (ctx, anim, secondAnim) {
        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 420,
                  constraints: const BoxConstraints(maxHeight: 520),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B3A).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: catColor.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: catColor.withOpacity(0.15), blurRadius: 40, spreadRadius: 0),
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: catColor.withOpacity(0.4)),
                              ),
                              child: Icon(icon, color: catColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, decoration: TextDecoration.none),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Text(note.category,
                                      style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.06), shape: const CircleBorder()),
                            ),
                          ],
                        ),
                      ),
                      // Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: const Text(
                              'Note content is encrypted.\nTap "Open & Edit" below to view and modify the full note.',
                              style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.7, decoration: TextDecoration.none),
                            ),
                          ),
                        ),
                      ),
                      // Actions
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white60,
                                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Close'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note)));
                                },
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Open & Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: catColor.withOpacity(0.35),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
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
          Expanded(child: Text(text, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11, height: 1.5))),
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
    final all = storage.getNotes();
    final list = widget.category == 'All' ? all : all.where((n) => n.category == widget.category).toList();
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
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditNoteScreen())),
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
                        ? Center(child: Text('No notes in ${widget.category}', style: const TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              return _NoteTile(
                                note: list[index],
                                catColor: catColor,
                                getIcon: _getIconForCategory,
                                onTap: () => _showNotePopup(context, list[index], catColor),
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
                                color: catColor.withOpacity(0.15), shape: BoxShape.circle,
                                border: Border.all(color: catColor.withOpacity(0.4), width: 1.5),
                                boxShadow: [BoxShadow(color: catColor.withOpacity(0.3), blurRadius: 20)],
                              ),
                              child: Icon(catIcon, color: catColor, size: 30),
                            ),
                            const SizedBox(height: 16),
                            Text(widget.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                              child: Text('${list.length} ${list.length == 1 ? 'note' : 'notes'}',
                                style: TextStyle(color: catColor, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 12),
                            Align(alignment: Alignment.centerLeft,
                              child: Text('NOTES', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5))),
                            const SizedBox(height: 8),
                            _infoRow(Icons.lock_outline, 'Private & Secure'),
                            const SizedBox(height: 8),
                            _infoRow(Icons.touch_app_outlined, 'Click to open note'),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditNoteScreen())),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('New Note', style: TextStyle(fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: catColor.withOpacity(0.3), foregroundColor: Colors.white, elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const Spacer(),
                            _buildDecoBottomTip('Notes are encrypted\non your device', Icons.phone_android, catColor),
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
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(catIcon, size: 48, color: catColor.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text('No ${widget.category} notes', style: const TextStyle(color: Colors.white54, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  const Text('Tap "New Note" to get started', style: TextStyle(color: Colors.white30, fontSize: 13)),
                                ]),
                              ))
                          : ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final note = list[index];
                                  return _NoteTile(
                                    note: note,
                                    catColor: catColor,
                                    getIcon: _getIconForCategory,
                                    onTap: () => _showNotePopup(context, note, catColor),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [catColor.withOpacity(0.7), Colors.purple.withOpacity(0.4)],
                              ).createShader(bounds),
                              child: Icon(Icons.touch_app_outlined, size: 48, color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            const Text('Click any note', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            const Text('A preview will open\nas a smooth popup',
                              style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5), textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 16),
                            _buildInfoTip(Icons.lock_outline, 'Encrypted content', catColor),
                            const SizedBox(height: 10),
                            _buildInfoTip(Icons.edit_note, 'Edit inside popup', catColor),
                            const SizedBox(height: 10),
                            _buildInfoTip(Icons.add_circle_outline, 'Add via left panel', catColor),
                            const Spacer(),
                            _buildDecoBottomTip('Secure & private\nnotes vault', Icons.note_alt_outlined, catColor),
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
}

class _NoteTile extends StatefulWidget {
  final dynamic note;
  final Color catColor;
  final IconData Function(String) getIcon;
  final VoidCallback onTap;

  const _NoteTile({required this.note, required this.catColor, required this.getIcon, required this.onTap});

  @override
  State<_NoteTile> createState() => _NoteTileState();
}

class _NoteTileState extends State<_NoteTile> {
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
          onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? widget.catColor.withOpacity(0.12) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered ? widget.catColor.withOpacity(0.4) : Colors.white.withOpacity(0.08),
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered ? [BoxShadow(color: widget.catColor.withOpacity(0.12), blurRadius: 12)] : [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _hovered ? widget.catColor.withOpacity(0.2) : Colors.white.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.getIcon(widget.note.category),
                      color: _hovered ? widget.catColor : Colors.white54, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.note.title,
                          style: TextStyle(
                            color: _hovered ? Colors.white : Colors.white.withOpacity(0.88),
                            fontWeight: _hovered ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(widget.note.category,
                          style: TextStyle(
                            color: _hovered ? widget.catColor.withOpacity(0.8) : Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.open_in_new_rounded,
                      color: _hovered ? widget.catColor : Colors.white54, size: 18),
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
