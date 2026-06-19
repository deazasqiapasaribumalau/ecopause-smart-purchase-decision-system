// lib/screens/report_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../utils/storage_service.dart';
import '../widgets/common_widgets.dart';

class ReportScreen extends StatefulWidget {
  final AuthProvider auth;
  const ReportScreen({super.key, required this.auth});
  @override State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<FomoEvaluation> _evals = [];
  List<WishlistItem>   _wishlist = [];
  List<ShoppingLog>    _logs = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = widget.auth.user!.id;
    final res = await Future.wait([StorageService.loadEvals(uid), StorageService.loadWishlist(uid), StorageService.loadLogs(uid)]);
    if (mounted) setState(() { _evals = res[0] as List<FomoEvaluation>; _wishlist = res[1] as List<WishlistItem>; _logs = res[2] as List<ShoppingLog>; _loading = false; });
  }

  List<FomoEvaluation> get _thisMonth {
    final now = DateTime.now();
    return _evals.where((e) => e.date.month == now.month && e.date.year == now.year).toList();
  }

  int    get _skippedCount  => _thisMonth.where((e) => e.decision == 'skip').length;
  double get _savedMoney    => _thisMonth.where((e) => e.decision == 'skip').fold(0.0, (s, e) => s + e.price);
  double get _totalWaste    => _logs.fold(0.0, (s, l) => s + l.wasteKg);
  double get _totalCO2      => _logs.fold(0.0, (s, l) => s + l.co2Emission);
  int    get _wishlistSkips => _wishlist.where((w) => w.isSkipped).length;
  int    get _wishlistBought=> _wishlist.where((w) => w.isBought).length;

  Map<String, int> get _catCount {
    final m = <String, int>{};
    for (final e in _evals) m[e.category] = (m[e.category] ?? 0) + 1;
    return m;
  }

  String _fmtP(double p) { if (p >= 1e6) return '${(p/1e6).toStringAsFixed(1)} jt'; if (p >= 1000) return '${(p/1000).toStringAsFixed(0)} rb'; return p.toStringAsFixed(0); }

  @override
  Widget build(BuildContext context) {
    final months = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('📊 Laporan Bulanan'), backgroundColor: AppTheme.forest, automaticallyImplyLeading: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.sage))
          : RefreshIndicator(onRefresh: _load, color: AppTheme.sage,
              child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${months[now.month]} ${now.year}', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.forest))),
                  EcoChip(label: '${_thisMonth.length} evaluasi'),
                ]),
                const SizedBox(height: 16),

                // KPI Grid
                GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [
                  _KPICard('🚫', 'Pembelian\nDicegah', '$_skippedCount item', AppTheme.terra),
                  _KPICard('💰', 'Uang\nTerhemat', 'Rp ${_fmtP(_savedMoney)}', AppTheme.forestMid),
                  _KPICard('🗑️', 'Total Sampah', '${_totalWaste.toStringAsFixed(1)} kg', AppTheme.sage),
                  _KPICard('☁️', 'Estimasi CO₂', '${_totalCO2.toStringAsFixed(1)} kg', AppTheme.sand),
                ]),
                const SizedBox(height: 16),

                // Wishlist results
                EcoCard(borderColor: AppTheme.sage.withOpacity(0.3), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hasil Cooling Period', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.forest)),
                  const SizedBox(height: 4),
                  Text('Berapa banyak pembelian yang berhasil ditahan?', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.grey)),
                  const SizedBox(height: 16),
                  if (_wishlist.isEmpty)
                    Text('Belum ada data wishlist', style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.grey))
                  else ...[
                    _wishlistBar('🎉 Tidak Jadi Beli', _wishlistSkips, _wishlist.length, AppTheme.sage),
                    const SizedBox(height: 10),
                    _wishlistBar('🛍️ Tetap Dibeli', _wishlistBought, _wishlist.length, AppTheme.terra),
                    if (_wishlistSkips > 0) ...[
                      const SizedBox(height: 12),
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.sage.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                        child: Text('🌟 Kamu berhasil menahan $_wishlistSkips pembelian impulsif lewat cooling period!',
                          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.forestMid))),
                    ],
                  ],
                ])),
                const SizedBox(height: 16),

                // Category pie chart
                if (_catCount.isNotEmpty) ...[_buildCategoryChart(), const SizedBox(height: 16)],

                // Monthly shopping summary
                EcoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ringkasan Belanja Bulan Ini', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.forest)),
                  const SizedBox(height: 14),
                  ...[
                    ['📦', 'Total pembelian dicatat', '${_logs.length} item'],
                    ['💸', 'Total pengeluaran', 'Rp ${_fmtP(_logs.fold(0.0, (s, l) => s + l.price))}'],
                    ['♻️', 'Sampah kemasan dihasilkan', '${_totalWaste.toStringAsFixed(2)} kg'],
                    ['🚚', 'Belanja online vs offline', '${_logs.where((l) => l.isOnline).length} vs ${_logs.where((l) => !l.isOnline).length}'],
                  ].map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Text(row[0], style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(row[1], style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.ink))),
                      Text(row[2], style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.forest)),
                    ]),
                  )),
                ])),
                const SizedBox(height: 24),
              ]))),
    );
  }

  Widget _wishlistBar(String label, int count, int total, Color color) {
    final pct = total == 0 ? 0.0 : count / total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
        Text('$count item (${(pct * 100).toStringAsFixed(0)}%)', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
        value: pct, minHeight: 10, backgroundColor: AppTheme.bgLight,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      )),
    ]);
  }

  Widget _buildCategoryChart() {
    final cats = _catCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = cats.take(5).toList();
    const colors = [AppTheme.sage, AppTheme.sand, AppTheme.terra, AppTheme.forestMid, AppTheme.sky];
    return EcoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Kategori Terbanyak Dievaluasi', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.forest)),
      const SizedBox(height: 16),
      SizedBox(height: 180, child: Row(children: [
        Expanded(child: PieChart(PieChartData(
          sections: top.asMap().entries.map((e) {
            final pct = e.value.value / _evals.length * 100;
            return PieChartSectionData(
              value: e.value.value.toDouble(), color: colors[e.key % colors.length], radius: 60,
              title: '${pct.toStringAsFixed(0)}%',
              titleStyle: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.white),
            );
          }).toList(),
          sectionsSpace: 3, centerSpaceRadius: 30,
        ))),
        const SizedBox(width: 16),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: top.asMap().entries.map((e) {
          final lbl = e.value.key.length > 16 ? '${e.value.key.substring(0, 14)}...' : e.value.key;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(lbl, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.ink)),
          ]));
        }).toList()),
      ])),
    ]));
  }
}

class _KPICard extends StatelessWidget {
  final String emoji, label, value; final Color color;
  const _KPICard(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))]),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 26)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.grey, height: 1.3)),
      ])),
    ]),
  );
}
