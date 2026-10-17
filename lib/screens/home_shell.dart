import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'menu_page.dart';
import 'profile_page.dart';
import 'feedback_page.dart';
import 'login_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  final _pages = const [MenuPage(), ProfilePage(), FeedbackPage()];

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ya')),
        ],
      ),
    );
    if (yes == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_i],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _i,
          type: BottomNavigationBarType.fixed,
          onTap: (n) => n == 3 ? _logout() : setState(() => _i = n),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
            BottomNavigationBarItem(icon: Icon(Icons.rate_review), label: 'Saran & Kesan'),
            BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
          ],
        ),
      );
}
