
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/storage_service.dart';
import '../../core/auth_service.dart';
import '../../core/encryption_service.dart';
import '../../models/data_models.dart';
import 'media_auth_screen.dart';
import '../widgets/linux_import_fallback.dart';
import 'dart:ui' show ImageFilter;

class MediaVaultTab extends StatefulWidget {
  const MediaVaultTab({super.key});

  @override
  State<MediaVaultTab> createState() => _MediaVaultTabState();
}

class _MediaVaultTabState extends State<MediaVaultTab> {
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    // Lazy initialize MediaKit only when entering the media vault
    MediaKit.ensureInitialized();
  }

  Future<void> _importMedia() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
      );
    } catch (e) {
      if (!kIsWeb && Platform.isLinux) {
        final fallbackPath = await showLinuxImportFallback(
          context, 
          ['.jpg', '.jpeg', '.png', '.gif', '.mp4', '.mov', '.mkv'],
          title: '📂 Import Media',
        );
        if (fallbackPath != null) {
          result = FilePickerResult([
            PlatformFile(
              path: fallbackPath, 
              name: fallbackPath.split('/').last, 
              size: File(fallbackPath).lengthSync(),
            )
          ]);
        }
      } else {
        rethrow;
      }
    }

    if (result == null) return;

    setState(() => _isImporting = true);

    try {
      final storage = context.read<StorageService>();
      final auth = context.read<AuthService>();
      final encryption = EncryptionService(); // We don't need init for file methods
      final key = await auth.getMediaKey();
      
      final appDocDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory(p.join(appDocDir.path, '.vault'));
      if (!await vaultDir.exists()) await vaultDir.create(recursive: true);

      for (var file in result.files) {
        if (file.path == null) continue;
        
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(" ", "_")}';
        final destPath = p.join(vaultDir.path, fileName);
        
        // Encrypt and save
        await encryption.encryptFile(file.path!, destPath, key);

        // Save metadata
        final media = SecureMedia(
          title: file.name,
          fileName: fileName,
          mediaType: _getMediaType(file.extension),
          isStealth: storage.isStealthUnlocked,
        );
        
        await storage.saveMedia(media);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing media: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _showPINSetup() async {
    showDialog(
      context: context,
      builder: (_) => const MediaAuthScreen(isSettingUp: true),
    );
  }

  Future<void> _unlockVault() async {
    showDialog(
      context: context,
      builder: (_) => const MediaAuthScreen(),
    );
  }

  String _getMediaType(String? ext) {
    if (ext == null) return 'image';
    ext = ext.toLowerCase();
    if (['mp4', 'mkv', 'mov', 'avi'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'm4a', 'flac'].contains(ext)) return 'audio';
    return 'image';
  }

  void _lockVault() {
    context.read<StorageService>().setMediaUnlocked(false);
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final auth = context.watch<AuthService>();
    final mediaList = storage.getMedia();

    return FutureBuilder<bool>(
      future: auth.hasMediaPIN(),
      builder: (context, snapshot) {
        final hasPIN = snapshot.data ?? false;
        final isUnlocked = storage.isMediaUnlocked;

        if (hasPIN && !isUnlocked) {
          return _buildLockScreen();
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MEDIA VAULT',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: 2),
                        ),
                        if (storage.isStealthUnlocked)
                          const Text(
                            'Stealth Mode Active',
                            style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        _ActionButton(
                          icon: Icons.lock_open,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const StealthAuthScreen(),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        if (hasPIN)
                          _ActionButton(
                            icon: Icons.lock_outline,
                            onTap: _lockVault,
                          )
                        else
                          _ActionButton(
                            icon: Icons.security_outlined,
                            onTap: _showPINSetup,
                          ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          icon: Icons.add_photo_alternate_outlined,
                          onTap: _isImporting ? null : _importMedia,
                          isLoading: _isImporting,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: mediaList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text('No media in vault', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: mediaList.length,
                        itemBuilder: (context, index) {
                          return _MediaCard(media: mediaList[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.tealAccent.withOpacity(0.2)),
            ),
            child: const Icon(Icons.lock_person_outlined, size: 64, color: Colors.tealAccent),
          ),
          const SizedBox(height: 24),
          const Text(
            'Media Vault is Protected',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Authorization required to view private files',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _unlockVault,
            icon: const Icon(Icons.key_outlined),
            label: const Text('Unlock Vault', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent.withOpacity(0.2),
              foregroundColor: Colors.tealAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final SecureMedia media;
  const _MediaCard({required this.media});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.image_outlined;
    Color color = Colors.blueAccent;
    if (media.mediaType == 'video') {
      icon = Icons.play_circle_outline;
      color = Colors.redAccent;
    } else if (media.mediaType == 'audio') {
      icon = Icons.mic_none;
      color = Colors.orangeAccent;
    }

    return GestureDetector(
      onTap: () => _openViewer(context),
      onLongPress: () => _showDeleteDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Center(child: Icon(icon, size: 32, color: color.withOpacity(0.8))),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.black45,
                  child: Text(
                    media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ),
              if (media.isStealth == true)
                Positioned(
                  top: 8, right: 8,
                  child: Icon(Icons.security, size: 14, color: Colors.tealAccent.withOpacity(0.7)),
                ),
              Positioned(
                top: 4, left: 4,
                child: IconButton(
                  icon: Icon(Icons.delete_outline, size: 16, color: Colors.redAccent.withOpacity(0.5)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showDeleteDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Delete Media?', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently delete the file from your vault.', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<StorageService>().deleteMedia(media);
              Navigator.pop(ctx);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context) {
    if (media.mediaType == 'image') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ImagePlayerScreen(media: media)));
    } else if (media.mediaType == 'video') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(media: media)));
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;
  const _ActionButton({required this.icon, this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: isLoading
            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent)))
            : Icon(icon, color: Colors.tealAccent),
      ),
    );
  }
}

// ─────────────── Image Viewer ───────────────

class ImagePlayerScreen extends StatefulWidget {
  final SecureMedia media;
  const ImagePlayerScreen({super.key, required this.media});

  @override
  State<ImagePlayerScreen> createState() => _ImagePlayerScreenState();
}

class _ImagePlayerScreenState extends State<ImagePlayerScreen> {
  Uint8List? _imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthService>();
      final key = await auth.getMediaKey();
      final appDocDir = await getApplicationDocumentsDirectory();
      final filePath = p.join(appDocDir.path, '.vault', widget.media.fileName);
      
      final bytes = await EncryptionService().decryptFileToMemory(filePath, key);
      if (mounted) setState(() => _imageBytes = bytes);
    } catch (e) {
      debugPrint('Error decrypting image: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.tealAccent)
                : _imageBytes != null
                    ? InteractiveViewer(child: Image.memory(_imageBytes!))
                    : const Text('Failed to load image', style: TextStyle(color: Colors.white54)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Video Viewer ───────────────

class VideoPlayerScreen extends StatefulWidget {
  final SecureMedia media;
  const VideoPlayerScreen({super.key, required this.media});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  String? _tempPath;
  bool _isLoading = true;
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthService>();
      final key = await auth.getMediaKey();
      final appDocDir = await getApplicationDocumentsDirectory();
      final sourcePath = p.join(appDocDir.path, '.vault', widget.media.fileName);
      
      // Decrypt to temp disk cache for playback on Windows
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(p.join(tempDir.path, '.crypton_cache'));
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
      
      final tempFileName = 'temp_${DateTime.now().millisecondsSinceEpoch}_${widget.media.fileName}';
      _tempPath = p.join(cacheDir.path, tempFileName);

      setState(() => _loadingMessage = 'Decrypting file...');
      await EncryptionService().decryptFileToDiskIsolate(sourcePath, _tempPath!, key);
      
      if (mounted) setState(() => _loadingMessage = 'Preparing player...');
      await _player.open(Media(_tempPath!));
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error decrypting video: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    if (_tempPath != null) {
      File(_tempPath!).delete().catchError((e) => debugPrint('Error deleting temp video: $e'));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.tealAccent),
                      const SizedBox(height: 16),
                      Text(
                        _loadingMessage,
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  )
                : Video(controller: _controller),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
