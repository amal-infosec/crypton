import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/storage_service.dart';
import '../../models/ui_models.dart';
import 'home_screen.dart' show PasswordListTab, NotesListTab;
import 'settings_tab.dart';
import 'add_edit_password_screen.dart';
import 'add_edit_note_screen.dart';
import 'media_vault_tab.dart';
import 'stealth_auth_screen.dart';
import 'dart:ui';
import 'dart:io' show Platform;

class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  String _selectedSection = 'All Vaults';
  String _selectedSettingsTab = 'General';

  final List<CategoryItem> _vaultCategories = [
    CategoryItem(name: 'Personal', icon: Icons.person_pin_outlined, color: Colors.orangeAccent),
    CategoryItem(name: 'Work', icon: Icons.work_outline, color: const Color(0xFF5C6BC0)),
    CategoryItem(name: 'Social', icon: Icons.people_outline, color: const Color(0xFF42A5F5)),
    CategoryItem(name: 'Finance', icon: Icons.account_balance_wallet_outlined, color: const Color(0xFF66BB6A)),
    CategoryItem(name: 'Developer', icon: Icons.code, color: Colors.tealAccent),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF080808), Color(0xFF0F0F11)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -200, right: -200,
            child: Container(
              width: 800, height: 800,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFF7C3AED).withOpacity(0.03), Colors.transparent],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _buildSidebar(context),
              Expanded(child: _buildMainContent()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final storage = context.watch<StorageService>();
    final allPasswords = storage.getPasswords();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DragToMoveArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Row(
                children: [
                   GestureDetector(
                     onLongPress: () {
                        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const StealthAuthScreen());
                     },
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Container(
                           width: 24, height: 24,
                           decoration: BoxDecoration(
                             borderRadius: BorderRadius.circular(6),
                             boxShadow: [
                               BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 10),
                               BoxShadow(color: const Color(0xFF2DD4BF).withOpacity(0.2), blurRadius: 6),
                             ],
                           ),
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(6),
                             child: Image.asset('assets/icon/icon.png', width: 24, height: 24, fit: BoxFit.cover),
                           ),
                         ),
                         const SizedBox(width: 10),
                         const Text(
                           'CRYPTON', 
                           style: TextStyle(
                             fontWeight: FontWeight.w900, 
                             letterSpacing: 2, 
                             fontSize: 16, 
                             color: Colors.white,
                           )
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _sidebarSectionLabel('VAULT'),
                _sidebarItem('All Items', Icons.shield_outlined, Colors.tealAccent, count: allPasswords.length, isSelected: _selectedSection == 'All Vaults', onTap: () => setState(() => _selectedSection = 'All Vaults')),
                _sidebarItem('Categories', Icons.grid_view_rounded, Colors.blueAccent, isSelected: _selectedSection == 'Categories', onTap: () => setState(() => _selectedSection = 'All Vaults')),
                
                const SizedBox(height: 32),
                _sidebarSectionLabel('PRIVATE MEDIA'),
                _sidebarItem('Secure Media', Icons.play_circle_outline, Colors.orangeAccent, isSelected: _selectedSection == 'Media', onTap: () => setState(() => _selectedSection = 'Media')),
                
                const SizedBox(height: 32),
                _sidebarSectionLabel('ORGANIZATION'),
                _sidebarItem('Secure Notes', Icons.description_outlined, Colors.purpleAccent, isSelected: _selectedSection == 'Notes', onTap: () => setState(() => _selectedSection = 'Notes')),
              ],
            ),
          ),

          _sidebarItem('Settings', Icons.settings_outlined, Colors.white60, isSelected: _selectedSection == 'Settings', onTap: () => setState(() => _selectedSection = 'Settings')),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _sidebarItem(String title, IconData icon, Color accent, {int? count, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accent.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? accent.withOpacity(0.2) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? accent : Colors.white54),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
              if (count != null) Text(count.toString(), style: TextStyle(color: isSelected ? accent.withOpacity(0.7) : Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowControlButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildMainContent() {
    Widget content;
    if (_selectedSection == 'All Vaults') {
       content = const PasswordListTab(categoryFilter: 'All Vaults');
    } else if (_selectedSection == 'Media') {
       content = const MediaVaultTab();
    } else if (_selectedSection == 'Notes') {
       content = const NotesListTab();
    } else if (_selectedSection == 'Settings') {
       content = _buildSettingsDesktopView();
    } else {
       content = const Center(child: Text('Unknown section'));
    }

    return Column(
      children: [
        DragToMoveArea(
          child: Container(
            height: 48, 
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildWindowControlButton(Icons.remove, const Color(0xFFFFBD2E), () => windowManager.minimize()),
                const SizedBox(width: 8),
                _buildWindowControlButton(Icons.expand_less_rounded, const Color(0xFF27C93F), () async {
                   if (await windowManager.isMaximized()) windowManager.unmaximize();
                   else windowManager.maximize();
                }),
                const SizedBox(width: 8),
                _buildWindowControlButton(Icons.close, const Color(0xFFFF5F56), () => windowManager.close()),
              ],
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildSettingsDesktopView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(32, 24, 32, 8), child: Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            children: [
              _settingsTab('General'), const SizedBox(width: 24),
              _settingsTab('Security'), const SizedBox(width: 24),
              _settingsTab('Import'), const SizedBox(width: 24),
              _settingsTab('Export'), const SizedBox(width: 24),
              _settingsTab('About'),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(child: SettingsTab(activeTab: _selectedSettingsTab)),
      ],
    );
  }

  Widget _settingsTab(String label) {
    final bool isSelected = _selectedSettingsTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSettingsTab = label),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: isSelected ? Colors.tealAccent : Colors.white38, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          if (isSelected) Container(margin: const EdgeInsets.only(top: 8), width: 20, height: 2, color: Colors.tealAccent),
        ],
      ),
    );
  }
}
