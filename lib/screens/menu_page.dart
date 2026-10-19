import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'books_page.dart';
import 'converter_page.dart';
import 'map_page.dart';
import 'ai_page.dart';
import 'quiz_page.dart';
import 'blockchain_page.dart';
import 'saved_books_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _user = 'Pembaca';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Panduan RentBook',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📖 Cara Sewa Buku:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('1. Buka menu "Cari & Sewa Buku" atau goyangkan HP untuk rekomendasi acak.'),
              Text('2. Pilih buku yang diinginkan lalu ketuk "Sewa Sekarang".'),
              Text('3. Tentukan durasi pinjam dan metode pembayaran.'),
              SizedBox(height: 12),
              Text('🔒 Transparansi Blockchain:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Setiap transaksi sewa dicatat ke dalam buku besar lokal terenkripsi SHA-256 sehingga riwayat Anda aman dan tidak dapat dimanipulasi.'),
              SizedBox(height: 12),
              Text('🎁 Voucher Diskon:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Jawab kuis di menu "Kuis Buku" dengan skor minimal 60% untuk mengklaim kode voucher potongan harga sewa!'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
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
      const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      final now = DateTime.now();
      return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    final todayStr = _formatToday();

    // 8 Menu terstruktur simetris (2 kolom x 4 baris)
    final items = [
      _MenuItem(
        title: 'Cari & Sewa Buku',
        subtitle: 'Katalog & sewa instan',
        badge: 'Katalog',
        icon: Icons.menu_book_rounded,
        color: Colors.indigo,
        onTap: () => go(const BooksPage()),
      ),
      _MenuItem(
        title: 'Buku Tersimpan',
        subtitle: 'Daftar buku favorit',
        badge: 'Favorit',
        icon: Icons.bookmark_added_rounded,
        color: Colors.amber.shade800,
        onTap: () => go(const SavedBooksPage()),
      ),
      _MenuItem(
        title: 'Asisten AI Buku',
        subtitle: 'Rekomendasi Gemini AI',
        badge: 'AI Smart',
        icon: Icons.auto_awesome_rounded,
        color: Colors.purple.shade700,
        onTap: () => go(const AiPage()),
      ),
      _MenuItem(
        title: 'Perpustakaan Terdekat',
        subtitle: '11 Titik Jogja & rute OSRM',
        badge: 'GPS Maps',
        icon: Icons.location_on_rounded,
        color: Colors.teal.shade700,
        onTap: () => go(const MapPage()),
      ),
      _MenuItem(
        title: 'Kuis Pengetahuan',
        subtitle: 'Raih reward voucher sewa',
        badge: 'Reward',
        icon: Icons.quiz_rounded,
        color: Colors.deepOrange.shade600,
        onTap: () => go(const QuizPage()),
      ),
      _MenuItem(
        title: 'Riwayat Blockchain',
        subtitle: 'Ledger transaksi SHA-256',
        badge: 'SHA-256',
        icon: Icons.lock_clock_rounded,
        color: Colors.green.shade700,
        onTap: () => go(const BlockchainPage()),
      ),
      _MenuItem(
        title: 'Konversi Kurs & Waktu',
        subtitle: 'Multi-valas & jam dunia',
        badge: 'Valas',
        icon: Icons.currency_exchange_rounded,
        color: Colors.blue.shade700,
        onTap: () => go(const ConverterPage()),
      ),
      _MenuItem(
        title: 'Panduan & Bantuan',
        subtitle: 'FAQ & info peminjaman',
        badge: 'Bantuan',
        icon: Icons.help_outline_rounded,
        color: Colors.brown.shade600,
        onTap: _showHelpDialog,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('RentBook', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'Panduan',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Greeting Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todayStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.indigo.shade100,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Halo, $_user!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mau baca atau sewa buku apa hari ini?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(220),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_stories, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Banner Quick Action (Gemini AI & Kuis Promo)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => go(const AiPage()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome, color: Colors.purple.shade700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bingung pilih buku?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                        Text(
                          'Tanyakan rekomendasi cerdas ke Asisten AI Gemini',
                          style: TextStyle(fontSize: 12, color: Colors.purple.shade800),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.purple),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section Title
          const Text(
            'Menu Utama',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // 8-Card Grid Layout (Simetris 2 kolom)
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
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
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
                                color: it.color.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(it.icon, size: 24, color: it.color),
                            ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: it.color.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  it.badge,
                                  style: TextStyle(
                                    fontSize: 10,
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              it.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
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