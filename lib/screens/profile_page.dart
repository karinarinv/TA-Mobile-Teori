import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import 'saved_books_page.dart';
import 'blockchain_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _user, _photo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _user = await AuthService.currentSession();
    final rows = await (await DbHelper.db).query('users', where: 'username=?', whereArgs: [_user]);
    if (rows.isNotEmpty) _photo = rows.first['photo'] as String?;
    if (mounted) setState(() {});
  }

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (f == null) return;
    await (await DbHelper.db).update('users', {'photo': f.path}, where: 'username=?', whereArgs: [_user]);
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(children: [
            GestureDetector(
              onTap: _pick,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _photo != null ? FileImage(File(_photo!)) : null,
                child: _photo == null ? const Icon(Icons.add_a_photo, size: 40) : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(_user ?? '-', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Ketuk foto profil untuk mengganti', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.collections_bookmark, color: Colors.indigo),
                      ),
                      title: const Text('Buku Tersimpan', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Lihat buku favorit yang disimpan'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedBooksPage())),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.verified, color: Colors.indigo),
                      ),
                      title: const Text('Riwayat Sewa (Blockchain)', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Cek transaksi & masa sewa buku'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockchainPage())),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      );
}

