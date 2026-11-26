// ============================================================================
// FITUR PROFILE (MANAJEMEN AKUN & KEANGGOTAAN USER)
// ----------------------------------------------------------------------------
// Logika Presentasi:
// 1. Data Agregasi Akun:
//    - Mengambil data sesi pengguna aktif (AuthService.currentSession()).
//    - Membaca foto profil & timestamp ganti nama dari database lokal SQLite 'users'.
//    - Menghitung statistik buku favorit (BookmarkService) & riwayat transaksi sewa dari SQLite.
// 2. Cooldown Pergantian Username (30 Hari):
//    - Mencegah spam pergantian username dengan membatasi perubahan hanya boleh
//      dilakukan sekali setiap 30 hari (AuthService.usernameChangeCooldown).
// 3. Foto Profil Interaktif:
//    - Memilih gambar dari Kamera atau Galeri via ImagePicker.
//    - Menyimpan path file lokal ke SQLite sehingga foto tetap tersimpan saat app dibuka lagi.
// 4. Logout Aman:
//    - Menghapus sesi login di AuthService dan mereset stack navigasi ke LoginPage.
// ============================================================================

import 'package:google_fonts/google_fonts.dart';


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/db_helper.dart';
import '../services/bookmark_service.dart';
import 'saved_books_page.dart';
import 'rental_history_page.dart';
import '../widgets/rental_bottom_sheet.dart';
import 'login_page.dart';

/// Ringkasan akun: profil lokal, bookmark, riwayat sewa, dan membership.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Ringkasan akun yang dimuat untuk menampilkan profil dan status keanggotaan.
  String? _username, _photo;
  DateTime? _usernameChangeAvailableAt;
  int _savedCount = 0;
  int _rentalCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    RentalBottomSheet.rentalUpdateNotifier.addListener(_load);
  }

  @override
  void dispose() {
    RentalBottomSheet.rentalUpdateNotifier.removeListener(_load);
    super.dispose();
  }

  // =========================================================================
  // LOGIKA 1: MEMUAT DATA LENGKAP PROFIL & STATUS VIP
  // =========================================================================
  // 1. Ambil username sesi aktif dari AuthService.
  // 2. Query SQLite 'users': ambil path foto dan cek apakah cooldown 30 hari masih aktif.
  // 3. Hitung jumlah buku tersimpan (bookmarks) dan transaksi sewa (rentals).
  // 4. Sinkronkan status VIP (SubscriptionService.isVip()) beserta masa aktifnya.
  Future<void> _load() async {
    // Baca identitas, jumlah bookmark/sewa, dan status VIP dari penyimpanan.
    // Gabungkan data akun SQLite, bookmark lokal, transaksi, dan status VIP.
    final username = await AuthService.currentSession();
    String? photo;
    DateTime? usernameChangeAvailableAt;
    final rows = username == null
        ? <Map<String, Object?>>[]
        : await (await DbHelper.db).query(
            'users',
            where: 'username=?',
            whereArgs: [username],
          );
    if (rows.isNotEmpty) {
      photo = rows.first['photo'] as String?;
      final lastUsernameChange = DateTime.tryParse(
        rows.first['username_changed_at'] as String? ?? '',
      );
      final nextUsernameChange = lastUsernameChange?.add(
        AuthService.usernameChangeCooldown,
      );
      if (nextUsernameChange != null &&
          DateTime.now().isBefore(nextUsernameChange)) {
        usernameChangeAvailableAt = nextUsernameChange;
      }
    }

    final bookmarks = await BookmarkService.getBookmarks();
    int rentalCount = 0;
    try {
      final db = await DbHelper.db;
      final currentUser = username ?? await AuthService.currentSession();
      List<Map<String, Object?>> rows;
      if (currentUser != null && currentUser.isNotEmpty) {
        rows = await db.query(
          'riwayat_transaksi',
          where: 'username=?',
          whereArgs: [currentUser],
        );
      } else {
        rows = await db.query('riwayat_transaksi');
      }
      rentalCount = rows.length;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _username = username;
        _photo = photo;
        _usernameChangeAvailableAt = usernameChangeAvailableAt;
        _savedCount = bookmarks.length;
        _rentalCount = rentalCount;
        _loading = false;
      });
    }
  }

  // =========================================================================
  // LOGIKA 2: UBAH FOTO PROFIL (IMAGE PICKER & SQLITE UPDATE)
  // =========================================================================
  // Mengambil gambar dari ImageSource.camera atau ImageSource.gallery,
  // lalu memperbarui path file di kolom 'photo' tabel 'users' SQLite lokal.
  Future<void> _pickImage(ImageSource source) async {
    // Ambil gambar dari sumber yang dipilih dan simpan sebagai foto profil lokal.
    // Pilih foto profil dan simpan path file pada baris akun SQLite.
    final f = await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (f == null || _username == null) return;
    await (await DbHelper.db).update(
      'users',
      {'photo': f.path},
      where: 'username=?',
      whereArgs: [_username],
    );
    _load();
  }

  // =========================================================================
  // LOGIKA 3: PERGANTIAN USERNAME DENGAN ATURAN COOLDOWN 30 HARI
  // =========================================================================
  // Membuka form nama baru, memvalidasi aturan karakter, lalu memanggil
  // AuthService.changeUsername() yang memperbarui database lokal & cloud.
  Future<void> _changeUsername() async {
    // Minta username baru; service memvalidasi format dan masa tunggu 30 hari.
    // Buka formulir nama; AuthService menerapkan validasi dan jeda 30 hari.
    final currentUsername = _username;
    if (currentUsername == null) return;

    final requestedUsername = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      // WARNA: latar pembungkus modal bottom sheet Ganti Username dibuat transparan agar sudut melengkung kartu modal terlihat.
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangeUsernameModal(
        initialUsername: currentUsername,
        availableAt: _usernameChangeAvailableAt,
      ),
    );

    if (requestedUsername == null || !mounted) return;

    try {
      final result = await AuthService.changeUsername(requestedUsername);
      if (result.success) await _load();
      if (!mounted) return;
      final message = result.availableAt == null
          ? result.message
          : '${result.message} Bisa diganti lagi ${DateFormat('dd MMM yyyy', 'id_ID').format(result.availableAt!)}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 7),
          content: Text(
            result.cloudSyncDetails.isEmpty
                ? message
                : '$message\n${result.cloudSyncDetails}',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username gagal diperbarui.')),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    // Tampilkan pilihan kamera atau galeri untuk foto profil.
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  // WARNA: warna garis pegangan (handle bar) abu-abu di bagian atas bottom sheet 'Ganti Foto Profil'.
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ganti Foto Profil',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // WARNA: latar kotak ikon 'Ambil dari Kamera' di bottom sheet Ganti Foto Profil.
                    color: const Color(0xFFEDE2CF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // WARNA: warna ikon kamera pada pilihan 'Ambil dari Kamera' di bottom sheet Ganti Foto Profil.
                  child: const Icon(Icons.camera_alt, color: Color(0xFF67343A)),
                ),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // WARNA: latar kotak ikon 'Pilih dari Galeri' di bottom sheet Ganti Foto Profil.
                    color: const Color(0xFFEDE2CF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    // WARNA: warna ikon galeri foto pada pilihan 'Pilih dari Galeri' di bottom sheet Ganti Foto Profil.
                    color: Color(0xFF67343A),
                  ),
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // LOGIKA 4: PROSES LOGOUT & PEMBERSIHAN SESI PENGGUNA
  // =========================================================================
  // 1. Munculkan modal dialog konfirmasi keluar akun.
  // 2. Jika disetujui (yes == true), panggil AuthService.logout().
  // 3. Arahkan pengguna kembali ke halaman LoginPage dengan menghapus semua rute lama.
  Future<void> _logout() async {
    // Keluar menghapus sesi aktif lalu mengganti halaman ke form login.
    // Minta konfirmasi; jika setuju, hapus sesi dan kembali ke login.
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        // WARNA: latar belakang kotak dialog 'Konfirmasi Keluar' di halaman Profil.
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          // WARNA: garis tepi kotak dialog 'Konfirmasi Keluar' di halaman Profil.
          side: const BorderSide(color: Color(0xFFEADBCE), width: 1.2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // WARNA: latar lingkaran ikon logout di bagian atas dialog 'Konfirmasi Keluar'.
                color: const Color(0xFF67343A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  // WARNA: garis tepi lingkaran ikon logout di bagian atas dialog 'Konfirmasi Keluar'.
                  color: const Color(0xFF67343A).withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                // WARNA: warna ikon logout di dalam lingkaran atas dialog 'Konfirmasi Keluar'.
                color: Color(0xFF67343A),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Konfirmasi Keluar',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                // WARNA: warna teks judul 'Konfirmasi Keluar' pada dialog logout.
                color: const Color(0xFF302622),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Anda? Sesi login Anda akan diakhiri dengan aman.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            // WARNA: warna teks pesan pertanyaan konfirmasi pada dialog logout.
            color: const Color(0xFF6B564A),
            height: 1.45,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    // WARNA: warna teks tombol 'Batal' di kiri bawah dialog 'Konfirmasi Keluar'.
                    foregroundColor: const Color(0xFF302622),
                    side: const BorderSide(
                      // WARNA: garis tepi tombol 'Batal' di kiri bawah dialog 'Konfirmasi Keluar'.
                      color: Color(0xFFEADBCE),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      // WARNA: warna teks label 'Batal' di dalam tombol batal dialog logout.
                      color: const Color(0xFF302622),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    // WARNA: latar belakang tombol 'Keluar' di kanan bawah dialog 'Konfirmasi Keluar'.
                    backgroundColor: const Color(0xFF67343A),
                    // WARNA: warna ripple/teks tombol 'Keluar' di kanan bawah dialog 'Konfirmasi Keluar'.
                    foregroundColor: const Color(0xFFEDE2CF),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(
                    'Keluar',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      // WARNA: warna teks label 'Keluar' di dalam tombol konfirmasi logout.
                      color: const Color(0xFFEDE2CF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (yes == true) {
      // 1. Bersihkan session_user dan session_last_active_ms di SharedPreferences
      await AuthService.logout();
      if (!mounted) return;
      // 2. Navigasi ke LoginPage sambil menghapus seluruh riwayat stack rute (route => false)
      //    agar setelah keluar, tombol 'Back' fisik perangkat tidak dapat masuk kembali.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // WARNA: latar belakang utama halaman Profil Pengguna.
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text(
          'Profil Pengguna',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        elevation: 0,
        // WARNA: latar belakang AppBar halaman Profil Pengguna.
        backgroundColor: const Color(0xFF67343A),
        // WARNA: warna teks judul 'Profil Pengguna' pada AppBar.
        foregroundColor: const Color(0xFFEDE2CF),
        actions: [
          IconButton(
            // WARNA: warna ikon segarkan (refresh) di pojok kanan atas AppBar halaman Profil Pengguna.
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFEDE2CF)),
            tooltip: 'Segarkan',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              // WARNA: warna spinner loading saat memuat data profil dari SQLite.
              child: CircularProgressIndicator(color: Color(0xFF67343A)),
            )
          : RefreshIndicator(
              // WARNA: warna panah indikator tarik-untuk-refresh pada halaman Profil Pengguna.
              color: const Color(0xFF67343A),
              // WARNA: warna latar lingkaran indikator tarik-untuk-refresh pada halaman Profil Pengguna.
              backgroundColor: const Color(0xFFEDE2CF),
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                child: Column(
                  children: [
                    // 1. KARTU HEADER PROFIL PENGGUNA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        // WARNA: latar belakang kartu atas profil (tempat foto profil, username, dan lencana anggota) — putih.
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          // WARNA: garis tepi kartu header profil bagian atas.
                          color: const Color(0xFFEADBCE),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            // WARNA: bayangan tipis di bawah kartu header profil bagian atas.
                            color: const Color(0xFF302622)
                                .withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Foto Profil dengan Double Ring Elegan
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: _showImagePickerSheet,
                                  child: Container(
                                    padding: const EdgeInsets.all(3.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        // WARNA: gradasi bingkai cincin melingkar di sekeliling foto profil (marun -> cokelat -> krem emas).
                                        colors: const [
                                            Color(0xFF67343A),
                                            Color(0xFF9A704F),
                                            Color(0xFFD4BE9D),
                                          ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          // WARNA: bayangan di bawah lingkaran foto profil pengguna.
                                          color: const Color(0xFF302622)
                                              .withValues(alpha: 0.16),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      // WARNA: latar lingkaran avatar foto profil (terlihat saat user belum mengatur foto).
                                      backgroundColor: const Color(0xFFEDE2CF),
                                      backgroundImage: _photo != null
                                          ? FileImage(File(_photo!))
                                          : null,
                                      child: _photo == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 52,
                                              // WARNA: warna ikon orang default di dalam avatar foto profil (saat belum ada foto).
                                              color: Color(0xFF67343A),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _showImagePickerSheet,
                                    child: Container(
                                      padding: const EdgeInsets.all(7.5),
                                      decoration: BoxDecoration(
                                        // WARNA: latar lingkaran kecil tombol kamera di pojok kanan bawah foto profil.
                                        color: const Color(0xFF67343A),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          // WARNA: garis tepi putih melingkari tombol kamera kecil pada foto profil.
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            // WARNA: bayangan kecil di bawah tombol kamera pada foto profil.
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 15,
                                        // WARNA: warna ikon kamera kecil di pojok kanan bawah foto profil.
                                        color: Color(0xFFEDE2CF),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Nama Pengguna
                          SizedBox(
                            width: double.infinity,
                            child: Center(
                              child: Transform.translate(
                                // Keep the username centered while placing the pencil beside it.
                                offset: const Offset(17, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _username ?? 'Pengguna',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        // WARNA: warna teks nama pengguna (username) di bawah foto profil.
                                        color: const Color(0xFF302622),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip:
                                          _usernameChangeAvailableAt == null
                                          ? 'Ganti username'
                                          : 'Bisa diganti lagi ${DateFormat('dd MMM yyyy', 'id_ID').format(_usernameChangeAvailableAt!)}',
                                      onPressed: _changeUsername,
                                      visualDensity: VisualDensity.compact,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 34,
                                            height: 34,
                                          ),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                        // WARNA: warna ikon pensil tombol edit username di sebelah kanan nama pengguna.
                                        color: const Color(0xFF9A704F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Badge Status Keanggotaan Sesuai Color Palette
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              // WARNA: latar belakang pil lencana 'ANGGOTA PERPUSTAKAAN' di kartu header profil.
                              color: const Color(0xFFEDE2CF),
                              borderRadius: BorderRadius.circular(20),
                              // WARNA: garis tepi pil lencana 'ANGGOTA PERPUSTAKAAN' di kartu header profil.
                              border: Border.all(
                                color: const Color(0xFF9A704F).withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // WARNA: warna ikon perisai centang di dalam pil lencana 'ANGGOTA PERPUSTAKAAN'.
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 14,
                                  color: Color(0xFF67343A),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'ANGGOTA PERPUSTAKAAN',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    // WARNA: warna teks 'ANGGOTA PERPUSTAKAAN' di dalam pil lencana profil.
                                    color: const Color(0xFF67343A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. KARTU MENU NAVIGASI & PENGATURAN AKUN
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        // WARNA: latar belakang kartu menu 'PENGATURAN & AKUN' di halaman Profil (putih).
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          // WARNA: garis tepi luar kartu menu 'PENGATURAN & AKUN' di halaman Profil.
                          color: const Color(0xFFEADBCE),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            // WARNA: bayangan tipis di bawah kartu menu 'PENGATURAN & AKUN' di halaman Profil.
                            color: const Color(0xFF302622)
                                .withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                            child: Text(
                              'PENGATURAN & AKUN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                // WARNA: warna teks judul seksi 'PENGATURAN & AKUN' di bagian atas kartu menu Profil.
                                color: const Color(0xFF9A704F),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                // WARNA: latar kotak kecil ikon baris menu 'Buku Tersimpan' di kartu Pengaturan & Akun.
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  // WARNA: garis tepi kotak kecil ikon baris menu 'Buku Tersimpan' di kartu Pengaturan & Akun.
                                  color: const Color(0xFFEADBCE),
                                ),
                              ),
                              child: const Icon(
                                Icons.collections_bookmark_rounded,
                                // WARNA: warna ikon bookmark di dalam kotak kecil baris menu 'Buku Tersimpan'.
                                color: Color(0xFF67343A),
                                size: 19,
                              ),
                            ),
                            title: Text(
                              'Buku Tersimpan',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                // WARNA: warna teks judul baris menu 'Buku Tersimpan' di kartu Pengaturan & Akun.
                                color: const Color(0xFF302622),
                              ),
                            ),
                            subtitle: Text(
                              '$_savedCount buku favorit tersimpan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                // WARNA: warna subteks jumlah buku favorit di bawah judul baris menu 'Buku Tersimpan'.
                                color: const Color(0xFF6B564A),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              // WARNA: warna ikon panah kanan (>) di ujung baris menu 'Buku Tersimpan'.
                              color: Color(0xFF9A704F),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SavedBooksPage(),
                                ),
                              );
                              _load();
                            },
                          ),
                          // WARNA: warna garis pembatas horizontal antara baris menu 'Buku Tersimpan' dan 'Riwayat Peminjaman'.
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Color(0xFFEADBCE),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                // WARNA: latar kotak kecil ikon baris menu 'Riwayat Peminjaman' di kartu Pengaturan & Akun.
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(10),
                                // WARNA: garis tepi kotak kecil ikon baris menu 'Riwayat Peminjaman'.
                                border: Border.all(
                                  color: const Color(0xFFEADBCE),
                                ),
                              ),
                              // WARNA: warna ikon struk di dalam kotak kecil baris menu 'Riwayat Peminjaman'.
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFF67343A),
                                size: 19,
                              ),
                            ),
                            title: Text(
                              'Riwayat Peminjaman',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                // WARNA: warna teks judul baris menu 'Riwayat Peminjaman' di kartu Pengaturan & Akun.
                                color: const Color(0xFF302622),
                              ),
                            ),
                            subtitle: Text(
                              '$_rentalCount riwayat transaksi sewa buku',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                // WARNA: warna subteks jumlah transaksi sewa di bawah judul baris menu 'Riwayat Peminjaman'.
                                color: const Color(0xFF6B564A),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              // WARNA: warna ikon panah kanan (>) di ujung baris menu 'Riwayat Peminjaman'.
                              color: Color(0xFF9A704F),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RentalHistoryPage(),
                                ),
                              );
                              _load();
                            },
                          ),
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            // WARNA: warna garis pembatas horizontal antara baris menu 'Riwayat Peminjaman' dan 'Perbarui Foto Profil'.
                            color: Color(0xFFEADBCE),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                // WARNA: latar kotak kecil ikon baris menu 'Perbarui Foto Profil' di kartu Pengaturan & Akun.
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  // WARNA: garis tepi kotak kecil ikon baris menu 'Perbarui Foto Profil'.
                                  color: const Color(0xFFEADBCE),
                                ),
                              ),
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                // WARNA: warna ikon tambah foto di dalam kotak kecil baris menu 'Perbarui Foto Profil'.
                                color: Color(0xFF67343A),
                                size: 19,
                              ),
                            ),
                            title: Text(
                              'Perbarui Foto Profil',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                // WARNA: warna teks judul baris menu 'Perbarui Foto Profil' di kartu Pengaturan & Akun.
                                color: const Color(0xFF302622),
                              ),
                            ),
                            subtitle: Text(
                              'Pilih foto baru dari kamera atau galeri ponsel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                // WARNA: warna subteks deskripsi di bawah judul baris menu 'Perbarui Foto Profil'.
                                color: const Color(0xFF6B564A),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              // WARNA: warna ikon panah kanan (>) di ujung baris menu 'Perbarui Foto Profil'.
                              color: Color(0xFF9A704F),
                            ),
                            onTap: _showImagePickerSheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 5. TOMBOL LOGOUT ELEGAN
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          // WARNA: warna ikon logout dan ripple tombol 'Keluar dari Akun' di bagian bawah halaman Profil.
                          foregroundColor: const Color(0xFF67343A),
                          // WARNA: latar belakang tombol 'Keluar dari Akun' di halaman Profil (putih).
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            // WARNA: garis tepi tombol 'Keluar dari Akun' di halaman Profil (marun oxblood).
                            color: Color(0xFF67343A),
                            width: 1.4,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, size: 19),
                        label: Text(
                          'Keluar dari Akun',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            // WARNA: warna teks 'Keluar dari Akun' di dalam tombol logout halaman Profil.
                            color: const Color(0xFF67343A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 6. INFO KEAMANAN & VERSI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 14,
                          // WARNA: warna ikon perisai footer keamanan SHA-256 di bagian paling bawah halaman Profil.
                          color: Color(0xFF9A704F),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'RentBook • Keamanan SHA-256 Terenkripsi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            // WARNA: warna teks footer 'RentBook • Keamanan SHA-256 Terenkripsi' di bawah tombol Keluar.
                            color: const Color(0xFF9A704F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ChangeUsernameModal extends StatefulWidget {
  final String initialUsername;
  final DateTime? availableAt;

  const _ChangeUsernameModal({
    required this.initialUsername,
    required this.availableAt,
  });

  @override
  State<_ChangeUsernameModal> createState() => _ChangeUsernameModalState();
}

class _ChangeUsernameModalState extends State<_ChangeUsernameModal> {
  late final TextEditingController _controller;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
    _controller.addListener(_validate);
  }

  void _validate() {
    final text = _controller.text.trim();
    final isValid = text.isNotEmpty &&
        text != widget.initialUsername &&
        text.length >= 3 &&
        text.length <= 20;
    if (isValid != _canSubmit) {
      setState(() => _canSubmit = isValid);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_validate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.availableAt != null;
    const walnut = Color(0xFF302622);
    const oxblood = Color(0xFF67343A);
    const parchment = Color(0xFFEDE2CF);
    const surfaceBg = Color(0xFFFAF7F2);
    const borderColor = Color(0xFFD4BE9D);
    const tobacco = Color(0xFF9A704F);

    return Container(
      decoration: const BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Bar (Ikon, Judul & Tombol Tutup)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: parchment,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.2),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: oxblood,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ganti Username',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: walnut,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sesuaikan identitas akun membaca Anda',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: tobacco,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: parchment.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: walnut,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEADBCE)),
              const SizedBox(height: 16),

              // Banner Informasi / Cooldown Card
              if (locked)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF2E6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_clock_rounded,
                        color: Color(0xFF9A704F),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Username hanya dapat diubah sekali setiap 30 hari. Anda dapat mengubahnya kembali pada ${DateFormat('dd MMMM yyyy', 'id_ID').format(widget.availableAt!)}.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: walnut,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: parchment.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: oxblood,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pilih username yang unik dan mudah dikenali. Username dapat diganti kembali 30 hari setelah disimpan.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: walnut,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),

              // Input Username
              Text(
                'Username Baru',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: walnut,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                autofocus: !locked,
                readOnly: locked,
                enabled: !locked,
                maxLength: 20,
                textCapitalization: TextCapitalization.none,
                style: GoogleFonts.plusJakartaSans(
                  color: walnut,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Center(
                      widthFactor: 0,
                      child: Text(
                        '@',
                        style: GoogleFonts.plusJakartaSans(
                          color: oxblood,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: parchment.withValues(alpha: 0.45),
                  hintText: 'nama_pengguna',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: walnut.withValues(alpha: 0.45),
                    fontSize: 14,
                  ),
                  helperText: '3–20 karakter: huruf, angka, atau garis bawah',
                  helperStyle: GoogleFonts.plusJakartaSans(
                    color: tobacco,
                    fontSize: 11,
                  ),
                  counterStyle: GoogleFonts.plusJakartaSans(
                    color: tobacco,
                    fontSize: 11,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: borderColor, width: 1.1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: borderColor, width: 1.1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: oxblood, width: 1.8),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: borderColor.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: borderColor, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: walnut,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: locked ? 1 : 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: oxblood,
                        disabledBackgroundColor: oxblood.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: (!locked && _canSubmit)
                          ? () => Navigator.pop(context, _controller.text.trim())
                          : null,
                      child: Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: parchment,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _ChangeUsernamePage = _ChangeUsernameModal;