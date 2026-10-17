import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';

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
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
            const Text('Ketuk foto untuk mengganti'),
          ]),
        ),
      );
}
