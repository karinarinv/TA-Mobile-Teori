// ============================================================================
// FITUR REGISTRASI & LOGIN (HALAMAN OTENTIKASI PENGGUNA)
// ----------------------------------------------------------------------------
// Logika Presentasi:
// 1. Dual-Mode Form: Satu halaman dapat beralih antara Mode Masuk (Login) dan
//    Mode Buat Akun (Registrasi) melalui toggle state `_isRegister`.
// 2. Validasi Input: Memastikan username & password tidak kosong, serta password
//    minimal 6 karakter pada mode registrasi sebelum dikirim ke AuthService.
// 3. Alur Registrasi:
//    - Cek bentrok username di SQLite & Supabase via AuthService.registrationConflict().
//    - Password di-hash dengan Salt (SHA-256) sebelum disimpan ke SQLite lokal.
//    - Sinkronisasi instan ke cloud database Supabase.
// 4. Alur Login:
//    - Verifikasi kredensial: mencocokkan hash password yang dimasukkan dengan hash di database.
//    - Jika cocok, buat sesi login dan arahkan pengguna ke Beranda (HomeShell).
// 5. Login Biometrik (Fingerprint / Face ID):
//    - Menggunakan sensor biometrik perangkat via `AuthService.loginBiometric()`.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/session_service.dart';
import 'home_shell.dart';

/// Menangani formulir registrasi, login lokal, dan pilihan login biometrik.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller membaca username dan password dari form.
  final _u = TextEditingController();
  final _p = TextEditingController();
  // Mode form: false untuk masuk, true untuk membuat akun.
  bool _isRegister = false;
  // Mengatur apakah isi password disembunyikan dengan titik.
  bool _obscure = true;
  // Menonaktifkan tombol dan menampilkan indikator selama autentikasi.
  bool _loading = false;

  // Palet Warna
  // WARNA: palet lokal _cWalnut — cokelat gelap untuk latar fallback halaman login, teks tab tidak aktif, dan teks input form.
  static const Color _cWalnut = Color(0xFF302622);
  // WARNA: palet lokal _cOxblood — merah marun untuk tab aktif ('Masuk'/'Daftar Baru'), tombol utama submit, garis fokus input, dan SnackBar error.
  static const Color _cOxblood = Color(0xFF67343A);
  // WARNA: palet lokal _cTobacco — cokelat sedang untuk garis tepi (border) kolom input Username & Password saat tidak fokus.
  static const Color _cTobacco = Color(0xFF9A704F);
  // WARNA: palet lokal _cAgedPaper — krem tua untuk latar tipis kolom isian (fillColor) Username & Password.
  static const Color _cAgedPaper = Color(0xFFD4BE9D);
  // WARNA: palet lokal _cParchment — krem cerah untuk logo RentBook, teks tab aktif, teks tombol utama, dan teks SnackBar.
  static const Color _cParchment = Color(0xFFEDE2CF);
  // WARNA: palet lokal _cCardBg — krem hangat untuk latar belakang kartu utama formulir Login/Daftar di tengah layar.
  static const Color _cCardBg = Color(0xFFD8C7B0);
  // WARNA: palet lokal _cTabInactive — cokelat muda untuk latar lintasan (track) switcher tab 'Masuk' / 'Daftar Baru'.
  static const Color _cTabInactive = Color(0xFFC7B197);

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  void _msg(String s, {bool isError = false}) {
    // SnackBar pesan error tampil 6 detik; pesan biasa tampil 2 detik.
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s,
          style: GoogleFonts.poppins(
            // WARNA: warna teks pesan di dalam SnackBar halaman login/registrasi.
            color: _cParchment,
            fontWeight: FontWeight.w500,
          ),
        ),
        // WARNA: latar belakang SnackBar halaman login (marun oxblood saat error, cokelat walnut saat info/sukses).
        backgroundColor: isError ? _cOxblood : _cWalnut,
        duration: Duration(seconds: isError ? 6 : 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _goHome() {
    // Ganti halaman login dengan kerangka navigasi setelah autentikasi berhasil.
    if (!mounted) return;
    SessionService.recordActivity();
    SessionService.persistActivity();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  // =========================================================================
  // LOGIKA 1: SUBMIT FORM (REGISTRASI ATAU LOGIN)
  // =========================================================================
  // Alur Kerja:
  // 1. Validasi teks username dan password.
  // 2. Jika mode registrasi (_isRegister == true):
  //    - Cek apakah username sudah dipakai di database lokal/cloud.
  //    - Panggil AuthService.register(): enkripsi password & simpan ke SQLite + Supabase.
  //    - Jika sukses, arahkan user ke mode login.
  // 3. Jika mode login (_isRegister == false):
  //    - Panggil AuthService.login(): cocokkan hash password dan buat sesi.
  //    - Jika cocok, navigasi ke Beranda via _goHome().
  Future<void> _submit() async {
    // Validasi input, lalu jalankan cabang registrasi atau login.
    final username = _u.text.trim();
    // Password tidak di-trim supaya spasi yang diketik pengguna tetap dihitung.
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
        // Cek bentrok lebih dulu agar pengguna mendapat pesan yang jelas.
        final conflict = await AuthService.registrationConflict(username);
        if (conflict != null) {
          _msg(conflict, isError: true);
          return;
        }
        final result = await AuthService.register(username, password);
        // Registrasi lokal tetap berhasil meski sinkronisasi cloud gagal.
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
        // Login memeriksa hash password lokal dan membuat sesi jika cocok.
        final ok = await AuthService.login(username, password);
        if (ok) {
          _goHome();
        } else {
          _msg('Username atau password salah', isError: true);
        }
      }
    } finally {
      // Pastikan spinner berhenti juga saat operasi melempar error atau gagal.
      if (mounted) setState(() => _loading = false);
    }
  }

  // =========================================================================
  // LOGIKA SUBMIT FORM (LOGIN / REGISTER)
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // WARNA: latar belakang dasar halaman Login/Registrasi (terlihat jika gambar library_bg belum termuat).
      backgroundColor: _cWalnut,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/library_bg.jpg',
            fit: BoxFit.cover,
            // WARNA: warna fallback jika file gambar latar belakang library_bg.jpg gagal dimuat.
            errorBuilder: (_, __, ___) => Container(color: _cWalnut),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // WARNA: gradasi lapisan gelap (overlay) di atas foto perpustakaan agar logo dan kartu form login lebih kontras.
                colors: [
                  Colors.black.withValues(alpha: 0.52),
                  Colors.black.withValues(alpha: 0.32),
                  // WARNA: bagian bawah gradasi gelap (overlay) di atas foto latar belakang halaman login.
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
                      // WARNA: warna tint logo gambar RentBook di atas kartu form login.
                      color: _cParchment,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, __, ___) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            // WARNA: ikon buku fallback jika gambar rentbook_logo.png gagal dimuat di halaman login.
                            color: _cParchment,
                            size: 42,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'RENT\nBOOK',
                            style: GoogleFonts.poppins(
                              // WARNA: teks fallback 'RENT\nBOOK' jika gambar logo gagal dimuat di halaman login.
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
                        // WARNA: latar belakang kartu utama formulir Login / Daftar Baru di tengah layar.
                        color: _cCardBg,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            // WARNA: bayangan di bawah kartu utama formulir Login / Daftar Baru.
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
                              // WARNA: latar lintasan wadah switcher dua tab ('Masuk' dan 'Daftar Baru') di dalam kartu login.
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
                                        // WARNA: latar tombol tab 'Masuk' (marun oxblood saat aktif, transparan saat mode Daftar Baru).
                                        color: !_isRegister
                                            ? _cOxblood
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: !_isRegister
                                            ? [
                                                BoxShadow(
                                                  // WARNA: bayangan pil tab 'Masuk' saat sedang aktif.
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
                                            // WARNA: warna teks tab 'Masuk' (krem parchment saat aktif, cokelat walnut saat nonaktif).
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
                                        // WARNA: latar tombol tab 'Daftar Baru' (marun oxblood saat aktif, transparan saat mode Masuk).
                                        color: _isRegister
                                            ? _cOxblood
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: _isRegister
                                            ? [
                                                BoxShadow(
                                                  // WARNA: bayangan pil tab 'Daftar Baru' saat sedang aktif.
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
                                            // WARNA: warna teks tab 'Daftar Baru' (krem parchment saat aktif, cokelat walnut saat nonaktif).
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
                              // WARNA: warna teks ketikan pengguna di dalam kolom input Username.
                              color: _cWalnut,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            // WARNA: warna kursor ketik di kolom input Username.
                            cursorColor: _cOxblood,
                            decoration: InputDecoration(
                              hintText: 'Username',
                              hintStyle: GoogleFonts.poppins(
                                // WARNA: warna teks placeholder 'Username' saat kolom kosong.
                                color: _cWalnut.withValues(alpha: 0.6),
                                fontSize: 13.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                // WARNA: warna ikon orang di sebelah kiri kolom input Username.
                                color: _cWalnut,
                                size: 21,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              filled: true,
                              // WARNA: warna latar dalam (fill) kotak input Username.
                              fillColor: _cAgedPaper.withValues(alpha: 0.35),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  // WARNA: warna garis tepi kotak input Username saat tidak sedang diklik/fokus.
                                  color: _cTobacco,
                                  width: 1.1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  // WARNA: warna garis tepi kotak input Username saat sedang aktif/fokus diketik.
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
                              // WARNA: warna teks ketikan pengguna di dalam kolom input Password.
                              color: _cWalnut,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            // WARNA: warna kursor ketik di kolom input Password.
                            cursorColor: _cOxblood,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: GoogleFonts.poppins(
                                // WARNA: warna teks placeholder 'Password' saat kolom kosong.
                                color: _cWalnut.withValues(alpha: 0.6),
                                fontSize: 13.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                // WARNA: warna ikon gembok di sebelah kiri kolom input Password.
                                color: _cWalnut,
                                size: 21,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  // WARNA: warna ikon mata (lihat/sembunyikan password) di kanan kolom Password.
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
                              // WARNA: warna latar dalam (fill) kotak input Password.
                              fillColor: _cAgedPaper.withValues(alpha: 0.35),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  // WARNA: warna garis tepi kotak input Password saat tidak sedang diklik/fokus.
                                  color: _cTobacco,
                                  width: 1.1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  // WARNA: warna garis tepi kotak input Password saat sedang aktif/fokus diketik.
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
                                // WARNA: latar belakang tombol utama submit ('Masuk ke Aplikasi' / 'Daftar Akun Baru').
                                backgroundColor: _cOxblood,
                                // WARNA: warna teks dan efek ripple tombol utama submit login/registrasi.
                                foregroundColor: _cParchment,
                                elevation: 3,
                                // WARNA: warna bayangan di bawah tombol utama submit login/registrasi.
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
                                        // WARNA: warna spinner loading di dalam tombol submit saat proses login/daftar berjalan.
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
