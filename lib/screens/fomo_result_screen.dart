// lib/screens/fomo_result_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../utils/storage_service.dart';
import '../widgets/common_widgets.dart';
import 'wishlist_screen.dart';

class FomoResultScreen extends StatelessWidget {
  final FomoEvaluation eval;
  final AuthProvider auth;
  const FomoResultScreen({super.key, required this.eval, required this.auth});

  String get _verdict    => eval.decision == 'buy' ? '✅ Layak Dibeli' : eval.decision == 'skip' ? '🚫 Lebih Baik Dilewati' : '⏳ Masuk Wishlist Dulu';
  String get _verdictDesc=> eval.decision == 'buy' ? 'Kebutuhan kamu terhadap barang ini cukup kuat dan rasional. Tetap pertimbangkan dampak lingkungan ya!'
      : eval.decision == 'skip' ? 'Sepertinya pembelian ini didorong lebih banyak oleh FOMO daripada kebutuhan nyata. Coba tunda dan lihat besok apakah masih mau beli.'
      : 'Skor kamu berada di zona abu-abu. Masukkan ke wishlist dengan cooling period untuk memastikan kamu benar-benar butuh.';
  Color get _verdictColor => eval.decision == 'buy' ? AppTheme.forestMid : eval.decision == 'skip' ? AppTheme.terra : AppTheme.sand;

  List<String> get _ecoAlts => ecoAlternatives[eval.category] ?? ecoAlternatives['Lainnya']!;
  String? get _borrowAdvice => borrowSuggestions[eval.category];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: const Text('Hasil Evaluasi'), backgroundColor: AppTheme.forest),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Item header
          EcoCard(child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(eval.itemName, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.forest)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [EcoChip(label: eval.category), EcoChip(label: 'Rp ${_fmtP(eval.price)}', color: AppTheme.forestMid)]),
              ])),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ScoreRing(score: eval.needScore, label: 'Need Score', color: AppTheme.needColor(eval.needScore)),
              Container(width: 1, height: 80, color: AppTheme.divider),
              ScoreRing(score: eval.fomoScore, label: 'FOMO Score', color: AppTheme.fomoColor(eval.fomoScore)),
            ]),
          ])),
          const SizedBox(height: 16),

          // Verdict
          Container(
            width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: _verdictColor.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: _verdictColor.withOpacity(0.4), width: 2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_verdict, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: _verdictColor)),
              const SizedBox(height: 8),
              Text(_verdictDesc, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.ink, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 16),

          // Buy or Borrow
          if (_borrowAdvice != null) ...[
            EcoCard(borderColor: AppTheme.sky.withOpacity(0.6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Buy or Borrow?', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.forest)),
                const SizedBox(height: 4),
                Text(_borrowAdvice!, style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.ink, height: 1.5)),
              ])),
            ])),
            const SizedBox(height: 16),
          ],

          // Eco Alternatives
          EcoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🌿 Alternatif Ramah Lingkungan', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.forest)),
            const SizedBox(height: 12),
            ..._ecoAlts.map((alt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(alt, style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.ink, height: 1.4)),
            )),
          ])),
          const SizedBox(height: 24),

          if (eval.decision != 'buy') ...[
            SizedBox(width: double.infinity, child: EcoButton(label: '⏳ Tambah ke Wishlist', onTap: () => _addToWishlist(context), icon: Icons.bookmark_add_outlined)),
            const SizedBox(height: 10),
          ],
          SizedBox(width: double.infinity, child: EcoButton(label: 'Kembali ke Beranda', onTap: () => Navigator.of(context).popUntil((r) => r.isFirst), outline: true)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  String _fmtP(double p) { if (p >= 1e6) return '${(p/1e6).toStringAsFixed(1)} jt'; if (p >= 1000) return '${(p/1000).toStringAsFixed(0)} rb'; return p.toStringAsFixed(0); }

  void _addToWishlist(BuildContext context) async {
    int? cooling = await showDialog<int>(context: context, builder: (_) => _CoolingDialog());
    if (cooling == null) return;
    final item = WishlistItem(
      id: const Uuid().v4(), userId: auth.user!.id,
      itemName: eval.itemName, category: eval.category,
      price: eval.price, addedAt: DateTime.now(), coolingDays: cooling,
    );
    await StorageService.addToWishlist(item);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${eval.itemName} ditambahkan ke wishlist ($cooling hari cooling)'),
        backgroundColor: AppTheme.forestMid,
      ));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => WishlistScreen(auth: auth)), (r) => r.isFirst);
    }
  }
}

class _CoolingDialog extends StatefulWidget {
  @override State<_CoolingDialog> createState() => _CoolingDialogState();
}
class _CoolingDialogState extends State<_CoolingDialog> {
  int _sel = 3;
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text('⏳ Pilih Cooling Period', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppTheme.forest)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Tunggu beberapa hari sebelum memutuskan — ini membantu mengurangi pembelian impulsif.', style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.ink)),
      const SizedBox(height: 16),
      ...[
        [1, '1 Hari', 'Pemikiran singkat'],
        [3, '3 Hari', 'Cooling standar'],
        [7, '7 Hari', 'Keputusan matang'],
      ].map((d) => RadioListTile<int>(
        value: d[0] as int, groupValue: _sel, activeColor: AppTheme.sage,
        onChanged: (v) => setState(() => _sel = v!),
        title: Text('${d[1]} — ${d[2]}', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600)),
      )),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: GoogleFonts.nunito(color: AppTheme.grey))),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sage, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: () => Navigator.pop(context, _sel),
        child: Text('Konfirmasi', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppTheme.white)),
      ),
    ],
  );
}
