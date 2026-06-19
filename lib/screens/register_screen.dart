// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  @override void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _pass2Ctrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (_passCtrl.text != _pass2Ctrl.text) { setState(() => _error = 'Password tidak cocok'); return; }
    setState(() { _loading = true; _error = null; });
    final auth = AuthProvider();
    final err = await auth.register(_nameCtrl.text, _emailCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(auth: auth)));
    }
  }

  Widget _label(String t) => Text(t, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: AppTheme.forest, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Buat Akun Baru 🌱', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.forest)),
            const SizedBox(height: 4),
            Text('Bergabung dan mulai belanja lebih bijak', style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.grey)),
            const SizedBox(height: 28),
            if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 16)],
            _label('Nama Lengkap'), const SizedBox(height: 6),
            TextField(controller: _nameCtrl, style: GoogleFonts.nunito(fontSize: 14),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline, color: AppTheme.sage), hintText: 'Nama kamu')),
            const SizedBox(height: 16),
            _label('Email'), const SizedBox(height: 6),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: GoogleFonts.nunito(fontSize: 14),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined, color: AppTheme.sage), hintText: 'email@contoh.com')),
            const SizedBox(height: 16),
            _label('Password'), const SizedBox(height: 6),
            TextField(
              controller: _passCtrl, obscureText: _obscure, style: GoogleFonts.nunito(fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.sage), hintText: 'Minimal 6 karakter',
                suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.grey), onPressed: () => setState(() => _obscure = !_obscure)),
              ),
            ),
            const SizedBox(height: 16),
            _label('Konfirmasi Password'), const SizedBox(height: 6),
            TextField(controller: _pass2Ctrl, obscureText: _obscure, style: GoogleFonts.nunito(fontSize: 14),
              onSubmitted: (_) => _register(),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outlined, color: AppTheme.sage), hintText: 'Ulangi password')),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: EcoButton(label: 'Daftar Sekarang', onTap: _register, loading: _loading, icon: Icons.eco_outlined)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Sudah punya akun? ', style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.grey)),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text('Masuk', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.sage)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
