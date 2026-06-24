// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../utils/storage_service.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';
import 'splash_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AuthProvider auth;
  final VoidCallback onDataChanged;
  final VoidCallback onProfileImageChanged;

  const ProfileScreen({
    super.key,
    required this.auth,
    required this.onDataChanged,
    required this.onProfileImageChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<FomoEvaluation> _evals = [];
  List<ShoppingLog> _logs = [];
  List<AppNotification> _notifs = [];
  bool _loading = true;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final imagePath = await StorageService.getProfileImage(widget.auth.user!.id);

      if (!mounted) return;

      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          setState(() {
            _profileImage = file;
          });
        } else {
          setState(() {
            _profileImage = null;
          });
        }
      } else {
        setState(() {
          _profileImage = null;
        });
      }
    } catch (e) {
      print('❌ Error loading profile image: $e');
    }
  }

  Future<void> _load() async {
    try {
      final uid = widget.auth.user!.id;
      final res = await Future.wait([
        StorageService.loadEvals(uid),
        StorageService.loadLogs(uid),
        StorageService.loadNotifications(uid),
      ]);

      if (mounted) {
        setState(() {
          _evals = res[0] as List<FomoEvaluation>;
          _logs = res[1] as List<ShoppingLog>;
          _notifs = res[2] as List<AppNotification>;
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<double> get _susHistory {
    final now = DateTime.now();
    return List.generate(4, (w) {
      final wLogs = _logs.where((l) {
        final d = now.difference(l.date).inDays;
        return d >= w * 7 && d < (w + 1) * 7;
      }).toList();
      if (wLogs.isEmpty) return 0.0;
      final avgPkg = wLogs.fold(0, (s, l) => s + l.packageCount) / wLogs.length;
      final onR = wLogs.where((l) => l.isOnline).length / wLogs.length;
      return (100 - avgPkg * 10 - onR * 20).clamp(0.0, 100.0);
    }).reversed.toList();
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(auth: widget.auth),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user!;
    final unread = _notifs.where((n) => !n.isRead).length;
    final notifEnabled = user.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppTheme.forest,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.cream),
          onPressed: _goToHome,
          tooltip: 'Kembali ke Beranda',
        ),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppTheme.cream,
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.cream),
                onPressed: () => _showNotifications(context),
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.terra,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$unread',
                      style: GoogleFonts.nunito(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.sage))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.sage,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarSection(user),
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 16),
                    _buildSustainabilityChart(),
                    const SizedBox(height: 16),
                    _buildSettingsSection(notifEnabled),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: EcoButton(
                        label: 'Keluar dari Akun',
                        outline: true,
                        color: AppTheme.terra,
                        icon: Icons.logout_rounded,
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ========== WIDGET BUILDERS ==========

  Widget _buildAvatarSection(AppUser user) {
    return EcoCard(
      child: Row(
        children: [
          GestureDetector(
            onTap: _isImageLoading ? null : () => _showChangePhotoDialog(context),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.forest,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forest.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: _profileImage != null
                    ? DecorationImage(
                        image: FileImage(_profileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: _isImageLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppTheme.cream,
                        strokeWidth: 2,
                      ),
                    )
                  : _profileImage == null
                      ? Text(
                          user.name[0].toUpperCase(),
                          style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.cream,
                          ),
                        )
                      : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppTheme.grey,
                  ),
                ),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone!,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                EcoChip(label: 'Sejak ${_fmtDate(user.createdAt)}'),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.sage),
            onPressed: () => _showEditProfile(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _miniStatCard(
          '${_evals.length}',
          'Evaluasi\nDilakukan',
          '🔍',
          AppTheme.sage,
        ),
        const SizedBox(width: 10),
        _miniStatCard(
          '${_evals.where((e) => e.decision == 'skip').length}',
          'Pembelian\nDicegah',
          '🚫',
          AppTheme.terra,
        ),
        const SizedBox(width: 10),
        _miniStatCard(
          '${_logs.length}',
          'Belanja\nDicatat',
          '📦',
          AppTheme.forestMid,
        ),
      ],
    );
  }

  Widget _buildSustainabilityChart() {
    return EcoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Riwayat Sustainability Score',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Skor mingguan 4 minggu terakhir',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _susHistory.asMap().entries.map((e) {
              final score = e.value;
              final label = ['W-3', 'W-2', 'W-1', 'Ini'][e.key];
              final color = AppTheme.susColor(score);
              final barH = score == 0 ? 4.0 : (score / 100) * 80;
              return Column(
                children: [
                  Text(
                    score == 0 ? '-' : score.toStringAsFixed(0),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 48,
                    height: barH,
                    decoration: BoxDecoration(
                      color: score == 0
                          ? AppTheme.divider
                          : color.withOpacity(0.25),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      border: score == 0
                          ? null
                          : Border.all(color: color, width: 1.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool notifEnabled) {
    return EcoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚙️ Pengaturan',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.forest,
            ),
          ),
          const SizedBox(height: 14),
          _settingRow(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
            subtitle: 'Pengingat cooling period & eco tips',
            trailing: Switch(
              value: notifEnabled,
              activeColor: AppTheme.sage,
              onChanged: (v) async {
                await widget.auth.updateProfile(
                  notificationsEnabled: v,
                );
                setState(() {});
              },
            ),
          ),
          const Divider(height: 20),
          _settingRow(
            icon: Icons.eco_outlined,
            title: 'SDG Focus',
            subtitle: 'SDG 12 — Responsible Consumption',
            trailing: const EcoChip(label: 'Aktif'),
          ),
          const Divider(height: 20),
          _settingRow(
            icon: Icons.info_outline,
            title: 'Versi Aplikasi',
            subtitle: 'EcoPause v1.0.0',
            trailing: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ========== HELPER WIDGETS ==========

  Widget _miniStatCard(String val, String label, String emoji, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              val,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: AppTheme.grey,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppTheme.sage, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.forest,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  // ========== ACTION METHODS ==========

  void _showChangePhotoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Foto Profil',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forest,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PhotoSourceButton(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _PhotoSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  if (_profileImage != null)
                    _PhotoSourceButton(
                      icon: Icons.delete,
                      label: 'Hapus',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _removeProfileImage();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isImageLoading = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);

        final savedPath = await StorageService.saveProfileImage(
          widget.auth.user!.id,
          file,
        );

        if (savedPath != null && mounted) {
          setState(() {
            _profileImage = File(savedPath);
            _isImageLoading = false;
          });

          widget.onProfileImageChanged();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Foto profil berhasil diupdate!'),
              backgroundColor: AppTheme.sage,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isImageLoading = false);
      }
    } catch (e) {
      setState(() => _isImageLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal mengupload foto: $e'),
            backgroundColor: AppTheme.terra,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() => _isImageLoading = true);

    try {
      await StorageService.removeProfileImage(widget.auth.user!.id);

      if (mounted) {
        setState(() {
          _profileImage = null;
          _isImageLoading = false;
        });

        widget.onProfileImageChanged();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Foto profil berhasil dihapus'),
            backgroundColor: AppTheme.terra,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isImageLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menghapus foto: $e'),
            backgroundColor: AppTheme.terra,
          ),
        );
      }
    }
  }

  void _showEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        auth: widget.auth,
        onUpdated: () {
          setState(() {});
          widget.onDataChanged();
          _loadProfileImage();
          _load();
        },
        onChangePhoto: () {
          _showChangePhotoDialog(context);
        },
      ),
    );
  }

  void _showNotifications(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '🔔 Notifikasi',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forest,
                      ),
                    ),
                  ),
                  if (_notifs.any((n) => !n.isRead))
                    GestureDetector(
                      onTap: () async {
                        for (final n in _notifs.where((n) => !n.isRead)) {
                          await StorageService.markNotifRead(n.id);
                        }
                        _load();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Tandai semua dibaca',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppTheme.sage,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _notifs.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada notifikasi',
                        style: GoogleFonts.nunito(color: AppTheme.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _notifs.length,
                      itemBuilder: (_, i) {
                        final n = _notifs[i];
                        return GestureDetector(
                          onTap: () async {
                            await StorageService.markNotifRead(n.id);
                            _load();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? AppTheme.white
                                  : AppTheme.sage.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: n.isRead
                                    ? AppTheme.divider
                                    : AppTheme.sage.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4, right: 10),
                                  decoration: BoxDecoration(
                                    color: n.isRead ? AppTheme.divider : AppTheme.sage,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.title,
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.forest,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        n.body,
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          color: AppTheme.ink,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _fmtDate(n.time),
                                        style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          color: AppTheme.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
    _load();
  }

  // ✅ LOGOUT KE SPLASH SCREEN + RESET ONBOARDING
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Keluar?',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppTheme.forest,
          ),
        ),
        content: Text(
          'Kamu akan keluar dari akun ini.',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppTheme.ink,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.nunito(color: AppTheme.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terra,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              // ✅ 1. LOGOUT
              await widget.auth.logout();

              // ✅ 2. RESET ONBOARDING
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('onboarding_done');

              // ✅ 3. KE SPLASH SCREEN
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Keluar',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppTheme.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== PHOTO SOURCE BUTTON ==========
class _PhotoSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? AppTheme.sage).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: color ?? AppTheme.sage,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Profile Sheet ────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final AuthProvider auth;
  final VoidCallback onUpdated;
  final VoidCallback onChangePhoto;

  const _EditProfileSheet({
    required this.auth,
    required this.onUpdated,
    required this.onChangePhoto,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _isLoading = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    final user = widget.auth.user;
    _nameCtrl.text = user?.name ?? '';
    _emailCtrl.text = user?.email ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _bioCtrl.text = user?.bio ?? '';
    _notificationsEnabled = user?.notificationsEnabled ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    _saveProfileAsync();
  }

  Future<void> _saveProfileAsync() async {
    try {
      await widget.auth.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        notificationsEnabled: _notificationsEnabled,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil berhasil diperbarui!'),
            backgroundColor: AppTheme.sage,
          ),
        );
        Navigator.pop(context);
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal memperbarui profil: $e'),
            backgroundColor: AppTheme.terra,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Profil',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forest,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.nunito(
                          color: AppTheme.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _nameCtrl,
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap',
                      icon: Icons.person_outline,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'Masukkan email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneCtrl,
                      label: 'Nomor Telepon',
                      hint: 'Masukkan nomor telepon',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _bioCtrl,
                      label: 'Bio / Deskripsi Diri',
                      hint: 'Ceritakan sedikit tentang dirimu...',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 20),
                    _buildNotificationSwitch(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                    _buildChangePasswordButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.forest,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.forest.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _nameCtrl.text.isEmpty
                  ? '?'
                  : _nameCtrl.text[0].toUpperCase(),
              style: GoogleFonts.nunito(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.cream,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), () {
                  widget.onChangePhoto();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.sage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.notifications_outlined,
            color: AppTheme.sage,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifikasi',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.forest,
                  ),
                ),
                Text(
                  'Terima pengingat dan tips eco',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppTheme.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            activeColor: AppTheme.sage,
            onChanged: _isLoading
                ? null
                : (v) => setState(() => _notificationsEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: EcoButton(
        label: _isLoading ? 'Menyimpan...' : '💾 Simpan Perubahan',
        onTap: _isLoading ? null : _saveProfile,
        color: AppTheme.sage,
        icon: _isLoading ? null : Icons.save_outlined,
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _isLoading
            ? null
            : () {
                Navigator.pop(context);
                _showChangePasswordDialog(context);
              },
        icon: const Icon(Icons.lock_outline, color: AppTheme.terra),
        label: Text(
          'Ubah Password',
          style: GoogleFonts.nunito(
            color: AppTheme.terra,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.forest),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.sage),
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
              fontSize: 14,
              color: AppTheme.grey.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.sage, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.divider.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '🔒 Ubah Password',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppTheme.forest,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField(
              controller: oldPassCtrl,
              label: 'Password Lama',
              hint: 'Masukkan password lama',
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: newPassCtrl,
              label: 'Password Baru',
              hint: 'Masukkan password baru (min 6 karakter)',
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: confirmPassCtrl,
              label: 'Konfirmasi Password',
              hint: 'Masukkan ulang password baru',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.nunito(color: AppTheme.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              _handlePasswordChange(
                context,
                oldPassCtrl.text,
                newPassCtrl.text,
                confirmPassCtrl.text,
              );
            },
            child: Text(
              'Ubah Password',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppTheme.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.forest),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.sage),
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
          fontSize: 14,
          color: AppTheme.grey.withOpacity(0.5),
        ),
        labelText: label,
        labelStyle: GoogleFonts.nunito(
          fontSize: 12,
          color: AppTheme.ink,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.sage, width: 2),
        ),
      ),
    );
  }

  void _handlePasswordChange(
    BuildContext context,
    String oldPass,
    String newPass,
    String confirmPass,
  ) {
    if (newPass.isEmpty || newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru minimal 6 karakter!')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok!')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ubah password akan segera hadir!'),
        backgroundColor: AppTheme.sage,
      ),
    );
    Navigator.pop(context);
  }
}