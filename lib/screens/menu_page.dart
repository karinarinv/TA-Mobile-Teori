import 'ai_vision_page.dart';
import '../services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'books_page.dart';
import 'converter_page.dart';
import 'map_page.dart';
import 'ai_page.dart';
import 'game_page.dart';
import 'blockchain_page.dart';
import 'saved_books_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _user = 'Pembaca';

  // Palet Warna 
  static const Color _cWalnut = Color(0xFF302622);
  static const Color _cOxblood = Color(0xFF67343A);
  static const Color _cTobacco = Color(0xFF9A704F);
  static const Color _cAgedPaper = Color(0xFFD4BE9D);
  static const Color _cParchment = Color(0xFFEDE2CF);
  static const Color _cBgWarm = Color(0xFFFAF7F2); 
  static const Color _cCardBg = Colors.white; 

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await AuthService.currentSession();
    if (u != null && u.isNotEmpty && mounted) {
      setState(() => _user = u);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _LibraryBookGuideDialog(),
    );
  }

  String _formatToday() {
    try {
      return DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now());
    } catch (_) {
      const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final now = DateTime.now();
      return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    final todayStr = _formatToday();

    // Menu Terstruktur (Termasuk Fitur AI LLM & AI Vision + VIP Membership)
    final items = [
      _MenuItem(
        title: 'Cari & Sewa Buku',
        subtitle: 'Katalog & sewa instan',
        badge: 'Katalog',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF67343A), 
        onTap: () => go(const BooksPage()),
      ),
      _MenuItem(
        title: 'Buku Tersimpan',
        subtitle: 'Daftar buku favorit',
        badge: 'Favorit',
        icon: Icons.bookmark_added_rounded,
        color: const Color(0xFF9A704F),
        onTap: () => go(const SavedBooksPage()),
      ),
      _MenuItem(
        title: 'Asisten AI Buku',
        subtitle: 'Kurator cerdas LLM',
        badge: 'AI Cerdas',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF5A2A38), 
        onTap: () => go(const AiPage()),
      ),
      _MenuItem(
        title: 'Scan Cover Buku',
        subtitle: 'Deteksi kamera AI Vision',
        badge: 'VIP',
        icon: Icons.camera_enhance_rounded,
        color: const Color(0xFF4C3B71), 
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Scan Cover Buku',
          onAllowed: () => go(const AiVisionPage()),
        ),
      ),
      _MenuItem(
        title: 'Labirin Perpustakaan',
        subtitle: 'Temukan buku & voucher',
        badge: 'VIP',
        icon: Icons.sports_esports_rounded,
        color: const Color(0xFFB45309), 
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Labirin Perpustakaan',
          onAllowed: () => go(const GamePage()),
        ),
      ),
      _MenuItem(
        title: 'Perpustakaan Terdekat',
        subtitle: 'Titik Perpustakaan & GPS',
        badge: 'GPS Maps',
        icon: Icons.location_on_rounded,
        color: const Color(0xFF43634B), 
        onTap: () => go(const MapPage()),
      ),
      _MenuItem(
        title: 'Riwayat Blockchain',
        subtitle: 'Ledger transaksi SHA-256',
        badge: 'SHA-256',
        icon: Icons.lock_clock_rounded,
        color: const Color(0xFF7C3F2B), 
        onTap: () => go(const BlockchainPage()),
      ),
      _MenuItem(
        title: 'Konversi Kurs & Jam',
        subtitle: 'Mata Uang & Jam Dunia',
        badge: 'VIP',
        icon: Icons.currency_exchange_rounded,
        color: const Color(0xFF3B506B), 
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Konversi Kurs & Jam',
          onAllowed: () => go(const ConverterPage()),
        ),
      ),
      _MenuItem(
        title: 'Panduan & Bantuan',
        subtitle: 'FAQ & info peminjaman',
        badge: 'Bantuan',
        icon: Icons.help_outline_rounded,
        color: const Color(0xFF302622),
        onTap: _showHelpDialog,
      ),
    ];

    return Scaffold(
      backgroundColor: _cBgWarm,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _cOxblood,
        foregroundColor: _cParchment,
        titleSpacing: 16,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            'assets/images/rentbook_logo.png',
            height: 42,
            color: _cParchment,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.menu_book_rounded,
              color: _cParchment,
              size: 36,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Panduan Perpustakaan',
            icon: const Icon(Icons.help_outline_rounded, color: _cParchment),
            onPressed: _showHelpDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_cOxblood, Color(0xFF4C272C), _cWalnut],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _cTobacco.withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _cAgedPaper.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: _cAgedPaper),
                            const SizedBox(width: 6),
                            Text(
                              todayStr,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _cAgedPaper,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Selamat Datang, $_user!',
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _cParchment,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Temukan kisah baru di antara ribuan lembar buku hari ini.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: _cParchment.withValues(alpha: 0.88),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _cAgedPaper.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _cAgedPaper.withValues(alpha: 0.5),
                      width: 1.6,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/rentbook_logo.png',
                    height: 58,
                    width: 58,
                    color: _cParchment,
                    colorBlendMode: BlendMode.srcIn,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_stories_rounded,
                      color: _cParchment,
                      size: 52,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => go(const AiPage()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFAF2E6), Color(0xFFF1E6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFD4BE9D),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1467343A),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_cOxblood, Color(0xFF4C272C)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _cOxblood.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFEF08A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rekomendasi Gemini AI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _cWalnut,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Temukan buku terbaik sesuai selera baca Anda',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF6E5648),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _cOxblood.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _cOxblood.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tanya AI',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _cOxblood,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded, size: 12, color: _cOxblood),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _cOxblood,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Layanan & Koleksi Perpustakaan',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _cWalnut,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final it = items[index];
              return Container(
                decoration: BoxDecoration(
                  color: _cCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE8DECF),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0C302622),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: it.onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: it.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(it.icon, size: 22, color: it.color),
                              ),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: it.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    it.badge,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: it.color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: _cWalnut,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                it.subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: const Color(0xFF7A685A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// =========================================================================
/// DIALOG BUKU PANDUAN PERPUSTAKAAN INTERAKTIF (LEMBARAN DAPAT DIBALIK)
/// =========================================================================
class _LibraryBookGuideDialog extends StatefulWidget {
  const _LibraryBookGuideDialog();

  @override
  State<_LibraryBookGuideDialog> createState() => _LibraryBookGuideDialogState();
}

class _LibraryBookGuideDialogState extends State<_LibraryBookGuideDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 580),
          decoration: BoxDecoration(
            color: const Color(0xFF5A252C), // Kulit jilid buku oxblood tua
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2), // Aksen emas
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Pita Pembatas Buku Merah Sutra di atas
              Positioned(
                top: -14,
                right: 32,
                child: Container(
                  width: 20,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B2635),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.bookmark_rounded, color: Color(0xFFF1E6D4), size: 14),
                  ),
                ),
              ),

              // Lembaran Buku Bertekstur Kertas Tua
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEADBCE), width: 1.5),
                ),
                child: Column(
                  children: [
                    // Header Buku
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE2CF).withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        border: const Border(bottom: BorderSide(color: Color(0xFFEADBCE))),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_stories_rounded, color: Color(0xFF67343A), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kitab Panduan RentBook',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF302622),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF67343A)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Konten Halaman yang Dapat Dibalik (PageView)
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        children: [
                          _buildPageOne(),
                          _buildPageTwo(),
                          _buildPageThree(),
                          _buildPageFour(),
                          _buildPageFive(),
                        ],
                      ),
                    ),

                    // Bilah Navigasi Halaman Buku
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE2CF).withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        border: const Border(top: BorderSide(color: Color(0xFFEADBCE))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF67343A),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: _currentPage > 0 ? _prevPage : null,
                            icon: const Icon(Icons.arrow_back_ios_rounded, size: 13),
                            label: Text(
                              'Kembali',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),

                          // Indikator Halaman
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEADBCE)),
                            ),
                            child: Text(
                              'Hal ${_currentPage + 1} dari $_totalPages',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF67343A),
                              ),
                            ),
                          ),

                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF67343A),
                              foregroundColor: const Color(0xFFEDE2CF),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _nextPage,
                            label: Text(
                              _currentPage == _totalPages - 1 ? 'Selesai' : 'Lanjut',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            icon: Icon(
                              _currentPage == _totalPages - 1 ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
                              size: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageOne() {
    return _buildPageContainer(
      chapter: 'BAB I',
      title: 'Eksplorasi & Katalog Buku',
      icon: Icons.menu_book_rounded,
      sections: [
        _buildSectionItem(
          title: 'Pencarian & Koleksi Buku',
          desc: 'Jelajahi ribuan koleksi sastra, teknologi, dan sejarah. Gunakan bilah pencarian cerdas untuk memfilter berdasarkan judul atau pengarang.',
        ),
        _buildSectionItem(
          title: 'Fitur Shake Perangkat (Goyang HP)',
          desc: 'Bingung mau membaca apa? Goyangkan ponsel Anda di halaman Katalog Buku untuk mendapatkan rekomendasi buku acak secara instan dengan sensor akselerometer!',
        ),
        _buildSectionItem(
          title: 'Peta Perpustakaan & GPS',
          desc: 'Temukan lokasi cabang perpustakaan terdekat (termasuk Perpustakaan UPN) lengkap dengan rute interaktif dan jarak tempuh real-time.',
        ),
      ],
    );
  }

  Widget _buildPageTwo() {
    return _buildPageContainer(
      chapter: 'BAB II',
      title: 'Peminjaman & Pembayaran',
      icon: Icons.payment_rounded,
      sections: [
        _buildSectionItem(
          title: 'Durasi Fleksibel',
          desc: 'Tentukan jangka waktu sewa sesuai kebutuhan Anda: 3 hari, 7 hari, 14 hari, atau hingga 30 hari dengan penghitungan tarif harian yang transparan.',
        ),
        _buildSectionItem(
          title: 'Pembayaran QRIS Cepat (Deteksi 5 Detik)',
          desc: 'Pindai kode QRIS menggunakan e-Wallet (GoPay, OVO, Dana) atau Mobile Banking. Pembayaran akan terkonfirmasi secara otomatis dalam 5 detik!',
        ),
        _buildSectionItem(
          title: 'Virtual Account & Voucher Diskon',
          desc: 'Tersedia nomor VA resmi untuk bank BCA, Mandiri, BNI, dan BRI. Pasang kode voucher (seperti DISKON10) untuk potongan harga sewa buku.',
        ),
      ],
    );
  }

  Widget _buildPageThree() {
    return _buildPageContainer(
      chapter: 'BAB III',
      title: 'Integritas Blockchain SHA-256',
      icon: Icons.lock_clock_rounded,
      sections: [
        _buildSectionItem(
          title: 'Buku Besar Digital Abadi',
          desc: 'Setiap transaksi sewa dan aktivasi VIP dicatat ke dalam buku besar lokal terenkripsi SHA-256 yang saling terhubung secara berantai.',
        ),
        _buildSectionItem(
          title: 'Kekebalan dari Manipulasi',
          desc: 'Setiap blok menyimpan hash blok sebelumnya. Apabila terdapat perubahan data ilegal, rantai blok akan mendeteksi inkonsistensi secara otomatis.',
        ),
        _buildSectionItem(
          title: 'Audit Keaslian Mandiri',
          desc: 'Buka menu "Riwayat Blockchain" untuk memverifikasi keaslian transaksi, waktu simpan, dan tanda tangan hash kriptografis Anda.',
        ),
      ],
    );
  }

  Widget _buildPageFour() {
    return _buildPageContainer(
      chapter: 'BAB IV',
      title: 'Fitur Cerdas AI Gemini & Vision',
      icon: Icons.auto_awesome_rounded,
      sections: [
        _buildSectionItem(
          title: 'Asisten AI Kurator (LLM Gemini)',
          desc: 'Konsultasikan bacaan Anda dengan AI Kurator. AI dapat merangkum sinopsis, menganalisis tokoh buku, dan memberikan saran bacaan sesuai minat Anda (bebas diakses kapan saja).',
        ),
        _buildSectionItem(
          title: 'AI Vision Scanner (Kamera & Galeri)',
          desc: 'Arahkan kamera ke sampul buku fisik atau unggah dari galeri foto. Model AI Vision akan menganalisis sampul dan mencari informasinya di perpustakaan secara otomatis.',
        ),
      ],
    );
  }

  Widget _buildPageFive() {
    return _buildPageContainer(
      chapter: 'BAB V',
      title: 'Labirin & Keanggotaan VIP',
      icon: Icons.workspace_premium_rounded,
      sections: [
        _buildSectionItem(
          title: 'Labirin Perpustakaan & Hadiah Voucher',
          desc: 'Taklukkan labirin 3 lantai, kumpulkan buku-buku di lorong, dan hindari kejaran hantu animatronik Wikwok di lantai 3 untuk meraih Buku Emas dan kode voucher DISKON10.',
        ),
        _buildSectionItem(
          title: 'Keanggotaan VIP Club (Rp 29.000 / bln)',
          desc: 'Dapatkan akses eksklusif untuk 3 fitur utama: Minigame Labirin Perpustakaan, Konversi Kurs & Jam Dunia, serta AI Vision Scanner.',
        ),
        _buildSectionItem(
          title: 'Masa Aktif Natural Tanpa Jebakan',
          desc: 'Status VIP berlaku 30 hari sejak pembayaran. Setelah masa aktif berakhir, akun Anda otomatis kembali menjadi Reguler tanpa pemotongan saldo tersembunyi.',
        ),
      ],
    );
  }

  Widget _buildPageContainer({
    required String chapter,
    required String title,
    required IconData icon,
    required List<Widget> sections,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF67343A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  chapter,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEDE2CF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF302622),
                  ),
                ),
              ),
              Icon(icon, color: const Color(0xFF67343A), size: 20),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFEADBCE), thickness: 1.2),
          const SizedBox(height: 4),
          ...sections,
        ],
      ),
    );
  }

  Widget _buildSectionItem({required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF67343A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF302622),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              desc,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: const Color(0xFF5A4A3E),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
