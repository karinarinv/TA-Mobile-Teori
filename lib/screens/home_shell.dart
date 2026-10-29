import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_vision_page.dart';
import 'menu_page.dart';
import 'profile_page.dart';
import 'feedback_page.dart';

/// Kerangka navigasi utama yang menampung Beranda, Profil, dan Kesan & Saran.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  final _pages = const [MenuPage(), ProfilePage(), FeedbackPage()];

  @override
  void initState() {
    super.initState();
    _checkPendingCamera();
  }

  Future<void> _checkPendingCamera() async {
    // Pulihkan halaman pemindai jika aplikasi sempat dijeda saat membuka kamera.
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('ai_vision_camera_pending') == true) {
        await prefs.remove('ai_vision_camera_pending');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiVisionPage()),
            );
          }
        });
      }
    } catch (_) {}
  }

  // WARNA: palet _cOxblood ().
  static const Color _cOxblood = Color(0xFF67343A);
  // WARNA: palet _cMuted ().
  static const Color _cMuted = Color(0xFF8C7362);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_i],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            // WARNA: latar kartu/komponen.
            color: Color(0xFFFAF7F2),
            // WARNA: garis tepi komponen.
            border: Border(
              // WARNA: latar kartu/komponen.
              top: BorderSide(color: Color(0xFFEADBCE), width: 1.2),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: BottomNavigationBar(
                currentIndex: _i,
                elevation: 0,
                // WARNA: latar menu navigasi bawah.
                backgroundColor: const Color(0xFFFAF7F2),
                type: BottomNavigationBarType.fixed,
                // WARNA: ikon dan teks menu yang sedang dipilih.
                selectedItemColor: _cOxblood,
                // WARNA: ikon dan teks menu yang sedang dipilih.
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

  // Bentuk ikon tab aktif/nonaktif dengan animasi ukuran 250 milidetik.
  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _i == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: isSelected ? 18 : 6, vertical: 4),
      decoration: BoxDecoration(
        // WARNA: latar kartu/komponen.
        color: isSelected ? const Color(0xFFEDE2CF) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        size: 22,
        // WARNA: latar kartu/komponen.
        color: isSelected ? _cOxblood : _cMuted,
      ),
    );
  }
}
