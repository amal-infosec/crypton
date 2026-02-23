
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' show ImageFilter;

class LinuxImportFallback extends StatefulWidget {
  final List<String> extensions;
  final String title;

  const LinuxImportFallback({
    super.key,
    required this.extensions,
    this.title = '📂 Linux Import Fallback',
  });

  @override
  State<LinuxImportFallback> createState() => _LinuxImportFallbackState();
}

class _LinuxImportFallbackState extends State<LinuxImportFallback> {
  String? manualPath;
  List<File> downloadsFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final files = downloadsDir.listSync()
          .whereType<File>()
          .where((f) => widget.extensions.any((ext) => f.path.toLowerCase().endsWith(ext.toLowerCase())))
          .toList();
        
        // Sort by modification date (newest first)
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        
        if (mounted) {
          setState(() {
            downloadsFiles = files;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassDialog(
      title: widget.title,
      icon: Icons.folder_open,
      iconColor: Colors.tealAccent,
      children: [
        const Text(
          'System file picker failed. This usually happens if xdg-desktop-portal is missing or misconfigured.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
        else if (downloadsFiles.isNotEmpty) ...[
          const Text('Recent matching files in Downloads:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(4),
              itemCount: downloadsFiles.length > 5 ? 5 : downloadsFiles.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, i) {
                final file = downloadsFiles[i];
                final name = file.path.split('/').last;
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                  subtitle: Text(DateFormat('MMM dd, HH:mm').format(file.lastModifiedSync()), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                  onTap: () => Navigator.pop(context, file.path),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text('Or Enter Manual Absolute Path:', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          autofocus: downloadsFiles.isEmpty,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: '/home/user/Downloads/file.ext',
            hintStyle: const TextStyle(color: Colors.white24),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent)),
          ),
          onChanged: (v) => manualPath = v,
        ),
        const SizedBox(height: 8),
        const Text(
          '💡 Tip: Install xdg-desktop-portal-gtk or xdg-desktop-portal-kde to fix this permanently.',
          style: TextStyle(color: Colors.tealAccent, fontSize: 10),
        ),
      ],
      actions: [
        _dialogBtn(context, 'Cancel', () => Navigator.pop(context), outline: true),
        _dialogBtn(context, 'Import Path', () {
          if (manualPath != null && manualPath!.isNotEmpty) {
            if (File(manualPath!).existsSync()) {
              Navigator.pop(context, manualPath);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found at specified path')));
            }
          }
        }, color: Colors.tealAccent.withOpacity(0.3)),
      ],
    );
  }

  Widget _dialogBtn(BuildContext context, String label, VoidCallback onTap, {bool outline = false, Color? color}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: outline ? Colors.white70 : Colors.tealAccent,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: outline ? BorderSide(color: Colors.white.withOpacity(0.1)) : BorderSide.none,
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 440,
          decoration: BoxDecoration(
            color: const Color(0xFF111111).withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: iconColor ?? Colors.tealAccent, size: 24),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> showLinuxImportFallback(BuildContext context, List<String> extensions, {String title = '📂 Linux Import Fallback'}) {
  return showDialog<String>(
    context: context,
    builder: (context) => LinuxImportFallback(extensions: extensions, title: title),
  );
}
