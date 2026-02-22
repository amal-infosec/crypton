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
import 'dart:ui';

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
    CategoryItem(name: 'Email', icon: Icons.email_outlined, color: const Color(0xFFEF5350)),
    CategoryItem(name: 'Finance', icon: Icons.account_balance_wallet_outlined, color: const Color(0xFF66BB6A)),
    CategoryItem(name: 'Wifi', icon: Icons.wifi, color: const Color(0xFFFFA726)),
    CategoryItem(name: 'Shopping', icon: Icons.shopping_cart, color: const Color(0xFFAB47BC)),
    CategoryItem(name: 'Developer', icon: Icons.code, color: Colors.tealAccent),
    CategoryItem(name: 'Forum', icon: Icons.forum_outlined, color: Colors.lightBlueAccent),
    CategoryItem(name: 'Software', icon: Icons.terminal, color: Colors.indigoAccent),
    CategoryItem(name: 'Streaming', icon: Icons.movie_filter_outlined, color: Colors.pinkAccent),
    CategoryItem(name: 'YouTube', icon: Icons.play_circle_outline, color: Colors.redAccent),
    CategoryItem(name: 'Cybersecurity', icon: Icons.security_rounded, color: Colors.lightGreenAccent),
    CategoryItem(name: 'Banking', icon: Icons.account_balance, color: Colors.amberAccent),
    CategoryItem(name: 'Other', icon: Icons.category_outlined, color: const Color(0xFFBDBDBD)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          // 1) Base Deep Atmospheric Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B0F14), Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // 2) Top-Right Radial Cold Blue Glow
          Positioned(
            top: -200,
            right: -200,
            child: Container(
              width: 800,
              height: 800,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.05),
                    const Color(0xFF3B82F6).withOpacity(0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // 3) Main UI Content
          Row(
            children: [
              _buildSidebar(context),
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final storage = context.watch<StorageService>();
    final allPasswords = storage.getPasswords();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06), // Premium 6% opacity
            border: Border(right: BorderSide(color: Colors.white.withOpacity(0.15), width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Custom Window Controls
          DragToMoveArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Row(
                children: [
                   _buildWindowControlButton(Icons.close, const Color(0xFFFF5F56), () => windowManager.close()),
                   const SizedBox(width: 8),
                   _buildWindowControlButton(Icons.remove, const Color(0xFFFFBD2E), () => windowManager.minimize()),
                   const SizedBox(width: 8),
                   _buildWindowControlButton(Icons.open_in_full, const Color(0xFF27C93F), () async {
                      if (await windowManager.isMaximized()) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                   }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Logo or Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 36, height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('CRYPTON', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarHeader('Vaults', Icons.add, onActionPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPasswordScreen()));
                }),
                _buildSidebarItem(
                  title: 'All vaults',
                  icon: Icons.all_inclusive,
                  count: allPasswords.length,
                  isSelected: _selectedSection == 'All Vaults',
                  onTap: () => setState(() => _selectedSection = 'All Vaults'),
                  isHighlighted: true,
                  highlightColor: const Color(0xFFB388FF),
                ),
                const SizedBox(height: 8),
                ..._vaultCategories.map((cat) {
                  final count = allPasswords.where((p) => p.category == cat.name).length;
                  return _buildSidebarItem(
                    title: cat.name,
                    icon: cat.icon,
                    count: count,
                    isSelected: _selectedSection == cat.name,
                    onTap: () => setState(() => _selectedSection = cat.name),
                  );
                }),
                
                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                
                _buildSidebarHeader('Notes', Icons.add, onActionPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditNoteScreen()));
                }),
                _buildSidebarItem(
                  title: 'Secure Notes',
                  icon: Icons.note,
                  isSelected: _selectedSection == 'Notes',
                  onTap: () => setState(() => _selectedSection = 'Notes'),
                  isHighlighted: true,
                  highlightColor: const Color(0xFF81D4FA),
                ),
                
                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),

                _buildSidebarItem(
                  title: 'Settings',
                  icon: Icons.settings,
                  isSelected: _selectedSection == 'Settings',
                  onTap: () => setState(() => _selectedSection = 'Settings'),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildSidebarHeader(String title, IconData actionIcon, {VoidCallback? onActionPressed}) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8, bottom: 8, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          if (onActionPressed != null)
             InkWell(
               onTap: onActionPressed,
               borderRadius: BorderRadius.circular(20),
               child: Padding(
                 padding: const EdgeInsets.all(4.0),
                 child: Icon(actionIcon, color: Colors.white54, size: 18),
               ),
             )
          else 
             Icon(actionIcon, color: Colors.white54, size: 18),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required String title,
    required IconData icon,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
    bool isHighlighted = false,
    Color highlightColor = const Color(0xFF3B82F6),
  }) {
    Color contentColor = Colors.white70;

    if (isSelected) {
      contentColor = Colors.white;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: isSelected
              ? LinearGradient(
                  colors: isHighlighted
                      ? [highlightColor.withOpacity(0.3), highlightColor.withOpacity(0.1)]
                      : [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.05)],
                )
              : null,
          boxShadow: (isSelected && isHighlighted)
              ? [BoxShadow(color: highlightColor.withOpacity(0.25), blurRadius: 16)]
              : null,
          border: isSelected
              ? Border.all(color: isHighlighted ? highlightColor.withOpacity(0.5) : Colors.white.withOpacity(0.15))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected && isHighlighted ? highlightColor : contentColor),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: contentColor, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
            if (count != null)
              Text(count.toString(), style: TextStyle(color: isSelected ? Colors.white70 : Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowControlButton(IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
          ),
          child: Center(child: Icon(icon, color: Colors.black54, size: 10)),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    Widget content;
    if (_selectedSection == 'All Vaults' || _vaultCategories.any((c) => c.name == _selectedSection)) {
       content = PasswordListTab(categoryFilter: _selectedSection);
    } else if (_selectedSection == 'Notes') {
       content = const NotesListTab();
    } else if (_selectedSection == 'Settings') {
       content = _buildSettingsDesktopView();
    } else {
       content = const Center(child: Text('Unknown section'));
    }

    return Column(
      children: [
        // Title Bar Drag Area (Right side)
        DragToMoveArea(
          child: Container(
            height: 48,
            color: Colors.transparent, // Allow drag on top
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
        // Tab Row — SINGLE source of truth for settings navigation
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              _buildTab('General',  _selectedSettingsTab == 'General'),
              const SizedBox(width: 24),
              _buildTab('Security', _selectedSettingsTab == 'Security'),
              const SizedBox(width: 24),
              _buildTab('Import',   _selectedSettingsTab == 'Import'),
              const SizedBox(width: 24),
              _buildTab('Export',   _selectedSettingsTab == 'Export'),
              const SizedBox(width: 24),
              _buildTab('About',    _selectedSettingsTab == 'About'),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: Container(
            color: Colors.transparent,
            child: _buildSettingsContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsContent() {
    final settingsWidget = SettingsTab(activeTab: _selectedSettingsTab);
    switch (_selectedSettingsTab) {
      case 'Import': return settingsWidget;
      case 'Export': return settingsWidget;
      case 'General': return settingsWidget;
      case 'Security': return settingsWidget;
      case 'About': return settingsWidget;
      default: return settingsWidget;
    }
  }

  Widget _buildImportGrid() {
    final List<Map<String, dynamic>> items = [
      {'name': '1Password', 'sub': '1pux, 1pif', 'color': const Color(0xFF0A55D1), 'initials': '1P'},
      {'name': 'Bitwarden', 'sub': 'json', 'color': const Color(0xFF175DDC), 'icon': Icons.security},
      {'name': 'Brave', 'sub': 'csv', 'color': const Color(0xFFFF4A00), 'icon': Icons.public},
      {'name': 'Chrome', 'sub': 'csv', 'color': const Color(0xFF4285F4), 'icon': Icons.public},
      {'name': 'Dashlane', 'sub': 'zip, csv', 'color': const Color(0xFF0F3542), 'initials': 'D'},
      {'name': 'Edge', 'sub': 'csv', 'color': const Color(0xFF0078D7), 'icon': Icons.public},
      {'name': 'Enpass', 'sub': 'json', 'color': const Color(0xFF0F9D58), 'icon': Icons.security},
      {'name': 'Firefox', 'sub': 'csv', 'color': const Color(0xFFFF7139), 'icon': Icons.public},
      {'name': 'Kaspersky', 'sub': 'txt', 'color': const Color(0xFF00A88E), 'icon': Icons.security},
      {'name': 'KeePass', 'sub': 'xml', 'color': const Color(0xFF1D5A79), 'icon': Icons.lock},
      {'name': 'Keeper', 'sub': 'csv', 'color': const Color(0xFFF1C40F), 'initials': 'K'},
      {'name': 'LastPass', 'sub': 'csv', 'color': const Color(0xFFD32D27), 'icon': Icons.more_horiz},
      {'name': 'NordPass', 'sub': 'csv', 'color': const Color(0xFF1B1B1B), 'icon': Icons.security},
      {'name': 'Proton Pass', 'sub': 'json', 'color': const Color(0xFFD1C4E9), 'icon': Icons.shield},
      {'name': 'Roboform', 'sub': 'csv', 'color': const Color(0xFF2E7D32), 'icon': Icons.assignment},
      {'name': 'Safari', 'sub': 'csv', 'color': const Color(0xFF1EA362), 'icon': Icons.explore},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select your password manager', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 1.3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                
                Widget badge;
                if (item['icon'] != null) {
                  badge = Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28);
                } else {
                  badge = Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item['initials'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                       await FilePicker.platform.pickFiles(
                         type: FileType.custom,
                         allowedExtensions: ['csv', 'json', 'txt', 'xml', 'zip', '1pux', '1pif'],
                       );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        badge,
                        const SizedBox(height: 12),
                        Text(item['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(item['sub'] as String, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected, {bool hasIcon = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedSettingsTab = title),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
             bottom: BorderSide(
               color: isSelected ? const Color(0xFFB388FF) : Colors.transparent, 
               width: 2
             )
          )
        ),
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            if (hasIcon) ...[
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 14, color: Colors.white54),
            ]
          ],
        ),
      ),
    );
  }
}
