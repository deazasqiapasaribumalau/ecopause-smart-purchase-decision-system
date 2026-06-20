// lib/screens/shopping_detail_screen.dart
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

class ShoppingDetailScreen extends StatefulWidget {
  final ShoppingLog log;
  final AuthProvider auth;
  final VoidCallback onUpdated;

  const ShoppingDetailScreen({
    super.key,
    required this.log,
    required this.auth,
    required this.onUpdated,
  });

  @override
  State<ShoppingDetailScreen> createState() => _ShoppingDetailScreenState();
}

class _ShoppingDetailScreenState extends State<ShoppingDetailScreen> {
  late ShoppingLog _log;
  bool _isEditing = false;
  bool _isLoading = false;

  // Edit controllers
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = '';
  int _packageCount = 1;
  bool _isOnline = true;
  String _deliveryType = 'regular';
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _log = widget.log;
    _loadData();
  }

  void _loadData() {
    _nameCtrl.text = _log.itemName;
    _priceCtrl.text = _log.price.toString();
    _category = _log.category;
    _packageCount = _log.packageCount;
    _isOnline = _log.isOnline;
    _deliveryType = _log.deliveryType;
    if (_log.imagePath != null && _log.imagePath!.isNotEmpty) {
      _selectedImage = File(_log.imagePath!);
    }
  }

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
                'Pilih Foto',
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

  Future<void> _saveChanges() async {
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
      final updatedLog = _log.copyWith(
        itemName: _nameCtrl.text.trim(),
        category: _category,
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        packageCount: _packageCount,
        isOnline: _isOnline,
        deliveryType: _deliveryType,
        imagePath: _selectedImage?.path,
      );

      await StorageService.updateLog(updatedLog);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Belanja berhasil diperbarui!'),
            backgroundColor: AppTheme.sage,
          ),
        );
        setState(() {
          _log = updatedLog;
          _isEditing = false;
        });
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal memperbarui: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Catatan?',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppTheme.forest,
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus catatan belanja "${_log.itemName}"?',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppTheme.ink,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
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
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Hapus',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppTheme.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await StorageService.deleteLog(_log.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Catatan berhasil dihapus!'),
              backgroundColor: AppTheme.terra,
            ),
          );
          Navigator.pop(context);
          widget.onUpdated();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Gagal menghapus: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _fmtDate(DateTime d) => '${d.day} ${_getMonth(d.month)} ${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _getMonth(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'][m - 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '✏️ Edit Belanja' : 'Detail Belanja'),
        backgroundColor: AppTheme.forest,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.cream),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali',
        ),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppTheme.cream,
        ),
        // HAPUS actions (edit dan hapus di AppBar)
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.sage))
          : _isEditing ? _buildEditForm() : _buildDetailView(),
    );
  }

  Widget _buildDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar
          if (_log.imagePath != null && _log.imagePath!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 250,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.sage.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImageWidget(_log.imagePath!),
              ),
            ),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.sage.withOpacity(0.05),
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
                      child: Text(
                        _log.itemName,
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.forest,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _log.isOnline ? AppTheme.sage.withOpacity(0.1) : AppTheme.forestMid.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _log.isOnline ? AppTheme.sage : AppTheme.forestMid,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _log.isOnline ? '🛒 Online' : '🏪 Offline',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _log.isOnline ? AppTheme.sage : AppTheme.forestMid,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _log.category,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _detailItem(
                      icon: Icons.attach_money_rounded,
                      label: 'Harga',
                      value: 'Rp ${_log.price.toStringAsFixed(0)}',
                    ),
                    const SizedBox(width: 16),
                    _detailItem(
                      icon: Icons.inventory_2_rounded,
                      label: 'Kemasan',
                      value: '${_log.packageCount} pcs',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_log.isOnline)
                  _detailItem(
                    icon: Icons.local_shipping_rounded,
                    label: 'Pengiriman',
                    value: _log.deliveryType == 'sameday' ? '⚡ Same-Day' : '🚚 Reguler',
                  ),
                const SizedBox(height: 12),
                _detailItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tanggal',
                  value: _fmtDate(_log.date),
                ),
                const SizedBox(height: 12),
                _detailItem(
                  icon: Icons.eco_rounded,
                  label: 'Dampak Lingkungan',
                  value: '${_log.wasteKg.toStringAsFixed(1)} kg sampah • ${_log.co2Emission.toStringAsFixed(1)} kg CO₂',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Tombol Aksi
          Row(
            children: [
              Expanded(
                child: EcoButton(
                  label: 'Edit',
                  onTap: () => setState(() => _isEditing = true),
                  outline: true,
                  color: AppTheme.sage,
                  icon: Icons.edit_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EcoButton(
                  label: 'Hapus',
                  onTap: _deleteLog,
                  outline: true,
                  color: AppTheme.terra,
                  icon: Icons.delete_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  onTap: _isLoading ? null : () {
                    setState(() {
                      _isEditing = false;
                      _loadData();
                    });
                  },
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
                  onTap: _isLoading ? null : _saveChanges,
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
    );
  }

  Widget _detailItem({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.sage),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.forest,
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.bgLight,
          child: const Icon(Icons.image_not_supported, size: 40, color: AppTheme.grey),
        ),
      );
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.bgLight,
          child: const Icon(Icons.image_not_supported, size: 40, color: AppTheme.grey),
        ),
      );
    }

    return Container(
      color: AppTheme.bgLight,
      child: const Icon(Icons.image_not_supported, size: 40, color: AppTheme.grey),
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