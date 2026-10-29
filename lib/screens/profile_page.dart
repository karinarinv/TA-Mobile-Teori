import 'package:google_fonts/google_fonts.dart';

import '../services/subscription_service.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/db_helper.dart';
import '../services/bookmark_service.dart';
import '../services/blockchain_service.dart';
import 'saved_books_page.dart';
import 'blockchain_page.dart';
import 'login_page.dart';

/// Ringkasan akun: profil lokal, bookmark, riwayat sewa, dan membership.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username, _photo;
  DateTime? _usernameChangeAvailableAt;
  int _savedCount = 0;
  int _rentalCount = 0;
  bool _loading = true;
  bool _isVip = false;
  String _vipPlanName = '-';
  String _vipExpiry = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    final rentals = await BlockchainService.all();

    if (mounted) {
      final isVip = await SubscriptionService.isVip();
      final vipPlanName = await SubscriptionService.getPlanName();
      final expiry = await SubscriptionService.getExpiryDate();
      setState(() {
        _username = username;
        _photo = photo;
        _usernameChangeAvailableAt = usernameChangeAvailableAt;
        _savedCount = bookmarks.length;
        _rentalCount = rentals.length;
        _isVip = isVip;
        _vipPlanName = vipPlanName;
        _vipExpiry = expiry;
        _loading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
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

  Future<void> _changeUsername() async {
    // Buka formulir nama; AuthService menerapkan validasi dan jeda 30 hari.
    final currentUsername = _username;
    if (currentUsername == null) return;

    final requestedUsername = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _ChangeUsernamePage(
        initialUsername: currentUsername,
        availableAt: _usernameChangeAvailableAt,
        ),
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
                  // WARNA: latar kartu/komponen.
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
                    // WARNA: latar kartu/komponen.
                    color: const Color(0xFFEDE2CF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // WARNA: latar kartu/komponen.
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
                    // WARNA: latar kartu/komponen.
                    color: const Color(0xFFEDE2CF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    // WARNA: latar kartu/komponen.
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

  Future<void> _logout() async {
    // Minta konfirmasi; jika setuju, hapus sesi dan kembali ke login.
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        // WARNA: latar dialog.
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          // WARNA: warna komponen.
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
                // WARNA: latar kartu/komponen.
                color: const Color(0xFF67343A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                // WARNA: garis tepi komponen.
                border: Border.all(
                  // WARNA: garis tepi kartu/komponen.
                  color: const Color(0xFF67343A).withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                // WARNA: garis tepi kartu/komponen.
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
                // WARNA: teks 'Konfirmasi Keluar'.
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
            // WARNA: teks judul/isi pada bagian ini.
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
                    // WARNA: teks/ikon tombol 'Batal'.
                    foregroundColor: const Color(0xFF302622),
                    side: const BorderSide(
                      // WARNA: garis tepi kartu/komponen.
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
                      // WARNA: teks 'Batal'.
                      color: const Color(0xFF302622),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    // WARNA: latar tombol.
                    backgroundColor: const Color(0xFF67343A),
                    // WARNA: teks/ikon tombol 'Keluar'.
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
                      // WARNA: teks 'Keluar'.
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
      await AuthService.logout();
      if (!mounted) return;
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
      // WARNA: latar halaman.
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text(
          'Profil Pengguna',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        elevation: 0,
        // WARNA: latar AppBar.
        backgroundColor: const Color(0xFF67343A),
        // WARNA: teks/ikon tombol.
        foregroundColor: const Color(0xFFEDE2CF),
        actions: [
          IconButton(
            // WARNA: teks 'Profil Pengguna'.
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFEDE2CF)),
            tooltip: 'Segarkan',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              // WARNA: ikon refresh_rounded.
              child: CircularProgressIndicator(color: Color(0xFF67343A)),
            )
          : RefreshIndicator(
              // WARNA: ikon pada komponen ini.
              color: const Color(0xFF67343A),
              // WARNA: latar spinner tarik-refresh.
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
                        // WARNA: latar kartu/komponen.
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        // WARNA: garis tepi komponen.
                        border: Border.all(
                          // WARNA: garis tepi kartu/komponen.
                          color: const Color(0xFFEADBCE),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            // WARNA: bayangan kartu.
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
                                        // WARNA: gradasi komponen ini.
                                        colors: _isVip
                                            ? const [
                                                Color(0xFFD4AF37),
                                                // WARNA: bayangan kartu.
                                                Color(0xFFB45309),
                                                // WARNA: bayangan kartu.
                                                Color(0xFF67343A),
                                              ]
                                            : const [
                                                // WARNA: bayangan kartu.
                                                Color(0xFFEADBCE),
                                                // WARNA: bayangan kartu.
                                                Color(0xFFEDE2CF),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          // WARNA: bayangan kartu.
                                          color: const Color(0xFF302622)
                                              .withValues(alpha: 0.16),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      // WARNA: latar komponen.
                                      backgroundColor: const Color(0xFFEDE2CF),
                                      backgroundImage: _photo != null
                                          ? FileImage(File(_photo!))
                                          : null,
                                      child: _photo == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 52,
                                              // WARNA: ikon person.
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
                                        // WARNA: latar kartu/komponen.
                                        color: const Color(0xFF67343A),
                                        shape: BoxShape.circle,
                                        // WARNA: garis tepi komponen.
                                        border: Border.all(
                                          // WARNA: garis tepi kartu/komponen.
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            // WARNA: bayangan kartu.
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
                                        // WARNA: ikon camera_alt_rounded.
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
                                        // WARNA: teks '_username'.
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
                                        // WARNA: ikon edit_rounded.
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
                              vertical: 4.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: _isVip
                                  ? const LinearGradient(
                                      // WARNA: gradasi komponen ini.
                                      colors: [
                                        Color(0xFF67343A),
                                        Color(0xFF4A1F25),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              // WARNA: latar kartu/komponen ini.
                              color: _isVip ? null : const Color(0xFFEDE2CF),
                              borderRadius: BorderRadius.circular(20),
                              // WARNA: garis tepi komponen.
                              border: Border.all(
                                // WARNA: garis tepi kartu/komponen.
                                color: _isVip
                                    ? const Color(0xFFD4AF37)
                                    : const Color(0xFFEADBCE),
                                width: 1.2,
                              ),
                              boxShadow: _isVip
                                  ? [
                                      BoxShadow(
                                        // WARNA: bayangan kartu.
                                        color: const Color(0xFF67343A)
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isVip
                                      ? Icons.stars_rounded
                                      : Icons.person_outline_rounded,
                                  size: 14,
                                  // WARNA: ikon stars_rounded.
                                  color: _isVip
                                      ? const Color(0xFFD4AF37)
                                      : const Color(0xFF67343A),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isVip
                                      ? 'MEMBER VIP • $_vipPlanName'
                                      : 'MEMBER REGULER',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    // WARNA: teks status VIP/anggota.
                                    color: _isVip
                                        ? const Color(0xFFEDE2CF)
                                        : const Color(0xFF67343A),
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

                    // 2. KARTU HERO: KEANGGOTAAN VIP SESUAI COLOR PALETTE
                    if (_isVip)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            // WARNA: gradasi komponen ini.
                            colors: [
                              Color(0xFF5E2B31),
                              Color(0xFF4A1F25),
                              // WARNA: latar kartu.
                              Color(0xFF302622),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          // WARNA: garis tepi komponen.
                          border: Border.all(
                            // WARNA: garis tepi kartu/komponen.
                            color: const Color(0xFFD4AF37)
                                .withValues(alpha: 0.65),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              // WARNA: bayangan kartu.
                              color: const Color(0xFF302622)
                                  .withValues(alpha: 0.22),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 10,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        // WARNA: latar kartu/komponen.
                                        color: const Color(0xFFEDE2CF)
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        // WARNA: bayangan kartu/panel.
                                        border: Border.all(
                                          // WARNA: garis tepi kartu/komponen.
                                          color: const Color(0xFFD4AF37)
                                              .withValues(alpha: 0.6),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_rounded,
                                        // WARNA: garis tepi kartu/komponen.
                                        color: Color(0xFFD4AF37),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Keanggotaan VIP Club',
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            // WARNA: teks 'Keanggotaan VIP Club'.
                                            color: const Color(0xFFEDE2CF),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Akses eksklusif fitur premium',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            // WARNA: teks 'Keanggotaan VIP Club'.
                                            color: const Color(0xFFD4BE9D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Badge VIP Aktif Eksklusif (Sesuai Color Palette)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4.5,
                                  ),
                                  decoration: BoxDecoration(
                                    // WARNA: latar kartu/komponen.
                                    color: const Color(0xFFEDE2CF),
                                    borderRadius: BorderRadius.circular(20),
                                    // WARNA: garis tepi komponen.
                                    border: Border.all(
                                      // WARNA: garis tepi kartu/komponen.
                                      color: const Color(0xFFD4AF37),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        // WARNA: bayangan kartu.
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 13,
                                        // WARNA: ikon verified_rounded.
                                        color: Color(0xFF67343A),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _vipPlanName.isNotEmpty
                                            ? 'VIP AKTIF • $_vipPlanName'
                                            : 'VIP AKTIF',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          // WARNA: teks '_vipPlanName.isNotEmpty'.
                                          color: const Color(0xFF67343A),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  // WARNA: gradasi komponen ini.
                                  colors: [
                                    const Color(0xFFD4AF37)
                                        .withValues(alpha: 0.45),
                                    // WARNA: latar kartu 'Paket $_vipPlanName • aktif hingga $_vipExpiry'.
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.event_available_rounded,
                                  size: 16,
                                  // WARNA: ikon event_available_rounded.
                                  color: Color(0xFFD4BE9D),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Paket $_vipPlanName • aktif hingga $_vipExpiry',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      // WARNA: teks 'Paket $_vipPlanName • aktif hingga $_vipExpiry'.
                                      color: const Color(0xFFEDE2CF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Text(
                                'Akses tak terbatas: Labirin Perpustakaan, Konversi Kurs & Scan Cover AI.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  // WARNA: teks judul/isi pada bagian ini.
                                  color: const Color(0xFFD4BE9D)
                                      .withValues(alpha: 0.85),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            // WARNA: gradasi komponen ini.
                            colors: [Color(0xFFFAF2E6), Color(0xFFF1E6D4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          // WARNA: garis tepi komponen.
                          border: Border.all(
                            // WARNA: garis tepi kartu/komponen.
                            color: const Color(0xFFD4BE9D),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              // WARNA: bayangan kartu.
                              color: const Color(0xFF302622)
                                  .withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                // WARNA: latar kartu/komponen.
                                color: Color(0xFFEDE2CF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium_outlined,
                                // WARNA: latar kartu/komponen.
                                color: Color(0xFF67343A),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tingkatkan ke VIP Club',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      // WARNA: teks 'Tingkatkan ke VIP Club'.
                                      color: const Color(0xFF302622),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Akses Labirin Game, Konversi Kurs & AI Vision Scanner.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      // WARNA: teks 'Tingkatkan ke VIP Club'.
                                      color: const Color(0xFF7A4B3A),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                // WARNA: latar tombol.
                                backgroundColor: const Color(0xFF67343A),
                                // WARNA: teks/ikon tombol 'Upgrade'.
                                foregroundColor: const Color(0xFFEDE2CF),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                SubscriptionService.showPaywallDialog(
                                  context,
                                  featureName: 'Membership VIP',
                                  onSubscribed: _load,
                                );
                              },
                              child: Text(
                                'Upgrade',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 3. KARTU MENU NAVIGASI & PENGATURAN AKUN
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        // WARNA: latar kartu/komponen.
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        // WARNA: garis tepi komponen.
                        border: Border.all(
                          // WARNA: garis tepi kartu/komponen.
                          color: const Color(0xFFEADBCE),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            // WARNA: bayangan kartu.
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
                                // WARNA: teks 'PENGATURAN & AKUN'.
                                color: const Color(0xFF9A704F),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                // WARNA: latar kartu/komponen.
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(10),
                                // WARNA: garis tepi komponen.
                                border: Border.all(
                                  // WARNA: garis tepi kartu/komponen.
                                  color: const Color(0xFFEADBCE),
                                ),
                              ),
                              child: const Icon(
                                Icons.collections_bookmark_rounded,
                                // WARNA: garis tepi kartu/komponen.
                                color: Color(0xFF67343A),
                                size: 19,
                              ),
                            ),
                            title: Text(
                              'Buku Tersimpan',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                // WARNA: teks 'Buku Tersimpan'.
                                color: const Color(0xFF302622),
                              ),
                            ),
                            subtitle: Text(
                              '$_savedCount buku favorit tersimpan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                // WARNA: teks 'Buku Tersimpan'.
                                color: const Color(0xFF6B564A),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              // WARNA: teks 'Buku Tersimpan'.
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
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            // WARNA: warna komponen.
                            color: Color(0xFFEADBCE),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                // WARNA: latar kartu/komponen.
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(10),
                                // WARNA: garis tepi komponen.
                                border: Border.all(
                                  // WARNA: garis tepi kartu/komponen.
                                  color: const Color(0xFFEADBCE),
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_clock_rounded,
                                // WARNA: garis tepi kartu/komponen.
                                color: Color(0xFF67343A),
                                size: 19,
                              ),
                            ),
                            title: Text(
                              'Riwayat Sewa (Blockchain)',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                // WARNA: teks 'Riwayat Sewa (Blockchain)'.
                                color: const Color(0xFF302622),
                              ),
                            ),
                            subtitle: Text(
                              '$_rentalCount transaksi sewa tercatat di blockchain',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                // WARNA: teks 'Riwayat Sewa (Blockchain)'.
                                color: const Color(0xFF6B564A),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              // WARNA: teks 'Riwayat Sewa (Blockchain)'.
                              color: Color(0xFF9A704F),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BlockchainPage(),
                                ),
                              );
                              _load();
                            },
                          ),
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            // WARNA: warna komponen.
                            color: Color(0xFFEADBCE),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                // WARNA: latar kartu/komponen.
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(10),
                                // WARNA: garis tepi komponen.
                                border: Border.all(
                                  // WARNA: garis tepi kartu/komponen.
                                  color: const Color(0xFFEADBCE),
                                ),
                              ),
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                // WARNA: garis tepi kartu/komponen.
                                color: Color(0xFF67343A),
                                size: 19,
                              ),
                            ),
                            title: Text(
                              'Perbarui Foto Profil',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                // WARNA: teks 'Perbarui Foto Profil'.
                                color: const Color(0xFF302622),
                              ),
                            ),
                            subtitle: Text(
                              'Pilih foto baru dari kamera atau galeri ponsel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                // WARNA: teks 'Perbarui Foto Profil'.
                                color: const Color(0xFF6B564A),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              // WARNA: teks 'Perbarui Foto Profil'.
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
                          // WARNA: teks/ikon tombol 'Keluar dari Akun'.
                          foregroundColor: const Color(0xFF67343A),
                          // WARNA: latar tombol.
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            // WARNA: garis tepi kartu/komponen.
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
                            // WARNA: teks 'Keluar dari Akun'.
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
                          // WARNA: ikon shield_outlined.
                          color: Color(0xFF9A704F),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'RentBook • Keamanan SHA-256 Terenkripsi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            // WARNA: teks 'RentBook • Keamanan SHA-256 Terenkripsi'.
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

class _ChangeUsernamePage extends StatefulWidget {
  final String initialUsername;
  final DateTime? availableAt;

  const _ChangeUsernamePage({
    required this.initialUsername,
    required this.availableAt,
  });

  @override
  State<_ChangeUsernamePage> createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<_ChangeUsernamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.availableAt != null;
    // WARNA: warna elemen.
    const background = Color(0xFFEDE2CF);
    // WARNA: warna elemen.
    const fieldBackground = Color(0xFFD4BE9D);
    // WARNA: warna elemen.
    const walnut = Color(0xFF302622);
    // WARNA: warna elemen.
    const oxblood = Color(0xFF67343A);
    return Scaffold(
      // WARNA: latar halaman.
      backgroundColor: background,
      appBar: AppBar(
        // WARNA: latar AppBar.
        backgroundColor: background,
        // WARNA: teks/ikon tombol 'Batal'.
        foregroundColor: walnut,
        elevation: 0,
        // WARNA: warna komponen.
        title: const Text('Ubah nama', style: TextStyle(color: walnut, fontSize: 18, fontWeight: FontWeight.w600)),
        // WARNA: teks judul/isi pada bagian ini.
        leading: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: walnut, fontSize: 14))),
        leadingWidth: 72,
        actions: [
          TextButton(
            onPressed: locked ? null : () => Navigator.pop(context, _controller.text.trim()),
            // WARNA: teks 'Ubah nama'.
            child: Text('Simpan', style: TextStyle(color: locked ? walnut.withValues(alpha: 0.4) : oxblood, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // WARNA: teks 'Ubah nama'.
            const Text('Nama pengguna', style: TextStyle(color: walnut, fontSize: 23, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              locked
                  ? 'Nama pengguna hanya dapat diubah setiap 30 hari. Kamu bisa mengubahnya lagi pada ${DateFormat('dd MMMM yyyy', 'id_ID').format(widget.availableAt!)}.'
                  : 'Pilih nama pengguna yang mudah dikenali. Nama pengguna hanya dapat diubah setiap 30 hari.',
              // WARNA: teks 'Simpan'.
              style: const TextStyle(color: walnut, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _controller,
              autofocus: !locked,
              readOnly: locked,
              enabled: !locked,
              maxLength: 20,
              textCapitalization: TextCapitalization.none,
              // WARNA: teks 'Nama pengguna'.
              style: const TextStyle(color: walnut, fontSize: 16),
              decoration: InputDecoration(
                // WARNA: teks judul/isi pada bagian ini.
                prefixText: '@', prefixStyle: const TextStyle(color: walnut, fontSize: 16),
                // WARNA: teks judul/isi pada bagian ini.
                counterStyle: TextStyle(color: walnut.withValues(alpha: 0.65)),
                // WARNA: teks judul/isi pada bagian ini.
                filled: true, fillColor: fieldBackground,
                // WARNA: teks judul/isi pada bagian ini.
                hintText: 'nama_pengguna', hintStyle: TextStyle(color: walnut.withValues(alpha: 0.55)),
                helperText: '3–20 karakter: huruf, angka, atau garis bawah',
                // WARNA: teks judul/isi pada bagian ini.
                helperStyle: TextStyle(color: walnut.withValues(alpha: 0.75), fontSize: 12),
                // WARNA: garis tepi komponen.
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                // WARNA: teks judul/isi pada bagian ini.
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: oxblood, width: 1.5)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
