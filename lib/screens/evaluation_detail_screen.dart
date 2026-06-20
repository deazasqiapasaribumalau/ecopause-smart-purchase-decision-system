// lib/screens/evaluation_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../widgets/common_widgets.dart';

class EvaluationDetailScreen extends StatelessWidget {
  final FomoEvaluation eval;
  final AuthProvider auth;

  const EvaluationDetailScreen({
    super.key,
    required this.eval,
    required this.auth,
  });

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _fmtP(double p) {
    if (p >= 1e6) return '${(p / 1e6).toStringAsFixed(1)} jt';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)} rb';
    return p.toStringAsFixed(0);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Evaluasi'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            if (eval.imagePath != null && eval.imagePath!.isNotEmpty)
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
                  child: _buildImageWidget(eval.imagePath!),
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
                          eval.itemName,
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
                          color: _decisionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _decisionColor,
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
                  const SizedBox(height: 4),
                  Text(
                    eval.category,
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
                        value: 'Rp ${_fmtP(eval.price)}',
                      ),
                      const SizedBox(width: 16),
                      _detailItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Tanggal',
                        value: _fmtDate(eval.date),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _detailItem(
                        icon: Icons.trending_up_rounded,
                        label: 'Need Score',
                        value: '${eval.needScore}%',
                        color: AppTheme.sage,
                      ),
                      const SizedBox(width: 16),
                      _detailItem(
                        icon: Icons.trending_down_rounded,
                        label: 'FOMO Score',
                        value: '${eval.fomoScore}%',
                        color: AppTheme.terra,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Text(
                    'Need vs FOMO',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: eval.needScore / 100,
                      minHeight: 6,
                      backgroundColor: AppTheme.terra.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        eval.needScore >= 60 ? AppTheme.sage : AppTheme.terra,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _detailItem({
    required IconData icon,
    required String label,
    required String value,
    Color color = AppTheme.sage,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grey,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.forest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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