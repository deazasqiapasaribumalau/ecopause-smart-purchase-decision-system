// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/auth_provider.dart';
import '../widgets/common_widgets.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  @override void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Email dan password tidak boleh kosong'); return;
    }
    setState(() { _loading = true; _error = null; });
    final auth = AuthProvider();
    final err = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(auth: auth)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 32),
            Center(child: Column(children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(color: AppTheme.forest, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppTheme.forest.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                child: const Center(child: Text('🌿', style: TextStyle(fontSize: 44))),
              ),
              const SizedBox(height: 16),
              Text('EcoPause', style: GoogleFonts.nunito(fontSize: 30, fontWeight: FontWeight.w900, color: AppTheme.forest)),
              Text('Think Before You Buy', style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.grey, fontWeight: FontWeight.w600)),
            ])),
            const SizedBox(height: 44),
            Text('Selamat Datang 👋', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.forest)),
            const SizedBox(height: 4),
            Text('Masuk untuk melanjutkan', style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.grey)),
            const SizedBox(height: 28),
            if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 16)],
            Text('Email', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined, color: AppTheme.sage), hintText: 'email@contoh.com'),
            ),
            const SizedBox(height: 16),
            Text('Password', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
            const SizedBox(height: 6),
            TextField(
              controller: _passCtrl, obscureText: _obscure,
              style: GoogleFonts.nunito(fontSize: 14),
              onSubmitted: (_) => _login(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.sage),
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.grey),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: EcoButton(label: 'Masuk', onTap: _login, loading: _loading, icon: Icons.login_rounded)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Belum punya akun? ', style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.grey)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: Text('Daftar Sekarang', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.sage)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
