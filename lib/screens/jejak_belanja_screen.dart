// lib/screens/jejak_belanja_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../utils/storage_service.dart';
import '../widgets/common_widgets.dart';

class JejakBelanjaScreen extends StatefulWidget {
  final AuthProvider auth;
  const JejakBelanjaScreen({super.key, required this.auth});
  @override State<JejakBelanjaScreen> createState() => _JejakBelanjaScreenState();
}

class _JejakBelanjaScreenState extends State<JejakBelanjaScreen> {
  List<ShoppingLog> _logs = [];
  bool _loading = true, _showForm = false;
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = productCategories[0];
  int _packageCount = 1;
  bool _isOnline = true;
  String _deliveryType = 'regular';

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _nameCtrl.dispose(); _priceCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final logs = await StorageService.loadLogs(widget.auth.user!.id);
    if (mounted) setState(() { _logs = logs..sort((a, b) => b.date.compareTo(a.date)); _loading = false; });
  }

  double get _totalWaste  => _logs.fold(0.0, (s, l) => s + l.wasteKg);
  double get _totalSpend  => _logs.fold(0.0, (s, l) => s + l.price);
  double get _totalCO2    => _logs.fold(0.0, (s, l) => s + l.co2Emission);
  int    get _totalPkg    => _logs.fold(0, (s, l) => s + l.packageCount);
  int    get _onlineCount => _logs.where((l) => l.isOnline).length;

  double get _susScore {
    if (_logs.isEmpty) return 100;
    final avgPkg = _totalPkg / _logs.length;
    final onlineR = _onlineCount / _logs.length;
    return (100 - avgPkg * 10 - onlineR * 20).clamp(0.0, 100.0);
  }

  Future<void> _addLog() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final log = ShoppingLog(
      id: const Uuid().v4(), userId: widget.auth.user!.id,
      itemName: _nameCtrl.text.trim(), category: _category,
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      packageCount: _packageCount, isOnline: _isOnline,
      date: DateTime.now(), deliveryType: _deliveryType,
    );
    await StorageService.addLog(log);
    _nameCtrl.clear(); _priceCtrl.clear();
    setState(() { _showForm = false; _packageCount = 1; _isOnline = true; _deliveryType = 'regular'; });
    _load();
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, color: AppTheme.sage, size: 20),
    labelStyle: GoogleFonts.nunito(fontSize: 13, color: AppTheme.grey),
  );

  @override
  Widget build(BuildContext context) {
    final sus = _susScore;
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 JejakBelanja'),
        backgroundColor: AppTheme.forest,
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: Icon(_showForm ? Icons.close : Icons.add), onPressed: () => setState(() => _showForm = !_showForm))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.sage))
          : RefreshIndicator(onRefresh: _load, color: AppTheme.sage,
              child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_showForm) _buildForm(),
                _buildSummary(sus),
                const SizedBox(height: 16),
                // Trend chart
                if (_logs.isNotEmpty) ...[_buildTrendChart(), const SizedBox(height: 16)],
                SectionHeader(title: 'Riwayat Belanja', subtitle: '${_logs.length} item tercatat'),
                const SizedBox(height: 12),
                if (_logs.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Column(children: [
                    const Text('🛍️', style: TextStyle(fontSize: 48)), const SizedBox(height: 12),
                    Text('Belum ada catatan belanja', style: GoogleFonts.nunito(color: AppTheme.grey, fontSize: 14)),
                    Text('Tekan + untuk catat pembelian', style: GoogleFonts.nunito(color: AppTheme.grey.withOpacity(0.6), fontSize: 12)),
                  ])))
                else ..._logs.map((l) => _LogCard(log: l)),
                const SizedBox(height: 24),
              ]))),
    );
  }

  Widget _buildForm() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.sage.withOpacity(0.4), width: 2)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Catat Pembelian Baru', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.forest)),
      const SizedBox(height: 14),
      TextField(controller: _nameCtrl, style: GoogleFonts.nunito(fontSize: 13), decoration: _inputDeco('Nama barang', Icons.shopping_bag_outlined)),
      const SizedBox(height: 10),
      TextField(controller: _priceCtrl, keyboardType: TextInputType.number, style: GoogleFonts.nunito(fontSize: 13), decoration: _inputDeco('Harga (Rp)', Icons.payments_outlined)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _category, decoration: _inputDeco('Kategori', Icons.category_outlined),
        items: productCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.nunito(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _category = v!),
      ),
      const SizedBox(height: 12),
      Text('Jumlah kemasan:', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
      const SizedBox(height: 8),
      Row(children: [1, 2, 3, 4, 5].map((n) => GestureDetector(
        onTap: () => setState(() => _packageCount = n),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _packageCount == n ? AppTheme.sage : AppTheme.bgLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _packageCount == n ? AppTheme.sage : AppTheme.divider),
          ),
          alignment: Alignment.center,
          child: Text('$n', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: _packageCount == n ? AppTheme.white : AppTheme.ink)),
        ),
      )).toList()),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Text('Belanja online?', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700))),
        Switch(value: _isOnline, activeColor: AppTheme.sage, onChanged: (v) => setState(() => _isOnline = v)),
      ]),
      if (_isOnline) ...[
        const SizedBox(height: 8),
        Text('Jenis pengiriman:', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(children: ['regular', 'sameday'].map((t) => GestureDetector(
          onTap: () => setState(() => _deliveryType = t),
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _deliveryType == t ? AppTheme.sage.withOpacity(0.12) : AppTheme.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _deliveryType == t ? AppTheme.sage : AppTheme.divider, width: _deliveryType == t ? 2 : 1.5),
            ),
            child: Text(t == 'regular' ? '🚚 Reguler' : '⚡ Same-Day', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: _deliveryType == t ? AppTheme.sage : AppTheme.grey)),
          ),
        )).toList()),
      ],
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: EcoButton(label: 'Catat Pembelian', onTap: _addLog)),
    ]),
  );

  Widget _buildSummary(double sus) => EcoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Sustainability Score', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(sus.toStringAsFixed(0), style: GoogleFonts.nunito(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.susColor(sus))),
          Text('/100', style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.grey.withOpacity(0.6), fontWeight: FontWeight.w700)),
        ]),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
          value: sus / 100, minHeight: 8, backgroundColor: AppTheme.bgLight,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.susColor(sus)),
        )),
      ])),
      const SizedBox(width: 20),
      Column(children: [
        _statBubble('${_totalPkg}', 'Kemasan', '📦'),
        const SizedBox(height: 10),
        _statBubble('${_totalWaste.toStringAsFixed(1)} kg', 'Sampah Est.', '🗑️'),
        const SizedBox(height: 10),
        _statBubble('${_totalCO2.toStringAsFixed(1)} kg', 'CO₂ Est.', '☁️'),
      ]),
    ]),
    const SizedBox(height: 14), const Divider(height: 1), const SizedBox(height: 14),
    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _miniStat('${_logs.length}', 'Total Item'),
      _miniStat('$_onlineCount', 'Online'),
      _miniStat('Rp ${_fmtP(_totalSpend)}', 'Total Belanja'),
    ]),
  ]));

  Widget _buildTrendChart() {
    // Last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayLogs = _logs.where((l) => l.date.day == day.day && l.date.month == day.month && l.date.year == day.year).toList();
      return {'label': '${day.day}/${day.month}', 'waste': dayLogs.fold(0.0, (s, l) => s + l.wasteKg), 'count': dayLogs.length};
    });
    final maxWaste = days.map((d) => d['waste'] as double).reduce((a, b) => a > b ? a : b);

    return EcoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('📈 Tren Konsumsi 7 Hari Terakhir', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.forest)),
      const SizedBox(height: 4),
      Text('Estimasi sampah kemasan per hari (kg)', style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.grey)),
      const SizedBox(height: 16),
      SizedBox(height: 100, child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final waste = d['waste'] as double;
          final barH = maxWaste == 0 ? 4.0 : ((waste / maxWaste) * 80).clamp(4.0, 80.0);
          return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (waste > 0) Text('${waste.toStringAsFixed(1)}', style: GoogleFonts.nunito(fontSize: 8, color: AppTheme.terra, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Container(height: barH, margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: waste > 0 ? AppTheme.terra.withOpacity(0.6) : AppTheme.divider, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
            const SizedBox(height: 4),
            Text(d['label'] as String, style: GoogleFonts.nunito(fontSize: 8, color: AppTheme.grey)),
          ]));
        }).toList(),
      )),
    ]));
  }

  Widget _statBubble(String v, String l, String e) => Column(children: [
    Text(e, style: const TextStyle(fontSize: 18)),
    const SizedBox(height: 2),
    Text(v, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.forest)),
    Text(l, style: GoogleFonts.nunito(fontSize: 9, color: AppTheme.grey)),
  ]);

  Widget _miniStat(String v, String l) => Column(children: [
    Text(v, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.forest)),
    Text(l, style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.grey)),
  ]);

  String _fmtP(double p) { if (p >= 1e6) return '${(p/1e6).toStringAsFixed(1)} jt'; if (p >= 1000) return '${(p/1000).toStringAsFixed(0)} rb'; return p.toStringAsFixed(0); }
}

class _LogCard extends StatelessWidget {
  final ShoppingLog log;
  const _LogCard({required this.log});
  String _fmt(double p) { if (p >= 1e6) return '${(p/1e6).toStringAsFixed(1)} jt'; if (p >= 1000) return '${(p/1000).toStringAsFixed(0)} rb'; return p.toStringAsFixed(0); }
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider, width: 1.5)),
    child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center, child: Text(log.isOnline ? '🛒' : '🏪', style: const TextStyle(fontSize: 22))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(log.itemName, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.forest)),
        Row(children: [
          Text(log.category, style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.grey)),
          if (log.isOnline) ...[const SizedBox(width: 6), Text(log.deliveryType == 'sameday' ? '⚡ Same-day' : '🚚 Reguler', style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.grey))],
        ]),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('📦 ×${log.packageCount}', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: log.packageCount > 2 ? AppTheme.terra : AppTheme.forestMid)),
        Text('${log.wasteKg.toStringAsFixed(1)} kg sampah', style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.grey)),
        Text('Rp ${_fmt(log.price)}', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.ink)),
      ]),
    ]),
  );
}
