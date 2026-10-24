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
            color: Color(0xFFFAF7F2),
            border: Border(
              top: BorderSide(color: Color(0xFFEADBCE), width: 1.2),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: BottomNavigationBar(
                currentIndex: _i,
                elevation: 0,
                backgroundColor: const Color(0xFFFAF7F2),
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
                items: [
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.home_rounded, 0),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.person_rounded, 1),
                    label: 'Profil',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.rate_review_rounded, 2),
                    label: 'Saran & Kesan',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _i == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: isSelected ? 18 : 6, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEDE2CF) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        size: 22,
        color: isSelected ? _cOxblood : _cMuted,
      ),
    );
  }
}
