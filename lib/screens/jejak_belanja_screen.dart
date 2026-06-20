// lib/screens/jejak_belanja_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../utils/storage_service.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';
import 'shopping_detail_screen.dart';

class JejakBelanjaScreen extends StatefulWidget {
  final AuthProvider auth;
  const JejakBelanjaScreen({super.key, required this.auth});
  @override State<JejakBelanjaScreen> createState() => _JejakBelanjaScreenState();
}

class _JejakBelanjaScreenState extends State<JejakBelanjaScreen> {
  List<ShoppingLog> _logs = [];
  bool _loading = true;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
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

  void _showAddForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddLogSheet(
        auth: widget.auth,
        onAdded: _load,
      ),
    );
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(auth: widget.auth),
      ),
      (route) => false,
    );
  }

  void _navigateToDetail(ShoppingLog log) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingDetailScreen(
          log: log,
          auth: widget.auth,
          onUpdated: _load,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sus = _susScore;
    final displayLogs = _showAll ? _logs : _logs.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jejak Belanja'),
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
            icon: const Icon(Icons.add_rounded, color: AppTheme.cream),
            onPressed: _showAddForm,
            tooltip: 'Tambah Belanja',
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
                  _buildSummary(sus),
                  const SizedBox(height: 12),
                  if (_logs.isNotEmpty) _buildTrendChart(),
                  if (_logs.isNotEmpty) const SizedBox(height: 12),
                  _buildHistoryHeader(),
                  const SizedBox(height: 8),
                  if (_logs.isEmpty) _buildEmptyState(),
                  ...displayLogs.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _navigateToDetail(l),
                      child: _LogCard(log: l),
                    ),
                  )),
                  if (_logs.length > 5) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _showAll = !_showAll),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.sage.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.sage.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showAll ? 'Sembunyikan' : 'Lihat Semua (${_logs.length})',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.sage,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _showAll ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                color: AppTheme.sage,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
        'count': dayLogs.length,
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
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Tren Konsumsi 7 Hari Terakhir',
                style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.forest),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Estimasi sampah kemasan per hari (kg)',
            style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final waste = data['waste'] as double;
                final label = data['label'] as String;
                final barH = maxWaste == 0 ? 4.0 : ((waste / maxWaste) * 60).clamp(4.0, 60.0);
                final isToday = index == days.length - 1;
                
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
                        label,
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.sage,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Hari ini',
                style: GoogleFonts.nunito(fontSize: 8, color: AppTheme.sage),
              ),
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.terra.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Sebelumnya',
                style: GoogleFonts.nunito(fontSize: 8, color: AppTheme.grey),
              ),
            ],
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

// ========== ADD LOG SHEET ==========
class _AddLogSheet extends StatefulWidget {
  final AuthProvider auth;
  final VoidCallback onAdded;
  const _AddLogSheet({required this.auth, required this.onAdded});

  @override
  State<_AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<_AddLogSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = productCategories[0];
  int _packageCount = 1;
  bool _isOnline = true;
  String _deliveryType = 'regular';
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _showImagePickerDialog() {
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
                'Tambah Foto',
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
                  _ImageSourceBtn(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  _ImageSourceBtn(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                  if (_selectedImage != null)
                    _ImageSourceBtn(
                      icon: Icons.delete,
                      label: 'Hapus',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _removeImage();
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

  Future<void> _saveLog() async {
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

    setState(() => _isLoading = true);

    try {
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
        imagePath: _selectedImage?.path,
      );
      await StorageService.addLog(log);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Belanja berhasil dicatat!'),
            backgroundColor: AppTheme.sage,
          ),
        );
        Navigator.pop(context);
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal mencatat: $e')),
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
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '✏️ Catat Belanja',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forest,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.grey,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Nama Barang
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama Barang',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameCtrl,
                            style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.forest),
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama barang',
                              hintStyle: GoogleFonts.nunito(
                                fontSize: 14,
                                color: AppTheme.grey.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppTheme.sage, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.sage, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: true,
                              fillColor: AppTheme.bgLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Harga
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga (Rp)',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.forest),
                            decoration: InputDecoration(
                              hintText: 'Masukkan harga',
                              hintStyle: GoogleFonts.nunito(
                                fontSize: 14,
                                color: AppTheme.grey.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.sage, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.sage, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: true,
                              fillColor: AppTheme.bgLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Kategori
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kategori',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _category,
                            style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.forest),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.category_outlined, color: AppTheme.sage, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.sage, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: true,
                              fillColor: AppTheme.bgLight,
                            ),
                            items: productCategories.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: AppTheme.forest,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Jumlah Kemasan
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jumlah Kemasan',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [1, 2, 3, 4, 5].map((n) {
                              final isSelected = _packageCount == n;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _packageCount = n),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.sage : AppTheme.bgLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.sage : AppTheme.divider,
                                        width: isSelected ? 2 : 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$n',
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? AppTheme.white : AppTheme.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Online Switch
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Belanja online?',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isOnline,
                            activeColor: AppTheme.sage,
                            onChanged: (v) => setState(() => _isOnline = v),
                          ),
                        ],
                      ),
                      if (_isOnline) ...[
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jenis Pengiriman',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: ['regular', 'sameday'].map((t) {
                                final isSelected = _deliveryType == t;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _deliveryType = t),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.sage.withOpacity(0.12) : AppTheme.bgLight,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.sage : AppTheme.divider,
                                          width: isSelected ? 2 : 1.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        t == 'regular' ? '🚚 Reguler' : '⚡ Same-Day',
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? AppTheme.sage : AppTheme.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Foto
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foto (Opsional)',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showImagePickerDialog,
                            child: Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.bgLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.divider, width: 1.5),
                              ),
                              child: _selectedImage != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            _selectedImage!,
                                            width: double.infinity,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: _removeImage,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 32,
                                          color: AppTheme.grey.withOpacity(0.6),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap untuk tambah foto',
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            color: AppTheme.grey.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading ? null : () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.grey, width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Batal',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading ? null : _saveLog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.save_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Simpan',
                                            style: GoogleFonts.nunito(
                                              fontSize: 14,
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ========== IMAGE SOURCE BUTTON ==========
class _ImageSourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ImageSourceBtn({
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

// ========== LOG CARD ==========
class _LogCard extends StatelessWidget {
  final ShoppingLog log;
  const _LogCard({required this.log});

  String _fmt(double p) {
    if (p >= 1e6) return '${(p / 1e6).toStringAsFixed(1)} jt';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)} rb';
    return p.toStringAsFixed(0);
  }

  Widget _buildImageWidget(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(log.isOnline ? '🛒' : '🏪', style: const TextStyle(fontSize: 18)),
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(log.isOnline ? '🛒' : '🏪', style: const TextStyle(fontSize: 18)),
        ),
      );
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(log.isOnline ? '🛒' : '🏪', style: const TextStyle(fontSize: 18)),
          ),
        ),
      );
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(log.isOnline ? '🛒' : '🏪', style: const TextStyle(fontSize: 18)),
    );
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
          // Gambar
          _buildImageWidget(log.imagePath),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.itemName,
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.forest),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    Text(log.category, style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.grey)),
                    if (log.isOnline) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: AppTheme.sage.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          log.deliveryType == 'sameday' ? '⚡ Same-day' : '🚚 Reguler',
                          style: GoogleFonts.nunito(fontSize: 8, color: AppTheme.sage, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: log.packageCount > 2 ? AppTheme.terra.withOpacity(0.1) : AppTheme.forestMid.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '📦 ×${log.packageCount}',
                        style: GoogleFonts.nunito(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: log.packageCount > 2 ? AppTheme.terra : AppTheme.forestMid,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${log.wasteKg.toStringAsFixed(1)} kg',
                style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.terra),
              ),
              const SizedBox(height: 1),
              Text(
                'Rp ${_fmt(log.price)}',
                style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.forestMid),
              ),
            ],
          ),
        ],
      ),
    );
  }
}