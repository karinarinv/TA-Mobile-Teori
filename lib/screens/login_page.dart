import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _u = TextEditingController(), _p = TextEditingController();

  void _msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  void _goHome() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const HomeShell()));

  Future<void> _login() async {
    if (await AuthService.login(_u.text.trim(), _p.text)) {
      _goHome();
    } else {
      _msg('Username atau password salah');
    }
  }

  Future<void> _register() async {
    if (_u.text.trim().isEmpty || _p.text.length < 6) {
      return _msg('Isi username & password minimal 6 karakter');
    }
    _msg(await AuthService.register(_u.text.trim(), _p.text)
        ? 'Registrasi berhasil, silakan login'
        : 'Username sudah dipakai');
  }

  Future<void> _bio() async {
    if (await AuthService.loginBiometric()) {
      _goHome();
    } else {
      _msg('Biometrik gagal / belum pernah login');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Icon(Icons.menu_book, size: 80, color: Colors.indigo),
              const Text('RentBook', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(controller: _u, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _p, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _login, child: const Text('Login'))),
              TextButton(onPressed: _register, child: const Text('Daftar akun baru')),
              IconButton(iconSize: 48, onPressed: _bio, icon: const Icon(Icons.fingerprint)),
              const Text('Login biometrik'),
            ]),
          ),
        ),
      );
}
