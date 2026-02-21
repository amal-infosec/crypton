import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../core/storage_service.dart';
import '../../core/encryption_service.dart'; 
import '../../models/ui_models.dart';
import 'add_edit_password_screen.dart';
import 'add_edit_note_screen.dart';
import 'category_detail_screen.dart';
import 'note_category_detail_screen.dart';
import 'settings_tab.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';

import 'desktop_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      return const DesktopHomeScreen();
    }
    return const MobileHomeScreen();
  }
}

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PasswordListTab(),
    const NotesListTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final isFake = storage.isFakeMode;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      extendBody: true,
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
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: isFake ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.05),
        indicatorColor: isFake ? Colors.red.shade700 : Colors.tealAccent.withOpacity(0.5),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.password), label: 'Vault'),
          NavigationDestination(icon: Icon(Icons.note), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                if (_currentIndex == 0) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPasswordScreen()));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditNoteScreen()));
                }
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Icon(_currentIndex == 0 ? Icons.add : Icons.note_add),
            )
          : null,
    );
  }
}

class PasswordListTab extends StatefulWidget {
  final String? categoryFilter;
  const PasswordListTab({super.key, this.categoryFilter});

  @override
  State<PasswordListTab> createState() => _PasswordListTabState();
}

class _PasswordListTabState extends State<PasswordListTab> {
  String _searchQuery = '';
  
  final List<CategoryItem> _categoryData = [
    CategoryItem(name: 'All', icon: Icons.all_inclusive, color: Colors.white),
    CategoryItem(name: 'Social', icon: Icons.people_outline, color: Color(0xFF42A5F5)),
    CategoryItem(name: 'Email', icon: Icons.email_outlined, color: Color(0xFFEF5350)),
    CategoryItem(name: 'Finance', icon: Icons.account_balance_wallet_outlined, color: Color(0xFF66BB6A)),
    CategoryItem(name: 'Work', icon: Icons.work_outline, color: Color(0xFF8D6E63)),
    CategoryItem(name: 'Wifi', icon: Icons.wifi, color: Color(0xFFFFA726)),
    CategoryItem(name: 'Shopping', icon: Icons.shopping_cart, color: Color(0xFFAB47BC)),
    CategoryItem(name: 'Other', icon: Icons.category_outlined, color: Color(0xFFBDBDBD)),
  ];

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final allPasswords = storage.getPasswords();
    
    final isSearching = _searchQuery.isNotEmpty;
    
    // Apply optional category filter before search
    final filteredByCategory = widget.categoryFilter != null && widget.categoryFilter != 'All Vaults'
        ? allPasswords.where((p) => p.category == widget.categoryFilter).toList()
        : allPasswords;

    final searchResults = isSearching 
        ? filteredByCategory.where((e) => 
            e.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
            e.username.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList()
        : filteredByCategory;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Drag Header
          DragToMoveArea(
            child: Container(
              height: 48,
              color: Colors.transparent, 
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.categoryFilter ?? 'CRYPTON', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)
                            ),
                            _LiquidGlassButton(
                              label: 'Add Password',
                              icon: Icons.add,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPasswordScreen())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Dark Search Bar
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search vault...',
                            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                            fillColor: Colors.white.withOpacity(0.05),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.tealAccent.withOpacity(0.5))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ],
                    ),
                  ),
                ),
          
          if (isSearching || (widget.categoryFilter != null && widget.categoryFilter != 'All Vaults'))
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                     final entry = searchResults[index];
                     return _buildDesktopPasswordCard(context, entry);
                  },
                  childCount: searchResults.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = _categoryData[index];
                    final name = cat.name;
                    final count = name == 'All' 
                        ? allPasswords.length 
                        : allPasswords.where((p) => p.category == name).length;

                    return _buildDesktopCategoryCard(context, cat, count, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: name)));
                    });
                  },
                  childCount: _categoryData.length,
                ),
              ),
            ),
             const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
        ],
      ),
    );
  }
  
  Widget _buildDesktopPasswordCard(BuildContext context, dynamic entry) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditPasswordScreen(entry: entry))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  entry.title, 
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.username, 
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildPasswordTile(BuildContext context, dynamic entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(entry.username),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditPasswordScreen(entry: entry))),
          ),
        ),
      );
  }
}

class NotesListTab extends StatefulWidget {
  const NotesListTab({super.key});

  @override
  State<NotesListTab> createState() => _NotesListTabState();
}

class _NotesListTabState extends State<NotesListTab> {
  String _searchQuery = '';
  
  final List<CategoryItem> _noteCategories = [
    CategoryItem(name: 'All', icon: Icons.description, color: Colors.white),
    CategoryItem(name: 'Personal', icon: Icons.person_outline, color: Color(0xFFEC407A)),
    CategoryItem(name: 'Work', icon: Icons.work_outline, color: Color(0xFF5C6BC0)),
    CategoryItem(name: 'Ideas', icon: Icons.lightbulb_outline, color: Color(0xFFFFCA28)),
    CategoryItem(name: 'Secret', icon: Icons.security, color: Color(0xFF78909C)),
  ];

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final notes = storage.getNotes();

    final isSearching = _searchQuery.isNotEmpty;
    final searchResults = isSearching 
        ? notes.where((e) => e.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList()
        : [];

    return Scaffold(
       backgroundColor: Colors.transparent,
       body: Column(
         children: [
          // Drag Header
          DragToMoveArea(
            child: Container(
              height: 48,
              color: Colors.transparent,
            ),
          ),
          Expanded(
            child: CustomScrollView(
             slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'NOTES', 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)
                            ),
                            _LiquidGlassButton(
                              label: 'Add Note',
                              icon: Icons.add,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditNoteScreen())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search notes...',
                            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                            fillColor: Colors.white.withOpacity(0.05),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.tealAccent.withOpacity(0.5))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ],
                    ),
                  ),
                ),
          
          if (isSearching)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                   final note = searchResults[index];
                   return _buildNoteTile(context, note);
                },
                childCount: searchResults.length,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = _noteCategories[index];
                    final name = cat.name;
                    final count = name == 'All' 
                        ? notes.length 
                        : notes.where((n) => n.category == name).length;

                    return _buildDesktopCategoryCard(context, cat, count, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => NoteCategoryDetailScreen(category: name)));
                    });
                  },
                  childCount: _noteCategories.length,
                ),
              ),
            ),
             const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildNoteTile(BuildContext context, dynamic note) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
           contentPadding: const EdgeInsets.all(16),
           title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
           subtitle: Text(note.category),
           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note))),
        ),
      );
  }
}

Widget _buildCategoryCard(BuildContext context, CategoryItem cat, int count, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Theme.of(context).cardTheme.color,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (cat.color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(cat.icon, size: 32, color: cat.color),
            ),
            const SizedBox(height: 12),
            Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('$count items', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
}

Widget _buildDesktopCategoryCard(BuildContext context, CategoryItem cat, int count, VoidCallback onTap) {
    return _SmoothCategoryCard(cat: cat, count: count, onTap: onTap);
}


class _SmoothCategoryCard extends StatefulWidget {
  final CategoryItem cat;
  final int count;
  final VoidCallback onTap;
  const _SmoothCategoryCard({required this.cat, required this.count, required this.onTap});

  @override
  State<_SmoothCategoryCard> createState() => _SmoothCategoryCardState();
}

class _SmoothCategoryCardState extends State<_SmoothCategoryCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.cat.color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() { _hovered = false; _pressed = false; }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(_pressed ? 0.96 : 1.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06), // Premium 6% white op
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.15), // Premium 15% white op border
              width: 1,
            ),
            boxShadow: [
              // Outer drop shadow for elevation
              if (_hovered)
                BoxShadow(color: color.withOpacity(0.25), blurRadius: 20, spreadRadius: 0, offset: const Offset(0, 4))
              else
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 2)),
              // Inner top edge highlight for realism
              BoxShadow(color: Colors.white.withOpacity(0.1), offset: const Offset(0, 1.5), blurRadius: 0, spreadRadius: 0),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: _hovered ? color.withOpacity(0.18) : Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _hovered ? color.withOpacity(0.4) : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Icon(widget.cat.icon, size: 26, color: _hovered ? color : color.withOpacity(0.7)),
              ),
              const SizedBox(height: 14),
              Text(widget.cat.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: _hovered ? Colors.white : Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: _hovered ? color.withOpacity(0.8) : Colors.white38,
                  fontSize: 12,
                  fontWeight: _hovered ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text('${widget.count} items'),
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

// ─────────────── Premium Liquid Glass Button ───────────────

class _LiquidGlassButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _LiquidGlassButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<_LiquidGlassButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          // Hover lift
          transform: _hovered ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.0,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 4))]
                : [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
