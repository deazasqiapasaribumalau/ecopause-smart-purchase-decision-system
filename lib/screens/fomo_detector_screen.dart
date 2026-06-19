// lib/screens/fomo_detector_screen.dart
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
import 'fomo_result_screen.dart';

class FomoDetectorScreen extends StatefulWidget {
  final AuthProvider auth;
  const FomoDetectorScreen({super.key, required this.auth});

  @override
  State<FomoDetectorScreen> createState() => _FomoDetectorScreenState();
}

class _FomoDetectorScreenState extends State<FomoDetectorScreen> with AutomaticKeepAliveClientMixin {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = productCategories[0];
  int _step = 0; // 0=info form, 1=questions

  // Tambahan untuk foto
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  static const Map<String, String> _questions = {
    'need_it': 'Apakah kamu benar-benar membutuhkan barang ini saat ini?',
    'have_similar': 'Kamu sudah memiliki barang serupa yang masih berfungsi baik?',
    'trend': 'Kamu membeli ini karena sedang tren / viral di media sosial?',
    'influencer': 'Kamu terpengaruh iklan atau konten influencer?',
    'flash_sale': 'Alasan utama membeli adalah karena diskon / flash sale?',
    'planned': 'Rencana pembelian ini sudah ada lebih dari 1 minggu lalu?',
    'budget': 'Pembelian ini masih dalam anggaran belanja bulan ini?',
    'regret': 'Kamu pernah menyesal membeli barang serupa sebelumnya?',
    'use_30': 'Kamu yakin akan menggunakan barang ini minimal 30 kali?',
    'eco': 'Kamu mempertimbangkan dampak lingkungan sebelum membeli?',
  };

  // true = "ya" meningkatkan FOMO score
  static const Map<String, bool> _fomoDir = {
    'need_it': false,
    'have_similar': true,
    'trend': true,
    'influencer': true,
    'flash_sale': true,
    'planned': false,
    'budget': false,
    'regret': true,
    'use_30': false,
    'eco': false,
  };

  final Map<String, bool?> _answers = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // Reset semua state ke awal
  void _resetToInitialState() {
    _nameCtrl.clear();
    _priceCtrl.clear();
    _category = productCategories[0];
    _step = 0;
    _selectedImage = null;
    _answers.clear();
  }

  bool get _infoValid =>
      _nameCtrl.text.trim().isNotEmpty && _priceCtrl.text.trim().isNotEmpty;
  bool get _allAnswered => _questions.keys.every((k) => _answers[k] != null);

  // Fungsi untuk memilih foto dari galeri
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

  // Fungsi untuk mengambil foto dari kamera
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

  // Fungsi untuk menghapus foto
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // Dialog untuk memilih sumber foto
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
                  _ImageSourceButton(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  _ImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                  if (_selectedImage != null)
                    _ImageSourceButton(
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

  void _submit() async {
    if (!_allAnswered) return;

    int fomoPoints = 0, needPoints = 0;
    for (final k in _questions.keys) {
      final ans = _answers[k]!;
      if (ans == _fomoDir[k]) {
        fomoPoints++;
      } else {
        needPoints++;
      }
    }
    final fomoScore = ((fomoPoints / _questions.length) * 100).round();
    final needScore = ((needPoints / _questions.length) * 100).round();
    final decision = needScore >= 60 ? 'buy' : fomoScore >= 60 ? 'skip' : 'wishlist';

    // Simpan path foto jika ada
    String? imagePath = _selectedImage?.path;

    final eval = FomoEvaluation(
      id: const Uuid().v4(),
      userId: widget.auth.user!.id,
      itemName: _nameCtrl.text.trim(),
      category: _category,
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      needScore: needScore,
      fomoScore: fomoScore,
      date: DateTime.now(),
      decision: decision,
      answers: Map<String, bool>.from(_answers.map((k, v) => MapEntry(k, v ?? false))),
      imagePath: imagePath,
    );

    await StorageService.saveEval(eval);

    if (mounted) {
      // Reset state sebelum navigasi ke hasil
      _resetToInitialState();

      // Navigasi ke hasil dengan pushReplacement agar tidak bisa kembali ke pertanyaan
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FomoResultScreen(eval: eval, auth: widget.auth),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 FOMO Detector'),
        backgroundColor: AppTheme.forest,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: _step == 0 ? _buildInfoStep() : _buildQuestionStep(),
    );
  }

  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EcoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Barang yang Ingin Dibeli',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Isi informasi barang terlebih dahulu',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.grey),
                ),
                const SizedBox(height: 18),
                _fieldLabel('Nama Barang'),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.nunito(fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppTheme.sage),
                    hintText: 'mis. Sepatu Nike Air Max',
                  ),
                ),
                const SizedBox(height: 14),
                _fieldLabel('Harga (Rp)'),
                const SizedBox(height: 6),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.nunito(fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.sage),
                    hintText: '350000',
                  ),
                ),
                const SizedBox(height: 14),
                _fieldLabel('Kategori'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined, color: AppTheme.sage),
                  ),
                  items: productCategories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: GoogleFonts.nunito(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                // Tambahan untuk Foto
                const SizedBox(height: 20),
                _fieldLabel('Foto Barang (Opsional)'),
                const SizedBox(height: 8),
                _buildImageSection(),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: EcoButton(
              label: 'Mulai Evaluasi →',
              onTap: _infoValid
                  ? () => setState(() => _step = 1)
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Isi nama barang dan harga dulu!'),
                        ),
                      );
                    },
              icon: Icons.psychology_outlined,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '10 pertanyaan reflektif • ~2 menit',
              style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.grey),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk bagian foto
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImage != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 150,
                  width: double.infinity,
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
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showImagePickerDialog,
                  icon: const Icon(Icons.change_circle_outlined),
                  label: Text(
                    'Ganti Foto',
                    style: GoogleFonts.nunito(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.forest,
                    side: const BorderSide(color: AppTheme.forest),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          GestureDetector(
            onTap: _showImagePickerDialog,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: AppTheme.grey.withOpacity(0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap untuk tambah foto',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppTheme.grey.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'Dari galeri atau kamera',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.grey.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _fieldLabel(String t) {
    return Text(
      t,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.ink,
      ),
    );
  }

  Widget _buildQuestionStep() {
    final keys = _questions.keys.toList();
    final answered = _answers.values.where((v) => v != null).length;

    return Column(
      children: [
        Container(
          color: AppTheme.forest,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _nameCtrl.text.trim(),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppTheme.mint,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$answered / ${_questions.length}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppTheme.cream.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: answered / _questions.length,
                  minHeight: 6,
                  backgroundColor: AppTheme.forestMid.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.sage),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length + 1,
            itemBuilder: (ctx, i) {
              if (i == keys.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: EcoButton(
                    label: _allAnswered
                        ? 'Lihat Hasil Evaluasi ✨'
                        : 'Jawab semua pertanyaan dulu',
                    onTap: _allAnswered ? _submit : null,
                    color: _allAnswered ? AppTheme.sage : AppTheme.grey,
                  ),
                );
              }
              final k = keys[i];
              return _QuestionCard(
                number: i + 1,
                question: _questions[k]!,
                answer: _answers[k],
                onAnswer: (v) => setState(() => _answers[k] = v),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Widget untuk tombol sumber gambar
class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ImageSourceButton({
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

class _QuestionCard extends StatelessWidget {
  final int number;
  final String question;
  final bool? answer;
  final ValueChanged<bool> onAnswer;

  const _QuestionCard({
    required this.number,
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: answer != null ? AppTheme.sage.withOpacity(0.5) : AppTheme.divider,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sage.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: answer != null ? AppTheme.sage : AppTheme.bgLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: answer != null ? AppTheme.white : AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.forest,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AnswerBtn(
                  label: 'Ya ✓',
                  selected: answer == true,
                  color: AppTheme.sage,
                  onTap: () => onAnswer(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnswerBtn(
                  label: 'Tidak ✗',
                  selected: answer == false,
                  color: AppTheme.terra,
                  onTap: () => onAnswer(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _AnswerBtn({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppTheme.divider,
            width: selected ? 2 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? color : AppTheme.grey,
          ),
        ),
      ),
    );
  }
}