// ============================================================================
// FITUR BERANDA: HOME SHELL (NAVIGASI UTAMA APLIKASI)
// ----------------------------------------------------------------------------
// Logika Presentasi:
// 1. BottomNavigationBar Controller:
//    - Mengelola perpindahan 3 tab utama:
//      * Index 0: Beranda / Dashboard (MenuPage)
//      * Index 1: Profil Pengguna (ProfilePage)
//      * Index 2: Evaluasi & Saran (FeedbackPage)
// 2. State Retention: Menyimpan index halaman aktif menggunakan setState(_i = n).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // WARNA: konstanta marun (_cOxblood) untuk ikon & label tab bottom navigation yang sedang aktif.
  static const Color _cOxblood = Color(0xFF67343A);
  // WARNA: konstanta cokelat redup (_cMuted) untuk ikon & label tab bottom navigation yang tidak aktif.
  static const Color _cMuted = Color(0xFF8C7362);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_i],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            // WARNA: latar belakang wadah luar bar navigasi bawah (HomeShell).
            color: Color(0xFFFAF7F2),
            border: Border(
              // WARNA: garis pembatas tipis di sisi atas bar navigasi bawah.
              top: BorderSide(color: Color(0xFFEADBCE), width: 1.2),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: BottomNavigationBar(
                currentIndex: _i,
                elevation: 0,
                // WARNA: latar belakang widget BottomNavigationBar utama (Beranda, Profil, Saran & Kesan).
                backgroundColor: const Color(0xFFFAF7F2),
                type: BottomNavigationBarType.fixed,
                // WARNA: warna label & ikon tab navigasi bawah yang sedang aktif/dipilih.
                selectedItemColor: _cOxblood,
                // WARNA: warna label & ikon tab navigasi bawah yang sedang tidak aktif.
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
        // WARNA: latar pil sorotan di belakang ikon tab navigasi bawah (krem saat aktif, transparan saat tidak aktif).
        color: isSelected ? const Color(0xFFEDE2CF) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        size: 22,
        // WARNA: warna ikon di dalam pil tab navigasi bawah (marun saat aktif, cokelat redup saat tidak aktif).
        color: isSelected ? _cOxblood : _cMuted,
      ),
    );
  }
}
