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
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = productCategories[0];
  int _packageCount = 1;
  bool _isOnline = true;
  String _deliveryType = 'regular';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final logs = await StorageService.loadLogs(widget.auth.user!.id);
    if (mounted) {
      setState(() {
        _logs = logs..sort((a, b) => b.date.compareTo(a.date));
        _loading = false;
      });
    }
  }

  double get _totalWaste => _logs.fold(0.0, (s, l) => s + l.wasteKg);
  double get _totalSpend => _logs.fold(0.0, (s, l) => s + l.price);
  double get _totalCO2 => _logs.fold(0.0, (s, l) => s + l.co2Emission);
  int get _totalPkg => _logs.fold(0, (s, l) => s + l.packageCount);
  int get _onlineCount => _logs.where((l) => l.isOnline).length;

  double get _susScore {
    if (_logs.isEmpty) return 100;
    final avgPkg = _totalPkg / _logs.length;
    final onlineR = _onlineCount / _logs.length;
    return (100 - avgPkg * 10 - onlineR * 20).clamp(0.0, 100.0);
  }

  Future<void> _addLog() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama barang!')),
      );
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan harga!')),
      );
      return;
    }

    final log = ShoppingLog(
      id: const Uuid().v4(),
      userId: widget.auth.user!.id,
      itemName: _nameCtrl.text.trim(),
      category: _category,
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      packageCount: _packageCount,
      isOnline: _isOnline,
      date: DateTime.now(),
      deliveryType: _deliveryType,
    );
    await StorageService.addLog(log);
    _nameCtrl.clear();
    _priceCtrl.clear();
    setState(() {
      _showForm = false;
      _packageCount = 1;
      _isOnline = true;
      _deliveryType = 'regular';
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final sus = _susScore;
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 JejakBelanja'),
        backgroundColor: AppTheme.forest,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close : Icons.add),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.sage))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.sage,
              child: ListView(
                padding: const EdgeInsets.all(12),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Form selalu muncul jika _showForm true
                  if (_showForm) _buildForm(),
                  if (_showForm) const SizedBox(height: 12),
                  
                  // Summary selalu muncul
                  _buildSummary(sus),
                  const SizedBox(height: 12),
                  
                  // Trend chart selalu muncul jika ada data
                  if (_logs.isNotEmpty) _buildTrendChart(),
                  if (_logs.isNotEmpty) const SizedBox(height: 12),
                  
                  // History header selalu muncul
                  _buildHistoryHeader(),
                  const SizedBox(height: 8),
                  
                  // List items
                  if (_logs.isEmpty) _buildEmptyState(),
                  ..._logs.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LogCard(log: l),
                  )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.sage.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sage.withOpacity(0.08),
            blurRadius: 8,
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
                child: Text(
                  '✏️ Catat Pembelian Baru',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forest,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showForm = false),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: AppTheme.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTextField(_nameCtrl, 'Nama barang', Icons.shopping_bag_outlined),
          const SizedBox(height: 8),
          _buildTextField(_priceCtrl, 'Harga (Rp)', Icons.payments_outlined, isNumber: true),
          const SizedBox(height: 8),
          _buildDropdown(),
          const SizedBox(height: 10),
          _buildPackageSelector(),
          const SizedBox(height: 10),
          _buildOnlineSwitch(),
          if (_isOnline) _buildDeliverySelector(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showForm = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Batal',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EcoButton(
                  label: 'Simpan',
                  onTap: _addLog,
                  color: AppTheme.sage,
                  icon: Icons.save_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.nunito(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.sage, size: 18),
        labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppTheme.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.sage, width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.divider)),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category_outlined, color: AppTheme.sage, size: 18),
        labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppTheme.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.sage, width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.divider)),
      ),
      items: productCategories.map((c) {
        return DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.nunito(fontSize: 12)));
      }).toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }

  Widget _buildPackageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jumlah kemasan:', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: [1, 2, 3, 4, 5].map((n) {
            return GestureDetector(
              onTap: () => setState(() => _packageCount = n),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _packageCount == n ? AppTheme.sage : AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _packageCount == n ? AppTheme.sage : AppTheme.divider),
                ),
                alignment: Alignment.center,
                child: Text('$n', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: _packageCount == n ? AppTheme.white : AppTheme.ink)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOnlineSwitch() {
    return Row(
      children: [
        Expanded(child: Text('Belanja online?', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700))),
        Switch(value: _isOnline, activeColor: AppTheme.sage, onChanged: (v) => setState(() => _isOnline = v)),
      ],
    );
  }

  Widget _buildDeliverySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text('Jenis pengiriman:', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: ['regular', 'sameday'].map((t) {
            return GestureDetector(
              onTap: () => setState(() => _deliveryType = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _deliveryType == t ? AppTheme.sage.withOpacity(0.12) : AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _deliveryType == t ? AppTheme.sage : AppTheme.divider, width: _deliveryType == t ? 2 : 1.5),
                ),
                child: Text(
                  t == 'regular' ? '🚚 Reguler' : '⚡ Same-Day',
                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: _deliveryType == t ? AppTheme.sage : AppTheme.grey),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummary(double sus) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 1),
        boxShadow: [BoxShadow(color: AppTheme.sage.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sustainability Score', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(sus.toStringAsFixed(0), style: GoogleFonts.nunito(fontSize: 30, fontWeight: FontWeight.w900, color: AppTheme.susColor(sus))),
                        const SizedBox(width: 2),
                        Text('/100', style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.grey.withOpacity(0.6), fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: sus / 100,
                        minHeight: 4,
                        backgroundColor: AppTheme.bgLight,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.susColor(sus)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statItem('${_totalPkg}', 'Kemasan', '📦'),
                  const SizedBox(height: 4),
                  _statItem('${_totalWaste.toStringAsFixed(1)} kg', 'Sampah', '🗑️'),
                  const SizedBox(height: 4),
                  _statItem('${_totalCO2.toStringAsFixed(1)} kg', 'CO₂', '☁️'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Bottom stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statMini('${_logs.length}', 'Total'),
              _statMini('$_onlineCount', 'Online'),
              _statMini('Rp ${_fmtP(_totalSpend)}', 'Belanja'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, String emoji) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(value, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.forest)),
        const SizedBox(width: 2),
        Text(label, style: GoogleFonts.nunito(fontSize: 9, color: AppTheme.grey)),
      ],
    );
  }

  Widget _statMini(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.forest)),
        Text(label, style: GoogleFonts.nunito(fontSize: 9, color: AppTheme.grey)),
      ],
    );
  }

  Widget _buildTrendChart() {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayLogs = _logs.where((l) =>
          l.date.day == day.day && l.date.month == day.month && l.date.year == day.year).toList();
      return {
        'label': '${day.day}/${day.month}',
        'waste': dayLogs.fold(0.0, (s, l) => s + l.wasteKg),
      };
    });
    final maxWaste = days.map((d) => d['waste'] as double).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 1),
        boxShadow: [BoxShadow(color: AppTheme.sage.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📈 Tren Konsumsi 7 Hari Terakhir', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.forest)),
          const SizedBox(height: 2),
          Text('Estimasi sampah kemasan per hari (kg)', style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.grey)),
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final waste = d['waste'] as double;
                final barH = maxWaste == 0 ? 4.0 : ((waste / maxWaste) * 50).clamp(4.0, 50.0);
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (waste > 0) Text('${waste.toStringAsFixed(1)}', style: GoogleFonts.nunito(fontSize: 7, color: AppTheme.terra, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Container(height: barH, margin: const EdgeInsets.symmetric(horizontal: 1), 
                        decoration: BoxDecoration(
                          color: waste > 0 ? AppTheme.terra.withOpacity(0.6) : AppTheme.divider,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(d['label'] as String, style: GoogleFonts.nunito(fontSize: 7, color: AppTheme.grey)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.sage, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text('Riwayat Belanja', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.forest)),
        const Spacer(),
        Text('${_logs.length} item', style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.grey)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text('🛍️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Belum Ada Catatan Belanja', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.forest)),
            const SizedBox(height: 4),
            Text('Tekan + untuk mencatat pembelianmu', style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.grey)),
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

// ========== LOG CARD ==========
class _LogCard extends StatelessWidget {
  final ShoppingLog log;
  const _LogCard({required this.log});

  String _fmt(double p) {
    if (p >= 1e6) return '${(p / 1e6).toStringAsFixed(1)} jt';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)} rb';
    return p.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider, width: 1),
        boxShadow: [BoxShadow(color: AppTheme.sage.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(log.isOnline ? '🛒' : '🏪', style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.itemName, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.forest), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(log.category, style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.grey)),
                    if (log.isOnline) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: AppTheme.sage.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          log.deliveryType == 'sameday' ? '⚡ Same-day' : '🚚 Reguler',
                          style: GoogleFonts.nunito(fontSize: 8, color: AppTheme.sage, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('📦 ×${log.packageCount}', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: log.packageCount > 2 ? AppTheme.terra : AppTheme.forestMid)),
              const SizedBox(height: 1),
              Text('${log.wasteKg.toStringAsFixed(1)} kg', style: GoogleFonts.nunito(fontSize: 9, color: AppTheme.grey)),
              Text('Rp ${_fmt(log.price)}', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.ink)),
            ],
          ),
        ],
      ),
    );
  }
}