// lib/screens/report_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../utils/storage_service.dart';
import '../widgets/common_widgets.dart';
import 'fomo_detector_screen.dart';
import 'home_screen.dart';
import 'evaluation_detail_screen.dart';

class ReportScreen extends StatefulWidget {
  final AuthProvider auth;
  const ReportScreen({super.key, required this.auth});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<FomoEvaluation> _evals = [];
  List<ShoppingLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.auth.user!.id;
    final results = await Future.wait([
      StorageService.loadEvals(uid),
      StorageService.loadLogs(uid),
    ]);
    if (mounted) {
      setState(() {
        _evals = results[0] as List<FomoEvaluation>;
        _logs = results[1] as List<ShoppingLog>;
        _loading = false;
      });
    }
  }

  int get _skippedCount => _evals.where((e) => e.decision == 'skip').length;
  double get _totalSpent => _evals.fold(0.0, (s, e) => s + e.price);
  double get _totalWaste => _logs.fold(0.0, (s, l) => s + l.wasteKg);
  int get _boughtCount => _evals.where((e) => e.decision == 'buy').length;
  int get _wishlistCount => _evals.where((e) => e.decision == 'wishlist').length;

  String _fmtP(double p) {
    if (p >= 1e6) return '${(p / 1e6).toStringAsFixed(1)} jt';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)} rb';
    return p.toStringAsFixed(0);
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

  void _showEvaluationDetail(FomoEvaluation eval) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EvaluationDetailScreen(
          eval: eval,
          auth: widget.auth,
        ),
      ),
    );
  }

  void _printWeeklyReport() {
    _showReportDialog('Laporan Mingguan', _getWeeklyReport());
  }

  void _printMonthlyReport() {
    _showReportDialog('Laporan Bulanan', _getMonthlyReport());
  }

  String _getWeeklyReport() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weeklyEvals = _evals.where((e) => e.date.isAfter(weekAgo)).toList();
    final weeklyLogs = _logs.where((l) => l.date.isAfter(weekAgo)).toList();
    
    final totalItems = weeklyEvals.length;
    final totalBought = weeklyEvals.where((e) => e.decision == 'buy').length;
    final totalSkipped = weeklyEvals.where((e) => e.decision == 'skip').length;
    final totalWishlist = weeklyEvals.where((e) => e.decision == 'wishlist').length;
    final totalWaste = weeklyLogs.fold(0.0, (s, l) => s + l.wasteKg);
    final totalSpend = weeklyEvals.fold(0.0, (s, e) => s + e.price);

    return '''
📊 LAPORAN MINGGUAN
━━━━━━━━━━━━━━━━━━━━
Periode: ${_fmtDate(weekAgo)} - ${_fmtDate(now)}

📝 Ringkasan Evaluasi:
• Total Evaluasi: $totalItems
• Dibeli: $totalBought
• Dilewati: $totalSkipped
• Wishlist: $totalWishlist

💰 Total Pengeluaran: Rp ${_fmtP(totalSpend)}
🌱 Total Sampah: ${totalWaste.toStringAsFixed(1)} kg

━━━━━━━━━━━━━━━━━━━━
Terus bijak dalam berbelanja! 🌿
    ''';
  }

  String _getMonthlyReport() {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    final monthlyEvals = _evals.where((e) => e.date.isAfter(monthAgo)).toList();
    final monthlyLogs = _logs.where((l) => l.date.isAfter(monthAgo)).toList();
    
    final totalItems = monthlyEvals.length;
    final totalBought = monthlyEvals.where((e) => e.decision == 'buy').length;
    final totalSkipped = monthlyEvals.where((e) => e.decision == 'skip').length;
    final totalWishlist = monthlyEvals.where((e) => e.decision == 'wishlist').length;
    final totalWaste = monthlyLogs.fold(0.0, (s, l) => s + l.wasteKg);
    final totalSpend = monthlyEvals.fold(0.0, (s, e) => s + e.price);

    // Hitung rata-rata per minggu
    final avgWeekly = totalItems / 4;

    return '''
📊 LAPORAN BULANAN
━━━━━━━━━━━━━━━━━━━━
Periode: ${_fmtDate(monthAgo)} - ${_fmtDate(now)}

📝 Ringkasan Evaluasi:
• Total Evaluasi: $totalItems
• Rata-rata per Minggu: ${avgWeekly.toStringAsFixed(1)}
• Dibeli: $totalBought
• Dilewati: $totalSkipped
• Wishlist: $totalWishlist

💰 Total Pengeluaran: Rp ${_fmtP(totalSpend)}
🌱 Total Sampah: ${totalWaste.toStringAsFixed(1)} kg

📈 Insight:
• ${totalSkipped > totalBought ? '✅ Kamu berhasil menahan diri dari ${totalSkipped} pembelian impulsif!' : '💪 Terus tingkatkan kesadaran belanjamu!'}
• ${totalWaste > 5 ? '🌍 Sampah yang dihasilkan cukup tinggi, coba kurangi kemasan!' : '🌱 Sampahmu terkendali, pertahankan!'}

━━━━━━━━━━━━━━━━━━━━
Terus bijak dalam berbelanja! 🌿
    ''';
  }

  void _showReportDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppTheme.forest,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Text(
              content,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppTheme.ink,
                height: 1.6,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.nunito(color: AppTheme.grey),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // TODO: Implement share/copy to clipboard
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Laporan siap dicopy!'),
                  backgroundColor: AppTheme.sage,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            label: Text(
              'Copy',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.cream),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.sage))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.sage,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tombol Cetak Laporan
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _printWeeklyReport,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.sage,
                                    AppTheme.forestMid,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_view_week_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Laporan Mingguan',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _printMonthlyReport,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.forestMid,
                                    AppTheme.forest,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Laporan Bulanan',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Statistik Ringkasan
                    _buildSummaryCards(),
                    const SizedBox(height: 16),

                    // Grafik sederhana
                    _buildSimpleChart(),
                    const SizedBox(height: 16),

                    // Daftar Evaluasi
                    _buildSectionHeader('Semua Evaluasi', _evals.length),
                    const SizedBox(height: 12),
                    if (_evals.isEmpty)
                      EcoEmptyState(
                        title: 'Belum Ada Evaluasi',
                        subtitle: 'Mulai evaluasi pembelian pertamamu',
                        icon: Icons.analytics_outlined,
                        buttonLabel: 'Mulai Evaluasi',
                        onButtonTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FomoDetectorScreen(auth: widget.auth),
                            ),
                          );
                        },
                      )
                    else ...[
                      ..._evals.reversed.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _showEvaluationDetail(e),
                          child: _ReportEvalTile(eval: e),
                        ),
                      )),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            emoji: '🚫',
            label: 'Dicegah',
            value: '$_skippedCount',
            color: AppTheme.terra,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            emoji: '💰',
            label: 'Pengeluaran',
            value: 'Rp ${_fmtP(_totalSpent)}',
            color: AppTheme.forestMid,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            emoji: '🌱',
            label: 'Sampah',
            value: '${_totalWaste.toStringAsFixed(1)} kg',
            color: AppTheme.sage,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleChart() {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayLogs = _logs.where((l) =>
          l.date.day == day.day &&
          l.date.month == day.month &&
          l.date.year == day.year).toList();
      final waste = dayLogs.fold(0.0, (s, l) => s + l.wasteKg);
      data.add({
        'label': '${day.day}/${day.month}',
        'waste': waste,
        'count': dayLogs.length,
      });
    }

    final maxWaste = data.isEmpty ? 1 : data.map((d) => d['waste'] as double).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sage.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Tren 7 Hari Terakhir',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimasi sampah kemasan per hari (kg)',
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final waste = d['waste'] as double;
                final barH = maxWaste == 0
                    ? 4.0
                    : ((waste / maxWaste) * 60).clamp(4.0, 60.0);
                final isToday = data.indexOf(d) == data.length - 1;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (waste > 0)
                        Text(
                          '${waste.toStringAsFixed(1)}',
                          style: GoogleFonts.nunito(
                            fontSize: 7,
                            color: isToday ? AppTheme.sage : AppTheme.terra,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        height: barH,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: waste > 0
                              ? (isToday ? AppTheme.sage : AppTheme.terra.withOpacity(0.6))
                              : AppTheme.divider,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d['label'] as String,
                        style: GoogleFonts.nunito(
                          fontSize: 7,
                          color: isToday ? AppTheme.sage : AppTheme.grey,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('${_boughtCount}', 'Dibeli', AppTheme.sage),
              _miniStat('${_wishlistCount}', 'Wishlist', AppTheme.sand),
              _miniStat('${_skippedCount}', 'Dicegah', AppTheme.terra),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            color: AppTheme.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
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
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.forest,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.sage.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count item',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.sage,
            ),
          ),
        ),
      ],
    );
  }
}

// ========== SUMMARY CARD ==========
class _SummaryCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;

  const _SummaryCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              color: AppTheme.ink.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== REPORT EVALUATION TILE ==========
class _ReportEvalTile extends StatelessWidget {
  final FomoEvaluation eval;

  const _ReportEvalTile({required this.eval});

  Color get _decisionColor {
    switch (eval.decision) {
      case 'buy':
        return AppTheme.forestMid;
      case 'skip':
        return AppTheme.terra;
      case 'wishlist':
        return AppTheme.sand;
      default:
        return AppTheme.grey;
    }
  }

  String get _decisionLabel {
    switch (eval.decision) {
      case 'buy':
        return '✅ Dibeli';
      case 'skip':
        return '🚫 Dilewati';
      case 'wishlist':
        return '⏳ Wishlist';
      default:
        return '❓ Unknown';
    }
  }

  Color get _bgColor => _decisionColor.withOpacity(0.08);

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _decisionColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sage.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _decisionColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  _decisionLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _decisionColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: AppTheme.grey,
              ),
              const SizedBox(width: 4),
              Text(
                _fmtDate(eval.date),
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: AppTheme.grey,
                ),
              ),
              const SizedBox(width: 12),
              if (eval.imagePath != null) ...[
                Icon(
                  Icons.image_outlined,
                  size: 12,
                  color: AppTheme.sage,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ada foto',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: AppTheme.sage,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 12,
                    color: AppTheme.sage,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Need ${eval.needScore}%',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.sage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.trending_down_rounded,
                    size: 12,
                    color: AppTheme.terra,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'FOMO ${eval.fomoScore}%',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.terra,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: eval.needScore / 100,
              minHeight: 4,
              backgroundColor: AppTheme.terra.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                eval.needScore >= 60 ? AppTheme.sage : AppTheme.terra,
              ),
            ),
          ),
        ],
      ),
    );
  }
}