import 'package:google_fonts/google_fonts.dart';

import '../services/subscription_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _user, _photo;
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
    _user = await AuthService.currentSession();
    final rows = await (await DbHelper.db).query('users', where: 'username=?', whereArgs: [_user]);
    if (rows.isNotEmpty) {
      _photo = rows.first['photo'] as String?;
    }

    final bookmarks = await BookmarkService.getBookmarks();
    final rentals = await BlockchainService.all();

    if (mounted) {
      final isVip = await SubscriptionService.isVip();
      final expiry = await SubscriptionService.getExpiryDate();
      setState(() {
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
    if (f == null) return;
    await (await DbHelper.db).update('users', {'photo': f.path}, where: 'username=?', whereArgs: [_user]);
    _load();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Keluar'),
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
        title: Text('Profil Pengguna', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
        elevation: 0,
        backgroundColor: const Color(0xFF67343A),
        foregroundColor: const Color(0xFFEDE2CF),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _showImagePickerSheet,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFEADBCE), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: const Color(0xFFEDE2CF),
                                backgroundImage: _photo != null ? FileImage(File(_photo!)) : null,
                                child: _photo == null
                                    ? const Icon(Icons.person, size: 55, color: Color(0xFF67343A))
                                    : null,
                              ),
                            ),
                          ),
                          PositionBeside(
                            child: InkWell(
                              onTap: _showImagePickerSheet,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF67343A),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _user ?? 'Pengguna',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isVip ? const Color(0xFF67343A).withValues(alpha: 0.12) : const Color(0xFFEDE2CF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isVip ? const Color(0xFF67343A) : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isVip ? Icons.workspace_premium_rounded : Icons.person_outline_rounded,
                            size: 14,
                            color: const Color(0xFF67343A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isVip ? 'Member VIP' : 'Member Reguler',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF67343A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kartu Status Berlangganan VIP
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isVip ? const Color(0xFF67343A) : const Color(0xFFEADBCE),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE2CF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isVip ? Icons.workspace_premium_rounded : Icons.card_membership_rounded,
                              color: const Color(0xFF67343A),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isVip ? 'Keanggotaan VIP Aktif' : 'Tingkatkan ke VIP Club',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF302622),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isVip
                                      ? 'Berlaku hingga $_vipExpiry. Akun otomatis menjadi Reguler saat masa aktif berakhir.'
                                      : 'Akses Labirin Perpustakaan, Konversi Kurs & AI Vision Scanner.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isVip)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Aktif',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF67343A),
                                foregroundColor: const Color(0xFFEDE2CF),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                SubscriptionService.showPaywallDialog(
                                  context,
                                  featureName: 'Membership VIP',
                                  onSubscribed: _load,
                                );
                              },
                              child: const Text(
                                'Upgrade',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Bar (Tersimpan & Disewa)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEADBCE)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedBooksPage()));
                                _load();
                              },
                              child: Column(
                                children: [
                                  Text(
                                    '$_savedCount',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF67343A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Buku Tersimpan',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 35, color: Colors.grey.shade300),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockchainPage()));
                                _load();
                              },
                              child: Column(
                                children: [
                                  Text(
                                    '$_rentalCount',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Transaksi Sewa',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Actions Card
                    Card(
                      color: const Color(0xFFFAF7F2),
                      surfaceTintColor: Colors.transparent,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFEADBCE)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE2CF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF67343A)),
                            ),
                            title: const Text('Buku Tersimpan', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text('Koleksi buku favorit yang Anda simpan'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedBooksPage()));
                              _load();
                            },
                          ),
                          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.lock_clock_rounded, color: Colors.green),
                            ),
                            title: const Text('Riwayat Sewa (Blockchain)', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text('Buku besar SHA-256 riwayat peminjaman'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockchainPage()));
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Logout 
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF67343A),
                          foregroundColor: const Color(0xFFEDE2CF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 1,
                        ),
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Version & Security Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          'RentBook v2.0 • Ledger Lokal Terenkripsi SHA-256',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
    );
  }
}

class PositionBeside extends StatelessWidget {
  final Widget child;
  const PositionBeside({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 2,
      right: 2,
      child: child,
    );
  }
}
