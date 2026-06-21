// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../utils/storage_service.dart';
import '../widgets/common_widgets.dart';
import 'fomo_detector_screen.dart';
import 'wishlist_screen.dart';
import 'jejak_belanja_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthProvider auth;
  const HomeScreen({super.key, required this.auth});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  int _navIndex = 0;
  File? _profileImage;

  void _rebuild() => setState(() {});

  @override
  bool get wantKeepAlive => true;

  void _goToProfile() {
    setState(() {
      _navIndex = 5;
    });
  }

  Future<void> _loadProfileImage() async {
    try {
      final imagePath = await StorageService.getProfileImage(widget.auth.user!.id);
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          setState(() {
            _profileImage = file;
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

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final pages = [
      _DashboardPage(auth: widget.auth, onProfileTap: _goToProfile, profileImage: _profileImage),
      FomoDetectorScreen(auth: widget.auth),
      WishlistScreen(auth: widget.auth),
      JejakBelanjaScreen(auth: widget.auth),
      ReportScreen(auth: widget.auth),
      ProfileScreen(
        auth: widget.auth, 
        onDataChanged: () {
          _rebuild();
          _loadProfileImage();
        },
        onProfileImageChanged: _loadProfileImage,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _navIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: AppTheme.forest,
        unselectedItemColor: AppTheme.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'FOMO Check'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'JejakBeli'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

// ─── Dashboard Page ───────────────────────────────────────────────────────────
class _DashboardPage extends StatefulWidget {
  final AuthProvider auth;
  final VoidCallback onProfileTap;
  final File? profileImage;
  const _DashboardPage({required this.auth, required this.onProfileTap, this.profileImage});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> with AutomaticKeepAliveClientMixin {
  List<FomoEvaluation> _evals = [];
  List<WishlistItem> _wishlist = [];
  List<ShoppingLog> _logs = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  AuthProvider get _auth => widget.auth;

  Future<void> _load() async {
    final uid = _auth.user!.id;
    
    await Future.microtask(() async {
      final results = await Future.wait([
        StorageService.loadEvals(uid),
        StorageService.loadWishlist(uid),
        StorageService.loadLogs(uid),
        StorageService.checkWishlistUnlocks(uid),
      ]);
      
      if (!mounted) return;
      
      setState(() {
        _evals = results[0] as List<FomoEvaluation>;
        _wishlist = results[1] as List<WishlistItem>;
        _logs = results[2] as List<ShoppingLog>;
        _loading = false;
      });
    });
  }

  int get _skippedCount => _evals.where((e) => e.decision == 'skip').length;
  double get _totalSpent => _evals.fold(0.0, (s, e) => s + e.price);
  int get _wishlistPending => _wishlist.where((w) => w.isPending).length;
  int get _unlockedCount => _wishlist.where((w) => w.isPending && w.isUnlocked).length;
  double get _totalWaste => _logs.fold(0.0, (s, l) => s + l.wasteKg);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final user = _auth.user!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Selamat Pagi' : hour < 18 ? 'Selamat Siang' : 'Selamat Malam';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.sage,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Header dengan gradient
            SliverAppBar(
              expandedHeight: 115,
              pinned: true,
              backgroundColor: AppTheme.forest,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.forest,
                        AppTheme.forestMid,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$greeting,',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppTheme.mint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              user.name,
                              style: GoogleFonts.nunito(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.cream,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '🌿 Belanja bijak',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: AppTheme.cream.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Avatar yang bisa diklik ke Profile dengan foto profil
                      GestureDetector(
                        onTap: widget.onProfileTap,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.cream.withOpacity(0.25),
                                AppTheme.cream.withOpacity(0.08),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.cream.withOpacity(0.25),
                              width: 2,
                            ),
                            image: widget.profileImage != null
                                ? DecorationImage(
                                    image: FileImage(widget.profileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: widget.profileImage == null
                              ? Center(
                                  child: Text(
                                    user.name[0].toUpperCase(),
                                    style: GoogleFonts.nunito(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.cream,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
                      
            // CONTENT
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.sage),
                        ),
                      )
                    else ...[
                      _buildSDGBadge(),
                      const SizedBox(height: 16),

                      if (_unlockedCount > 0) ...[
                        _buildUnlockAlert(),
                        const SizedBox(height: 16),
                      ],

                      _buildStatsRow(),
                      const SizedBox(height: 20),

                      _buildSectionHeader('Aktivitas Cepat', showSeeAll: false),
                      const SizedBox(height: 12),
                      
                      _buildQuickAction(
                        emoji: '🔍',
                        title: 'Cek Sebelum Beli',
                        subtitle: 'Evaluasi pembelian dengan FOMO Detector',
                        color: AppTheme.sage,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FomoDetectorScreen(auth: _auth),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildQuickAction(
                        emoji: '⏳',
                        title: 'Smart Wishlist',
                        subtitle: '$_wishlistPending item — $_unlockedCount siap',
                        color: AppTheme.sand,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WishlistScreen(auth: _auth),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildQuickAction(
                        emoji: '📦',
                        title: 'Jejak Belanja',
                        subtitle: 'Rekam dampak kemasan belanjaanmu',
                        color: AppTheme.forestMid,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JejakBelanjaScreen(auth: _auth),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_evals.isNotEmpty) ...[
                        _buildSectionHeader('Evaluasi Terakhir', showSeeAll: true),
                        const SizedBox(height: 12),
                        ..._evals.reversed.take(3).map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RecentEvalTile(eval: e),
                          ),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ],
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WIDGET BUILDERS ==========

  Widget _buildSDGBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.sage.withOpacity(0.15),
            AppTheme.sage.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.sage.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.sage,
                  AppTheme.forestMid,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SDG 12',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Responsible Consumption & Production',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.forest,
              ),
            ),
          ),
          const Icon(
            Icons.eco_rounded,
            color: AppTheme.sage,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.sage.withOpacity(0.15),
            AppTheme.sage.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.sage.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.sage,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '🎯',
              style: TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_unlockedCount Item Siap Diputuskan!',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestMid,
                  ),
                ),
                Text(
                  'Cooling period selesai. Beli atau lewati?',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppTheme.ink.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.sage.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.sage,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(
          emoji: '🚫',
          label: 'Pembelian\nDicegah',
          value: '$_skippedCount',
          color: AppTheme.terra,
        ),
        const SizedBox(width: 10),
        _StatCard(
          emoji: '💰',
          label: 'Total\nPengeluaran',
          value: 'Rp ${_fmtP(_totalSpent)}',
          color: AppTheme.forestMid,
        ),
        const SizedBox(width: 10),
        _StatCard(
          emoji: '🌱',
          label: 'Sampah\nDicegah',
          value: '${_totalWaste.toStringAsFixed(1)} kg',
          color: AppTheme.sage,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {bool showSeeAll = false}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.sage,
                AppTheme.forestMid,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.forest,
          ),
        ),
        if (showSeeAll) ...[
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportScreen(auth: _auth),
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  'Lihat Semua',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grey,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickAction({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.sage.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forest,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtP(double p) {
    if (p >= 1e6) return '${(p / 1e6).toStringAsFixed(1)} jt';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)} rb';
    return p.toStringAsFixed(0);
  }
}

// ========== STAT CARD ==========
class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: AppTheme.ink.withOpacity(0.6),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== RECENT EVALUATION TILE ==========
class _RecentEvalTile extends StatelessWidget {
  final FomoEvaluation eval;

  const _RecentEvalTile({required this.eval});

  Color get _c => eval.decision == 'buy'
      ? AppTheme.forestMid
      : eval.decision == 'skip'
          ? AppTheme.terra
          : AppTheme.sand;

  Color get _bgColor => eval.decision == 'buy'
      ? AppTheme.forestMid.withOpacity(0.08)
      : eval.decision == 'skip'
          ? AppTheme.terra.withOpacity(0.08)
          : AppTheme.sand.withOpacity(0.08);

  String get _lbl => eval.decision == 'buy'
      ? '✅ Dibeli'
      : eval.decision == 'skip'
          ? '🚫 Dilewati'
          : '⏳ Wishlist';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _c.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sage.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eval.itemName,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.forest,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 12,
                      color: AppTheme.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      eval.category,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: AppTheme.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.attach_money_rounded,
                      size: 12,
                      color: AppTheme.grey,
                    ),
                    Text(
                      'Rp ${eval.price.toStringAsFixed(0)}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _c.withOpacity(0.2), width: 1),
            ),
            child: Text(
              _lbl,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _c,
              ),
            ),
          ),
        ],
      ),
    );
  }
}