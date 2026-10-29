import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/session_service.dart';
import 'home_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _isRegister = false;
  bool _obscure = true;
  bool _loading = false;

  // Palet Warna
  // WARNA: palet _cWalnut ().
  static const Color _cWalnut = Color(0xFF302622);
  // WARNA: palet _cOxblood ().
  static const Color _cOxblood = Color(0xFF67343A);
  // WARNA: palet _cTobacco ().
  static const Color _cTobacco = Color(0xFF9A704F);
  // WARNA: palet _cAgedPaper ().
  static const Color _cAgedPaper = Color(0xFFD4BE9D);
  // WARNA: palet _cParchment ().
  static const Color _cParchment = Color(0xFFEDE2CF);
  // WARNA: palet _cCardBg ().
  static const Color _cCardBg = Color(0xFFD8C7B0);
  // WARNA: palet _cTabInactive ().
  static const Color _cTabInactive = Color(0xFFC7B197);

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  void _msg(String s, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s,
          style: GoogleFonts.poppins(
            // WARNA: teks 's'.
            color: _cParchment,
            fontWeight: FontWeight.w500,
          ),
        ),
        // WARNA: latar notifikasi.
        backgroundColor: isError ? _cOxblood : _cWalnut,
        duration: Duration(seconds: isError ? 6 : 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _goHome() {
    if (!mounted) return;
    SessionService.recordActivity();
    SessionService.persistActivity();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  Future<void> _submit() async {
    final username = _u.text.trim();
    final password = _p.text;

    if (username.isEmpty || password.isEmpty) {
      _msg('Harap isi username dan password', isError: true);
      return;
    }

    if (_isRegister && password.length < 6) {
      _msg('Password minimal 6 karakter', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isRegister) {
        final conflict = await AuthService.registrationConflict(username);
        if (conflict != null) {
          _msg(conflict, isError: true);
          return;
        }
        final result = await AuthService.register(username, password);
        if (result.localSuccess) {
          _msg(
            result.cloudSynced
                ? 'Registrasi berhasil! Silakan masuk ke akun Anda.'
                : 'Akun tersimpan di perangkat, tetapi sinkronisasi Supabase gagal: ${result.cloudMessage}',
            isError: !result.cloudSynced,
          );
          setState(() {
            _isRegister = false;
            _p.clear();
          });
        } else {
          _msg('Username sudah dipakai, gunakan username lain', isError: true);
        }
      } else {
        final ok = await AuthService.login(username, password);
        if (ok) {
          _goHome();
        } else {
          _msg('Username atau password salah', isError: true);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bio() async {
    setState(() => _loading = true);
    try {
      if (await AuthService.loginBiometric()) {
        _goHome();
      } else {
        _msg(
          'Biometrik gagal atau belum ada sesi login tersimpan',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // WARNA: latar halaman.
      backgroundColor: _cWalnut,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/library_bg.jpg',
            fit: BoxFit.cover,
            // WARNA: warna komponen.
            errorBuilder: (_, __, ___) => Container(color: _cWalnut),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // WARNA: gradasi komponen ini.
                colors: [
                  Colors.black.withValues(alpha: 0.52),
                  Colors.black.withValues(alpha: 0.32),
                  // WARNA: latar kartu 'RENT\nBOOK'.
                  Colors.black.withValues(alpha: 0.68),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/rentbook_logo.png',
                      height: 85,
                      // WARNA: warna komponen.
                      color: _cParchment,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, __, ___) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            // WARNA: ikon menu_book_rounded.
                            color: _cParchment,
                            size: 42,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'RENT\nBOOK',
                            style: GoogleFonts.poppins(
                              // WARNA: teks 'RENT\nBOOK'.
                              color: _cParchment,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        // WARNA: latar kartu/komponen.
                        color: _cCardBg,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            // WARNA: bayangan kartu.
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 28,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 44,
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              // WARNA: latar kartu/komponen.
                              color: _cTabInactive,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _isRegister = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        // WARNA: latar kartu/komponen.
                                        color: !_isRegister
                                            ? _cOxblood
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: !_isRegister
                                            ? [
                                                BoxShadow(
                                                  // WARNA: bayangan kartu.
                                                  color: Colors.black
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Masuk',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            // WARNA: teks 'Masuk'.
                                            color: !_isRegister
                                                ? _cParchment
                                                : _cWalnut,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _isRegister = true),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        // WARNA: latar kartu/komponen.
                                        color: _isRegister
                                            ? _cOxblood
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: _isRegister
                                            ? [
                                                BoxShadow(
                                                  // WARNA: bayangan kartu.
                                                  color: Colors.black
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Daftar Baru',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            // WARNA: teks 'Daftar Baru'.
                                            color: _isRegister
                                                ? _cParchment
                                                : _cWalnut,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Field Username
                          TextField(
                            controller: _u,
                            style: GoogleFonts.poppins(
                              // WARNA: teks judul/isi pada bagian ini.
                              color: _cWalnut,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            // WARNA: teks judul/isi pada bagian ini.
                            cursorColor: _cOxblood,
                            decoration: InputDecoration(
                              hintText: 'Username',
                              hintStyle: GoogleFonts.poppins(
                                // WARNA: teks judul/isi pada bagian ini.
                                color: _cWalnut.withValues(alpha: 0.6),
                                fontSize: 13.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                // WARNA: teks judul/isi pada bagian ini.
                                color: _cWalnut,
                                size: 21,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              filled: true,
                              // WARNA: warna komponen.
                              fillColor: _cAgedPaper.withValues(alpha: 0.35),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  // WARNA: garis tepi kartu/komponen.
                                  color: _cTobacco,
                                  width: 1.1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  // WARNA: garis tepi kartu/komponen.
                                  color: _cOxblood,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Field Password
                          TextField(
                            controller: _p,
                            obscureText: _obscure,
                            style: GoogleFonts.poppins(
                              // WARNA: teks judul/isi pada bagian ini.
                              color: _cWalnut,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            // WARNA: teks judul/isi pada bagian ini.
                            cursorColor: _cOxblood,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: GoogleFonts.poppins(
                                // WARNA: teks judul/isi pada bagian ini.
                                color: _cWalnut.withValues(alpha: 0.6),
                                fontSize: 13.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                // WARNA: teks judul/isi pada bagian ini.
                                color: _cWalnut,
                                size: 21,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  // WARNA: ikon visibility_outlined.
                                  color: _cWalnut,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              filled: true,
                              // WARNA: warna komponen.
                              fillColor: _cAgedPaper.withValues(alpha: 0.35),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  // WARNA: garis tepi kartu/komponen.
                                  color: _cTobacco,
                                  width: 1.1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  // WARNA: garis tepi kartu/komponen.
                                  color: _cOxblood,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                // WARNA: latar tombol.
                                backgroundColor: _cOxblood,
                                // WARNA: teks/ikon tombol.
                                foregroundColor: _cParchment,
                                elevation: 3,
                                // WARNA: warna komponen.
                                shadowColor: Colors.black26,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        // WARNA: warna komponen.
                                        color: _cParchment,
                                      ),
                                    )
                                  : Text(
                                      _isRegister
                                          ? 'Daftar Akun Baru'
                                          : 'Masuk ke Aplikasi',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  // WARNA: warna komponen.
                                  color: _cTobacco.withValues(alpha: 0.5),
                                  thickness: 0.9,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'atau',
                                  style: GoogleFonts.poppins(
                                    // WARNA: teks 'atau'.
                                    color: _cWalnut.withValues(alpha: 0.7),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  // WARNA: teks 'atau'.
                                  color: _cTobacco.withValues(alpha: 0.5),
                                  thickness: 0.9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Material(
                            // WARNA: warna komponen.
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _loading ? null : _bio,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  // WARNA: garis tepi komponen.
                                  border: Border.all(
                                    // WARNA: garis tepi kartu/komponen.
                                    color: _cTobacco,
                                    width: 1.1,
                                  ),
                                  // WARNA: garis tepi kartu/komponen.
                                  color: _cAgedPaper.withValues(alpha: 0.3),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.fingerprint,
                                      size: 24,
                                      // WARNA: ikon fingerprint.
                                      color: _cWalnut,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Masuk dengan Biometrik',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                        // WARNA: teks 'Masuk dengan Biometrik'.
                                        color: _cWalnut,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
