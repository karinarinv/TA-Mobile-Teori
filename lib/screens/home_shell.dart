import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_page.dart';
import 'profile_page.dart';
import 'feedback_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  final _pages = const [MenuPage(), ProfilePage(), FeedbackPage()];

  static const Color _cOxblood = Color(0xFF67343A);
  static const Color _cMuted = Color(0xFF8C7362);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_i],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF6F0),
            border: Border(
              top: BorderSide(color: Color(0xFFE8DECF), width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _i,
            elevation: 0,
            backgroundColor: const Color(0xFFFAF6F0),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: _cOxblood,
            unselectedItemColor: _cMuted,
            selectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            onTap: (n) => setState(() => _i = n),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rate_review_rounded),
                label: 'Saran & Kesan',
              ),
            ],
          ),
        ),
      );
}
