// lib/screens/home_screen.dart
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

  void _rebuild() => setState(() {});

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final pages = [
      _DashboardPage(auth: widget.auth),
      FomoDetectorScreen(auth: widget.auth),
      WishlistScreen(auth: widget.auth),
      JejakBelanjaScreen(auth: widget.auth),
      ReportScreen(auth: widget.auth),
      ProfileScreen(auth: widget.auth, onDataChanged: _rebuild),
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
  const _DashboardPage({required this.auth});
  @override State<_DashboardPage> createState() => _DashboardPageState();
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

  Future<void> _load() async {
    final uid = widget.auth.user!.id;
    
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
  double get _savedMoney => _evals.where((e) => e.decision == 'skip').fold(0.0, (s, e) => s + e.price);
  int get _wishlistPending => _wishlist.where((w) => w.isPending).length;
  int get _unlockedCount => _wishlist.where((w) => w.isPending && w.isUnlocked).length;
  double get _totalWaste => _logs.fold(0.0, (s, l) => s + l.wasteKg);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final user = widget.auth.user!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Selamat Pagi' : hour < 18 ? 'Selamat Siang' : 'Selamat Malam';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.sage,
        child: CustomScrollView(
          slivers: [
            // Header dengan gradient
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: AppTheme.forest,
              flexibleSpace: FlexibleSpaceBar(
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
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$greeting,',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppTheme.mint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.name,
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.cream,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cream.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '🌿 Yuk, belanja lebih bijak',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      color: AppTheme.cream.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.cream.withOpacity(0.3),
                                  AppTheme.cream.withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.cream.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                user.name[0].toUpperCase(),
                                style: GoogleFonts.nunito(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.cream,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
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
                      // SDG Badge dengan desain lebih baik
                      RepaintBoundary(
                        child: Container(
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
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Unlock alert dengan desain lebih menarik
                      if (_unlockedCount > 0) ...[
                        RepaintBoundary(
                          child: Container(
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
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Stats row dengan desain card
                      RepaintBoundary(
                        child: Row(
                          children: [
                            _StatCard(
                              emoji: '🚫',
                              label: 'Pembelian\nDicegah',
                              value: '$_skippedCount',
                              color: AppTheme.terra,
                              icon: Icons.block_rounded,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              emoji: '💰',
                              label: 'Uang\nTerhemat',
                              value: 'Rp ${_fmtP(_savedMoney)}',
                              color: AppTheme.forestMid,
                              icon: Icons.savings_rounded,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              emoji: '🌱',
                              label: 'Sampah\nDicegah',
                              value: '${_totalWaste.toStringAsFixed(1)} kg',
                              color: AppTheme.sage,
                              icon: Icons.recycling_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section Header dengan desain lebih baik
                      Row(
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
                            'Aktivitas Cepat',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forest,
                            ),
                          ),
                          const Spacer(),
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
                      const SizedBox(height: 12),
                      
                      // Quick actions dengan desain card
                      RepaintBoundary(
                        child: _QuickAction(
                          emoji: '🔍',
                          title: 'Cek Sebelum Beli',
                          subtitle: 'Evaluasi pembelian dengan FOMO Detector',
                          color: AppTheme.sage,
                          icon: Icons.psychology_rounded,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FomoDetectorScreen(auth: widget.auth),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      RepaintBoundary(
                        child: _QuickAction(
                          emoji: '⏳',
                          title: 'Smart Wishlist',
                          subtitle: '$_wishlistPending item — $_unlockedCount siap',
                          color: AppTheme.sand,
                          icon: Icons.bookmark_rounded,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WishlistScreen(auth: widget.auth),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      RepaintBoundary(
                        child: _QuickAction(
                          emoji: '📦',
                          title: 'Jejak Belanja',
                          subtitle: 'Rekam dampak kemasan belanjaanmu',
                          color: AppTheme.forestMid,
                          icon: Icons.inventory_2_rounded,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JejakBelanjaScreen(auth: widget.auth),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_evals.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppTheme.forestMid,
                                    AppTheme.sage,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Evaluasi Terakhir',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.forest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._evals.reversed.take(3).map(
                          (e) => RepaintBoundary(
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

  String _fmtP(double p) {
    if (p >= 1e6) return '${(p / 1e6).toStringAsFixed(1)} jt';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)} rb';
    return p.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
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

class _QuickAction extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

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
      margin: const EdgeInsets.only(bottom: 10),
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