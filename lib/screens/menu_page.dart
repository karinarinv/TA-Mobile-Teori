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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFCFAF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE8DECF), width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cOxblood.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_outline_rounded, color: _cOxblood, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Panduan RentBook',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _cWalnut,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cara Sewa Buku:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _cOxblood, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '1. Buka menu "Cari & Sewa Buku" lalu ketik buku yang ingin dicari atau goyangkan HP untuk rekomendasi acak.\n'
                '2. Pilih buku yang diinginkan lalu ketuk "Sewa Sekarang".\n'
                '3. Tentukan durasi pinjam dan metode pembayaran.',
                style: GoogleFonts.poppins(fontSize: 12, color: _cWalnut.withValues(alpha: 0.85), height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Transparansi Blockchain:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _cOxblood, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Setiap transaksi sewa dicatat ke dalam buku besar lokal terenkripsi SHA-256 sehingga riwayat Anda aman dan tidak dapat dimanipulasi.',
                style: GoogleFonts.poppins(fontSize: 12, color: _cWalnut.withValues(alpha: 0.85), height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Voucher Diskon:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _cOxblood, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Taklukkan 3 level di menu "Labirin Perpustakaan" untuk menemukan Buku Emas dan mengklaim kode voucher potongan harga sewa!',
                style: GoogleFonts.poppins(fontSize: 12, color: _cWalnut.withValues(alpha: 0.85), height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _cOxblood,
              foregroundColor: _cParchment,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
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

    // 8 Menu 
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
        subtitle: 'Rekomendasi Gemini AI',
        badge: 'AI Smart',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF5A2A38), 
        onTap: () => go(const AiPage()),
      ),
      _MenuItem(
        title: 'Perpustakaan Terdekat',
        subtitle: 'Titik Perpustakaan & rute GPS',
        badge: 'GPS Maps',
        icon: Icons.location_on_rounded,
        color: const Color(0xFF43634B), 
        onTap: () => go(const MapPage()),
      ),
      _MenuItem(
        title: 'Labirin Perpustakaan',
        subtitle: 'Temukan buku emas',
        badge: 'Minigame',
        icon: Icons.sports_esports_rounded,
        color: const Color(0xFFB45309), 
        onTap: () => go(const GamePage()),
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
        badge: 'Kurs & Jam',
        icon: Icons.currency_exchange_rounded,
        color: const Color(0xFF3B506B), 
        onTap: () => go(const ConverterPage()),
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
        title: Row(
          children: [
            Image.asset(
              'assets/images/rentbook_logo.png',
              height: 30,
              color: _cParchment,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.menu_book_rounded,
                color: _cParchment,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'RentBook',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _cParchment,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Panduan Perpustakaan',
            icon: const Icon(Icons.help_outline_rounded, color: _cParchment),
            onPressed: _showHelpDialog,
          ),
          const SizedBox(width: 4),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cAgedPaper.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _cAgedPaper.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: _cParchment,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => go(const AiPage()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE8DB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _cTobacco.withValues(alpha: 0.45),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0E302622),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _cOxblood.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: _cOxblood,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bingung Memilih Buku Hari Ini?',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _cWalnut,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Minta rekomendasi cerdas dari Asisten AI Perpustakaan',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: const Color(0xFF6E5648),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _cTobacco,
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
