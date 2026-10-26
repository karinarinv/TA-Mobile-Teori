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
  String _vipExpiry = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
      if (nextUsernameChange != null && DateTime.now().isBefore(nextUsernameChange)) {
        usernameChangeAvailableAt = nextUsernameChange;
      }
    }

    final bookmarks = await BookmarkService.getBookmarks();
    final rentals = await BlockchainService.all();

    if (mounted) {
      final isVip = await SubscriptionService.isVip();
      final expiry = await SubscriptionService.getExpiryDate();
      setState(() {
        _username = username;
        _photo = photo;
        _usernameChangeAvailableAt = usernameChangeAvailableAt;
        _savedCount = bookmarks.length;
        _rentalCount = rentals.length;
        _isVip = isVip;
        _vipExpiry = expiry;
        _loading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
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
    final currentUsername = _username;
    if (currentUsername == null) return;

    final controller = TextEditingController(text: currentUsername);
    final requestedUsername = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ganti Username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            labelText: 'Username baru',
            prefixText: '@',
            helperText: '3-20 karakter: huruf, angka, underscore',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF67343A)),
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (requestedUsername == null || !mounted) {
      controller.dispose();
      return;
    }

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
    } finally {
      controller.dispose();
    }
  }

  void _showImagePickerSheet() {
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
                    color: const Color(0xFFEDE2CF),
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                    color: const Color(0xFFEDE2CF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF67343A)),
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
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
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
                color: const Color(0xFF67343A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF67343A).withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
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
                    foregroundColor: const Color(0xFF302622),
                    side: const BorderSide(color: Color(0xFFEADBCE), width: 1.2),
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
                      color: const Color(0xFF302622),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF67343A),
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
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text(
          'Profil Pengguna',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF67343A),
        foregroundColor: const Color(0xFFEDE2CF),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFEDE2CF)),
            tooltip: 'Segarkan',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF67343A)),
            )
          : RefreshIndicator(
              color: const Color(0xFF67343A),
              backgroundColor: const Color(0xFFEDE2CF),
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Column(
                  children: [
                    // 1. KARTU HEADER PROFIL PENGGUNA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF302622).withValues(alpha: 0.05),
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
                                        colors: _isVip
                                            ? const [Color(0xFFD4AF37), Color(0xFFB45309), Color(0xFF67343A)]
                                            : const [Color(0xFFEADBCE), Color(0xFFEDE2CF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF302622).withValues(alpha: 0.16),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: const Color(0xFFEDE2CF),
                                      backgroundImage: _photo != null ? FileImage(File(_photo!)) : null,
                                      child: _photo == null
                                          ? const Icon(Icons.person, size: 52, color: Color(0xFF67343A))
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
                                        color: const Color(0xFF67343A),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, size: 15, color: Color(0xFFEDE2CF)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Nama Pengguna
                          Text(
                            _username ?? 'Pengguna',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF302622),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Badge Status Keanggotaan Sesuai Color Palette
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5),
                            decoration: BoxDecoration(
                              gradient: _isVip
                                  ? const LinearGradient(
                                      colors: [Color(0xFF67343A), Color(0xFF4A1F25)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: _isVip ? null : const Color(0xFFEDE2CF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isVip ? const Color(0xFFD4AF37) : const Color(0xFFEADBCE),
                                width: 1.2,
                              ),
                              boxShadow: _isVip
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF67343A).withValues(alpha: 0.25),
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
                                  _isVip ? Icons.stars_rounded : Icons.person_outline_rounded,
                                  size: 14,
                                  color: _isVip ? const Color(0xFFD4AF37) : const Color(0xFF67343A),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isVip ? 'MEMBER VIP AKTIF' : 'MEMBER REGULER',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: _isVip ? const Color(0xFFEDE2CF) : const Color(0xFF67343A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tombol Ganti Username
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _usernameChangeAvailableAt == null ? _changeUsername : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.alternate_email_rounded,
                                    size: 14,
                                    color: _usernameChangeAvailableAt == null
                                        ? const Color(0xFF9A704F)
                                        : Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _usernameChangeAvailableAt == null
                                        ? 'Ganti username (sekali tiap 30 hari)'
                                        : 'Bisa diganti lagi ${DateFormat('dd MMM yyyy', 'id_ID').format(_usernameChangeAvailableAt!)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: _usernameChangeAvailableAt == null
                                          ? const Color(0xFF9A704F)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                            colors: [Color(0xFF5E2B31), Color(0xFF4A1F25), Color(0xFF302622)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF302622).withValues(alpha: 0.22),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE2CF).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Color(0xFFD4AF37),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Keanggotaan VIP Club',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFEDE2CF),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Akses eksklusif fitur premium',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFFD4BE9D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Badge VIP Aktif Eksklusif (Sesuai Color Palette)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE2CF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
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
                                        color: Color(0xFF67343A),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'VIP AKTIF',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
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
                                  colors: [
                                    const Color(0xFFD4AF37).withValues(alpha: 0.45),
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
                                  color: Color(0xFFD4BE9D),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Masa aktif 30 hari • Berlaku hingga $_vipExpiry',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
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
                                  color: const Color(0xFFD4BE9D).withValues(alpha: 0.85),
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
                            colors: [Color(0xFFFAF2E6), Color(0xFFF1E6D4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD4BE9D), width: 1.3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF302622).withValues(alpha: 0.05),
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
                                color: Color(0xFFEDE2CF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium_outlined,
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
                                      color: const Color(0xFF302622),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Akses Labirin Game, Konversi Kurs & AI Vision Scanner.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
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
                                backgroundColor: const Color(0xFF67343A),
                                foregroundColor: const Color(0xFFEDE2CF),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEADBCE), width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF302622).withValues(alpha: 0.04),
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
                                color: const Color(0xFF9A704F),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFEADBCE)),
                              ),
                              child: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF67343A), size: 19),
                            ),
                            title: Text(
                              'Buku Tersimpan',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5, color: const Color(0xFF302622)),
                            ),
                            subtitle: Text(
                              '$_savedCount buku favorit tersimpan',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF6B564A)),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9A704F)),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedBooksPage()));
                              _load();
                            },
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEADBCE)),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFEADBCE)),
                              ),
                              child: const Icon(Icons.lock_clock_rounded, color: Color(0xFF67343A), size: 19),
                            ),
                            title: Text(
                              'Riwayat Sewa (Blockchain)',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5, color: const Color(0xFF302622)),
                            ),
                            subtitle: Text(
                              '$_rentalCount transaksi sewa tercatat di blockchain',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF6B564A)),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9A704F)),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockchainPage()));
                              _load();
                            },
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEADBCE)),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFEADBCE)),
                              ),
                              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF67343A), size: 19),
                            ),
                            title: Text(
                              'Ganti Username Akun',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5, color: const Color(0xFF302622)),
                            ),
                            subtitle: Text(
                              _usernameChangeAvailableAt == null
                                  ? 'Perbarui username akun Anda'
                                  : 'Tersedia kembali ${DateFormat('dd MMM yyyy', 'id_ID').format(_usernameChangeAvailableAt!)}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF6B564A)),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9A704F)),
                            onTap: _usernameChangeAvailableAt == null ? _changeUsername : null,
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEADBCE)),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFEADBCE)),
                              ),
                              child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF67343A), size: 19),
                            ),
                            title: Text(
                              'Perbarui Foto Profil',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5, color: const Color(0xFF302622)),
                            ),
                            subtitle: Text(
                              'Pilih foto baru dari kamera atau galeri ponsel',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF6B564A)),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9A704F)),
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
                          foregroundColor: const Color(0xFF67343A),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF67343A), width: 1.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, size: 19),
                        label: Text(
                          'Keluar dari Akun',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                        const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF9A704F)),
                        const SizedBox(width: 6),
                        Text(
                          'RentBook • Keamanan SHA-256 Terenkripsi',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF9A704F)),
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
