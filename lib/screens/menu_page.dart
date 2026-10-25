import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/bookmark_service.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import '../widgets/rental_bottom_sheet.dart';
import 'ai_page.dart';
import 'ai_vision_page.dart';
import 'blockchain_page.dart';
import 'book_detail_page.dart';
import 'books_page.dart';
import 'converter_page.dart';
import 'game_page.dart';
import 'map_page.dart';
import 'notification_page.dart';
import 'saved_books_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _user = 'Pembaca';
  int _unreadNotifications = 0;
  final Set<String> _bookmarkedTitles = {};

  // Pencarian
  final TextEditingController _searchController = TextEditingController();
  int _searchMode = 0; // 0 = Judul / Penulis, 1 = Kategori / Genre
  String _selectedGenre = 'Semua Genre';

  // Hero Banner Carousel
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Daftar Kategori Sesuai Gambar Referensi
  final List<String> _genres = const [
    'Semua Genre',
    'Fiksi',
    'Sastra',
    'Romansa',
    'Sejarah',
    'Filosofi',
    'Bisnis',
    'Teknologi',
    'Sains',
  ];

  // Koleksi Buku Terkurasi Kelas Premium (Classy Editorial)
  final List<Map<String, dynamic>> _masterBooks = [
    {
      'title': 'The Book, Think and Grow Rich',
      'authors': 'Napoleon Hill',
      'image': 'https://covers.openlibrary.org/b/id/8231996-L.jpg',
      'category': 'Bisnis',
      'rating': 4.9,
      'pricePerDay': 4000,
      'publishedDate': '1937',
      'publisher': 'The Ralston Society',
      'pageCount': 238,
      'description': 'Sebuah adikarya literatur pengembangan diri dan kesuksesan finansial terpopuler sepanjang masa. Merangkum 13 prinsip sukses yang digali selama lebih dari 20 tahun dari ratusan tokoh sukses dunia.',
    },
    {
      'title': 'The Stranger in the Lifeboat',
      'authors': 'Mitch Albom',
      'image': 'https://covers.openlibrary.org/b/id/12496732-L.jpg',
      'category': 'Fiksi',
      'rating': 4.9,
      'pricePerDay': 4500,
      'publishedDate': '2021',
      'publisher': 'Harper',
      'pageCount': 288,
      'description': 'Kisah naratif yang menggetarkan tentang sekelompok penyintas di atas sekoci penyelamat setelah kapal pesiar mewah tenggelam, hingga mereka menyelamatkan seorang pria asing misterius.',
    },
    {
      'title': 'A Little Life',
      'authors': 'Hanya Yanagihara',
      'image': 'https://covers.openlibrary.org/b/id/10524458-L.jpg',
      'category': 'Sastra',
      'rating': 4.8,
      'pricePerDay': 5000,
      'publishedDate': '2015',
      'publisher': 'Doubleday',
      'pageCount': 720,
      'description': 'Novel mendalam tentang persahabatan empat pemuda di New York yang menelusuri batas kesetiaan, trauma masa lalu, dan daya tahan cinta manusia melewati dekade kehidupan.',
    },
    {
      'title': 'Losing Hope',
      'authors': 'Colleen Hoover',
      'image': 'https://covers.openlibrary.org/b/id/8314115-L.jpg',
      'category': 'Romansa',
      'rating': 4.7,
      'pricePerDay': 4000,
      'publishedDate': '2013',
      'publisher': 'Atria Books',
      'pageCount': 336,
      'description': 'Kisah emosional tentang penebusan, luka masa kecil yang disembunyikan, dan kekuatan kejujuran dalam memulihkan cinta yang sempat hilang.',
    },
    {
      'title': 'Pride and Prejudice',
      'authors': 'Jane Austen',
      'image': 'https://covers.openlibrary.org/b/id/8235114-L.jpg',
      'category': 'Sastra',
      'rating': 4.9,
      'pricePerDay': 3500,
      'publishedDate': '1813',
      'publisher': 'T. Egerton',
      'pageCount': 432,
      'description': 'Klasik sastra dunia tak tertandingi yang mengupas relasi Elizabeth Bennet dan Mr. Darcy di tengah pertarungan gengsi sosial, kesalahpahaman, dan ketulusan nurani.',
    },
    {
      'title': 'The Lion Women of Tehran',
      'authors': 'Marjan Kamali',
      'image': 'https://covers.openlibrary.org/b/id/14589218-L.jpg',
      'category': 'Sejarah',
      'rating': 4.9,
      'pricePerDay': 4500,
      'publishedDate': '2024',
      'publisher': 'Gallery Books',
      'pageCount': 352,
      'description': 'Kisah memikat tentang keberanian dua sahabat perempuan di Tehran yang berjuang meraih pendidikan dan kebebasan di tengah pergolakan sejarah bangsa.',
    },
    {
      'title': 'Bumi Manusia',
      'authors': 'Pramoedya Ananta Toer',
      'image': 'https://covers.openlibrary.org/b/id/8754123-L.jpg',
      'category': 'Sastra',
      'rating': 5.0,
      'pricePerDay': 4500,
      'publishedDate': '1980',
      'publisher': 'Hasta Mitra',
      'pageCount': 535,
      'description': 'Mahakarya sastra Indonesia tentang perlawanan Minke, pemuda pribumi terpelajar yang menolak tunduk di hadapan arogansi kolonialisme akhir abad ke-19.',
    },
    {
      'title': 'Filosofi Teras',
      'authors': 'Henry Manampiring',
      'image': 'https://covers.openlibrary.org/b/id/10234567-L.jpg',
      'category': 'Filosofi',
      'rating': 4.8,
      'pricePerDay': 4000,
      'publishedDate': '2019',
      'publisher': 'Kompas',
      'pageCount': 346,
      'description': 'Panduan praktis stoisisme Yunani-Romawi kuno yang diracik khusus untuk membantu manusia modern menavigasi kecemasan mental dan emosi negatif secara rasional.',
    },
    {
      'title': 'Sapiens: Riwayat Singkat Umat Manusia',
      'authors': 'Yuval Noah Harari',
      'image': 'https://covers.openlibrary.org/b/id/8315121-L.jpg',
      'category': 'Sejarah',
      'rating': 4.9,
      'pricePerDay': 5000,
      'publishedDate': '2014',
      'publisher': 'Harper',
      'pageCount': 443,
      'description': 'Eksplorasi memukau tentang bagaimana spesies kera tak berarti berevolusi menjadi penguasa bumi melalui revolusi kognitif, agrikultur, dan saintifik.',
    },
    {
      'title': 'The Psychology of Money',
      'authors': 'Morgan Housel',
      'image': 'https://covers.openlibrary.org/b/id/10543210-L.jpg',
      'category': 'Bisnis',
      'rating': 4.9,
      'pricePerDay': 4500,
      'publishedDate': '2020',
      'publisher': 'Harriman House',
      'pageCount': 252,
      'description': '19 cerita pendek yang mengeksplorasi relasi ganjil antara perilaku manusia, ego, dan uang, serta bagaimana ketenangan emosi mengalahkan kecerdasan teknis.',
    },
  ];

  List<Map<String, dynamic>> _filteredBooks = [];

  @override
  void initState() {
    super.initState();
    _filteredBooks = List.from(_masterBooks);
    _loadUser();
    _loadNotificationsCount();
    _loadBookmarks();
    _startBannerAutoSlide();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startBannerAutoSlide() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        final next = (_currentBannerIndex + 1) % 4;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _loadUser() async {
    final u = await AuthService.currentSession();
    if (u != null && u.isNotEmpty && mounted) {
      setState(() => _user = u);
    }
  }

  Future<void> _loadNotificationsCount() async {
    final c = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() => _unreadNotifications = c);
    }
  }

  Future<void> _loadBookmarks() async {
    final list = await BookmarkService.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarkedTitles.clear();
        for (final b in list) {
          final t = b['title'] as String?;
          if (t != null) _bookmarkedTitles.add(t.toLowerCase());
        }
      });
    }
  }

  Future<void> _toggleBookmark(Map<String, dynamic> book) async {
    final title = book['title']?.toString() ?? '';
    final isSaved = await BookmarkService.toggleBookmark(book);
    if (!mounted) return;

    setState(() {
      if (isSaved) {
        _bookmarkedTitles.add(title.toLowerCase());
      } else {
        _bookmarkedTitles.remove(title.toLowerCase());
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.oxblood,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          isSaved
              ? '"$title" disimpan ke Buku Tersimpan.'
              : '"$title" dihapus dari Buku Tersimpan.',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.parchment,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _filterBooks() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredBooks = _masterBooks.where((b) {
        // Filter Genre
        final category = (b['category'] as String? ?? '').toLowerCase();
        if (_selectedGenre != 'Semua Genre') {
          if (!category.contains(_selectedGenre.toLowerCase())) {
            return false;
          }
        }

        // Filter Kata Kunci Sesuai Mode
        if (query.isEmpty) return true;

        if (_searchMode == 0) {
          // Mode: Judul / Penulis
          final title = (b['title'] as String? ?? '').toLowerCase();
          final author = (b['authors'] as String? ?? '').toLowerCase();
          return title.contains(query) || author.contains(query);
        } else {
          // Mode: Kategori / Genre
          return category.contains(query);
        }
      }).toList();
    });
  }

  void _selectGenre(String genre) {
    setState(() {
      _selectedGenre = genre;
    });
    _filterBooks();
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
      const days = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      final now = DateTime.now();
      return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    }
  }

  String _formatNumber(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  @override
  Widget build(BuildContext context) {
    void go(Widget w) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.oxblood,
          backgroundColor: AppColors.parchment,
          onRefresh: () async {
            await _loadUser();
            await _loadNotificationsCount();
            await _loadBookmarks();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ============================================================
              // 1. APP BAR & USER HEADER (EDITORIAL & CLASSY)
              // ============================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      // User Avatar & Name
                      GestureDetector(
                        onTap: () => go(const SavedBooksPage()),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.oxblood,
                            border: Border.all(
                              color: AppColors.agedPaper,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.walnut.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _user.isNotEmpty ? _user[0].toUpperCase() : 'P',
                              style: GoogleFonts.playfairDisplay(
                                color: AppColors.parchment,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _user,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.walnut,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2E7D32),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatToday(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Icons: Heart (Saved), Panduan ?, Notification Bell
                      IconButton(
                        tooltip: 'Buku Tersimpan',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.bookmark_border_rounded,
                          color: AppColors.walnut,
                          size: 24,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SavedBooksPage(),
                            ),
                          );
                          _loadBookmarks();
                        },
                      ),
                      IconButton(
                        tooltip: 'Panduan Perpustakaan',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.help_outline_rounded,
                          color: AppColors.walnut,
                          size: 24,
                        ),
                        onPressed: _showHelpDialog,
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            tooltip: 'Pemberitahuan & Promo',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.walnut,
                              size: 24,
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationPage(),
                                ),
                              );
                              _loadNotificationsCount();
                            },
                          ),
                          if (_unreadNotifications > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC0392B),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 17,
                                  minHeight: 17,
                                ),
                                child: Text(
                                  '$_unreadNotifications',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ============================================================
              // 2. DUAL-MODE SEARCH BAR (CLASSY & CLEAN)
              // ============================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.walnut.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _filterBooks(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.walnut,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: _searchMode == 0
                                ? 'Cari judul buku atau penulis...'
                                : 'Cari kategori atau genre buku...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: const Color(0xFF9E8B7E),
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 14, right: 10),
                              child: Icon(
                                Icons.search_rounded,
                                color: AppColors.tobacco,
                                size: 22,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 44,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFF9E8B7E),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterBooks();
                                    },
                                  ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _searchMode = _searchMode == 0 ? 1 : 0;
                                    });
                                    _filterBooks();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.parchment,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.agedPaper.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _searchMode == 0
                                              ? Icons.menu_book_rounded
                                              : Icons.category_rounded,
                                          size: 13,
                                          color: AppColors.oxblood,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _searchMode == 0
                                              ? 'Judul'
                                              : 'Kategori',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.oxblood,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtle Mode Toggle Hint
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Mode: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _searchMode = 0);
                              _filterBooks();
                            },
                            child: Text(
                              'Judul / Penulis',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: _searchMode == 0
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _searchMode == 0
                                    ? AppColors.oxblood
                                    : AppColors.textSecondary,
                                decoration: _searchMode == 0
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                          Text(
                            '  •  ',
                            style: TextStyle(
                              color: AppColors.border,
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _searchMode = 1);
                              _filterBooks();
                            },
                            child: Text(
                              'Kategori / Genre',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: _searchMode == 1
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _searchMode == 1
                                    ? AppColors.oxblood
                                    : AppColors.textSecondary,
                                decoration: _searchMode == 1
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ============================================================
              // 3. SLIDING HERO CAROUSEL BANNER (PROMO / VOUCHER / BOOK)
              // ============================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 172,
                        child: PageView(
                          controller: _bannerController,
                          onPageChanged: (i) =>
                              setState(() => _currentBannerIndex = i),
                          children: [
                            _buildHeroBannerCard(
                              tag: 'Pilihan Minggu Ini',
                              title: 'Think and Grow Rich',
                              subtitle: 'Napoleon Hill (1937)',
                              caption: 'Prinsip abadi ketangguhan & kesuksesan',
                              actionLabel: 'Sewa Buku',
                              bgGradient: const [
                                Color(0xFFF6EEDB),
                                Color(0xFFECE0CA),
                              ],
                              borderColor: const Color(0xFFDCCBB1),
                              accentColor: const Color(0xFFB45309),
                              bookCover: 'https://covers.openlibrary.org/b/id/8231996-L.jpg',
                              onAction: () => RentalBottomSheet.show(
                                context,
                                _masterBooks[0],
                              ),
                            ),
                            _buildHeroBannerCard(
                              tag: 'Voucher Diskon 10%',
                              title: 'Kode: DISKON10',
                              subtitle: 'Potongan Sewa Buku',
                              caption: 'Gunakan kode DISKON10 di ringkasan pembayaran.',
                              actionLabel: 'Salin Kode',
                              bgGradient: const [
                                Color(0xFFF7EBEB),
                                Color(0xFFF1D8D8),
                              ],
                              borderColor: const Color(0xFFE5BFBF),
                              accentColor: AppColors.oxblood,
                              iconGraphic: Icons.local_offer_outlined,
                              onAction: () {
                                Clipboard.setData(
                                  const ClipboardData(text: 'DISKON10'),
                                );
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Kode voucher DISKON10 berhasil disalin!',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.parchment,
                                      ),
                                    ),
                                    backgroundColor: AppColors.oxblood,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            _buildHeroBannerCard(
                              tag: 'Karya Klasik Indonesia',
                              title: 'Bumi Manusia',
                              subtitle: 'Pramoedya Ananta Toer',
                              caption: 'Roman legendaris Tetralogi Buru yang mendunia.',
                              actionLabel: 'Sewa Buku',
                              bgGradient: const [
                                Color(0xFFF3ECE4),
                                Color(0xFFE8DCCE),
                              ],
                              borderColor: const Color(0xFFDAC7B4),
                              accentColor: AppColors.tobacco,
                              bookCover: 'https://covers.openlibrary.org/b/id/8754123-L.jpg',
                              onAction: () => RentalBottomSheet.show(
                                context,
                                _masterBooks[6],
                              ),
                            ),
                            _buildHeroBannerCard(
                              tag: 'Akses Eksklusif VIP',
                              title: 'RentBook VIP Club',
                              subtitle: 'Rp 29.000 / 30 Hari',
                              caption: 'Akses Labirin Game, AI Vision, dan Konversi Kurs.',
                              actionLabel: 'Gabung VIP',
                              bgGradient: const [
                                Color(0xFFFAF0E2),
                                Color(0xFFF3DFC4),
                              ],
                              borderColor: const Color(0xFFE6CCA5),
                              accentColor: const Color(0xFF8C581E),
                              iconGraphic: Icons.workspace_premium_rounded,
                              onAction: () =>
                                  SubscriptionService.showPaywallDialog(
                                    context,
                                    featureName: 'Keanggotaan VIP RentBook',
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Dot Indicators (Active dot is elongated)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final isCur = _currentBannerIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isCur ? 22 : 6,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isCur
                                  ? AppColors.oxblood
                                  : AppColors.agedPaper.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // ============================================================
              // 4. HORIZONTAL CATEGORY / GENRE TABS (WITH ACTIVE DOT BELOW)
              // ============================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _genres.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 18),
                      itemBuilder: (context, i) {
                        final g = _genres[i];
                        final isSel = _selectedGenre == g;
                        return GestureDetector(
                          onTap: () => _selectGenre(g),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                g,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSel
                                      ? AppColors.walnut
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Small dot indicator under active item (Exact match to reference UI)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppColors.oxblood
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ============================================================
              // 5. 2-COLUMN BOOK GRID ("DUA-DUA GITU")
              // ============================================================
              if (_filteredBooks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.agedPaper,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada buku yang sesuai dengan pencarian.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.61, // Aspect ratio ideal untuk cover buku vertikal
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final book = _filteredBooks[index];
                      final title = book['title']?.toString() ?? '';
                      final isSaved = _bookmarkedTitles.contains(
                        title.toLowerCase(),
                      );
                      return _buildBookCard(book, isSaved);
                    }, childCount: _filteredBooks.length),
                  ),
                ),

              // ============================================================
              // 6. "SEDANG DIBACA" (CONTINUE READING)
              // ============================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sedang Dibaca',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.walnut,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => go(const SavedBooksPage()),
                            child: Row(
                              children: [
                                Text(
                                  'Lihat Semua',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.oxblood,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: AppColors.oxblood,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildContinueReadingCard(),
                    ],
                  ),
                ),
              ),

              // ============================================================
              // 7. LAYANAN & FITUR PERPUSTAKAAN (ZERO EMOJIS, CLASSY)
              // ============================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3.5,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.oxblood,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Layanan & Fitur Perpustakaan',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.walnut,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildServicesGrid(go),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGET: HERO BANNER CARD
  // =========================================================================
  Widget _buildHeroBannerCard({
    required String tag,
    required String title,
    required String subtitle,
    required String caption,
    required String actionLabel,
    required List<Color> bgGradient,
    required Color borderColor,
    required Color accentColor,
    required VoidCallback onAction,
    String? bookCover,
    IconData? iconGraphic,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.walnut.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Text Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tag pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.walnut,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onAction,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Right Graphic (3D Book Cover or Icon badge)
          if (bookCover != null)
            Container(
              width: 74,
              height: 108,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(4, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  bookCover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.oxblood,
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 10,
                          color: AppColors.parchment,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (iconGraphic != null)
            Container(
              width: 74,
              height: 108,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Icon(iconGraphic, size: 40, color: accentColor),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGET: 2-COLUMN BOOK CARD ("DUA-DUA GITU")
  // =========================================================================
  Widget _buildBookCard(Map<String, dynamic> book, bool isSaved) {
    final title = book['title']?.toString() ?? 'Tanpa Judul';
    final authors = book['authors']?.toString() ?? 'Penulis';
    final price = book['pricePerDay'] is int
        ? book['pricePerDay'] as int
        : 4000;
    final rating = (book['rating'] as num?)?.toDouble() ?? 4.9;
    final image = book['image'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: AppColors.walnut.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: READ NOW badge + Rating + Bookmark Heart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // READ NOW badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.parchment,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SEWA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.oxblood,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Rating
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFD4AF37),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.walnut,
                          ),
                        ),
                      ],
                    ),
                    // Bookmark Heart
                    GestureDetector(
                      onTap: () => _toggleBookmark(book),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 17,
                          color: isSaved
                              ? AppColors.oxblood
                              : const Color(0xFF9E8B7E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Book Cover with 3D drop shadow
                Expanded(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(3, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 0.68,
                          child: image != null
                              ? Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildFallbackCover(title),
                                )
                              : _buildFallbackCover(title),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Title (Serif Elegance)
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.walnut,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),

                // Author
                Text(
                  'oleh $authors',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),

                // Price Tag
                Text(
                  'Rp ${_formatNumber(price)} / hari',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oxblood,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCover(String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.oxblood, Color(0xFF4C272C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: 10,
            color: AppColors.parchment,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGET: "SEDANG DIBACA" (CONTINUE READING CARD)
  // =========================================================================
  Widget _buildContinueReadingCard() {
    final featured = _masterBooks[0];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: AppColors.walnut.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 52,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                featured['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.oxblood,
                  child: const Icon(
                    Icons.menu_book,
                    color: AppColors.parchment,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.parchment,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AKTIF DIBACA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.oxblood,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFD4AF37),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '4.9',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.walnut,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  featured['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.walnut,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bab 4: Iman & Visualisasi Tujuan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0.42,
                          minHeight: 5,
                          backgroundColor: AppColors.parchment,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.oxblood,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '42%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.oxblood,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGET: LAYANAN & FITUR PERPUSTAKAAN (ZERO EMOJIS, CLASSY)
  // =========================================================================
  Widget _buildServicesGrid(void Function(Widget) go) {
    final services = [
      _ServiceItem(
        title: 'Cari & Sewa Buku',
        desc: 'Katalog ribuan buku & sensor shake',
        badge: 'Katalog',
        icon: Icons.auto_stories_rounded,
        color: AppColors.oxblood,
        onTap: () => go(const BooksPage()),
      ),
      _ServiceItem(
        title: 'Buku Tersimpan',
        desc: 'Daftar bacaan & koleksi favorit',
        badge: 'Favorit',
        icon: Icons.bookmark_added_rounded,
        color: AppColors.tobacco,
        onTap: () => go(const SavedBooksPage()),
      ),
      _ServiceItem(
        title: 'Asisten AI Kurator',
        desc: 'Rekomendasi bacaan cerdas LLM',
        badge: 'AI Gemini',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF5A2A38),
        onTap: () => go(const AiPage()),
      ),
      _ServiceItem(
        title: 'Scan Cover Buku',
        desc: 'Deteksi kamera & sampul AI Vision',
        badge: 'VIP',
        icon: Icons.camera_enhance_rounded,
        color: const Color(0xFF4C3B71),
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Scan Cover Buku',
          onAllowed: () => go(const AiVisionPage()),
        ),
      ),
      _ServiceItem(
        title: 'Labirin Perpustakaan',
        desc: 'Minigame arcade buku & voucher',
        badge: 'VIP',
        icon: Icons.sports_esports_rounded,
        color: const Color(0xFFB45309),
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Labirin Perpustakaan',
          onAllowed: () => go(const GamePage()),
        ),
      ),
      _ServiceItem(
        title: 'Perpustakaan Terdekat',
        desc: 'Peta cabang perpustakaan & GPS',
        badge: 'GPS Map',
        icon: Icons.location_on_rounded,
        color: const Color(0xFF43634B),
        onTap: () => go(const MapPage()),
      ),
      _ServiceItem(
        title: 'Riwayat Blockchain',
        desc: 'Buku besar transaksi SHA-256',
        badge: 'SHA-256',
        icon: Icons.lock_clock_rounded,
        color: const Color(0xFF7C3F2B),
        onTap: () => go(const BlockchainPage()),
      ),
      _ServiceItem(
        title: 'Konversi Kurs & Jam',
        desc: 'Kalkulator mata uang & jam dunia',
        badge: 'VIP',
        icon: Icons.currency_exchange_rounded,
        color: const Color(0xFF3B506B),
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Konversi Kurs & Jam',
          onAllowed: () => go(const ConverterPage()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, i) {
        final s = services[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: AppColors.walnut.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: s.onTap,
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
                            color: s.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s.icon, size: 20, color: s.color),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.badge,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: s.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.walnut,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
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
    );
  }
}

class _ServiceItem {
  final String title;
  final String desc;
  final String badge;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ServiceItem({
    required this.title,
    required this.desc,
    required this.badge,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// =========================================================================
// DIALOG BUKU PANDUAN PERPUSTAKAAN INTERAKTIF (LEMBARAN DAPAT DIBALIK)
// =========================================================================
class _LibraryBookGuideDialog extends StatefulWidget {
  const _LibraryBookGuideDialog();

  @override
  State<_LibraryBookGuideDialog> createState() =>
      _LibraryBookGuideDialogState();
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
            color: const Color(0xFF5A252C),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
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
              // Pita Pembatas Buku Merah Sutra
              Positioned(
                top: -14,
                right: 32,
                child: Container(
                  width: 20,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B2635),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bookmark_rounded,
                      color: Color(0xFFF1E6D4),
                      size: 14,
                    ),
                  ),
                ),
              ),

              // Lembaran Buku Bertekstur Kertas Tua
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEADBCE),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Header Buku
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE2CF).withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        border: const Border(
                          bottom: BorderSide(color: Color(0xFFEADBCE)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            color: Color(0xFF67343A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Panduan RentBook',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 15,
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
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Color(0xFF67343A),
                              ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE2CF).withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                        border: const Border(
                          top: BorderSide(color: Color(0xFFEADBCE)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF67343A),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: _currentPage > 0
                                ? _prevPage
                                : () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 13,
                            ),
                            label: Text(
                              'Kembali',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Indikator Halaman
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEADBCE),
                              ),
                            ),
                            child: Text(
                              'Hal ${_currentPage + 1} dari $_totalPages',
                              style: GoogleFonts.plusJakartaSans(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _nextPage,
                            label: Text(
                              _currentPage == _totalPages - 1
                                  ? 'Selesai'
                                  : 'Lanjut',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            icon: Icon(
                              _currentPage == _totalPages - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_ios_rounded,
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
          desc: 'Jelajahi ribuan koleksi sastra, teknologi, dan sejarah. Gunakan bilah pencarian cerdas untuk memfilter berdasarkan judul, penulis, atau genre.',
        ),
        _buildSectionItem(
          title: 'Fitur Shake Perangkat (Goyang HP)',
          desc: 'Goyangkan ponsel Anda di halaman Katalog Buku untuk mendapatkan rekomendasi buku acak secara instan dengan sensor akselerometer!',
        ),
        _buildSectionItem(
          title: 'Peta Perpustakaan & GPS',
          desc: 'Temukan lokasi cabang perpustakaan terdekat lengkap dengan rute interaktif dan jarak tempuh real-time.',
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
          title: 'Pembayaran QRIS Cepat',
          desc: 'Pindai kode QRIS menggunakan e-Wallet (GoPay, OVO, Dana) atau Mobile Banking. Pembayaran terverifikasi aman dan dapat dicek langsung ke buku besar blockchain.',
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
          desc: 'Buka fitur "Riwayat Blockchain" untuk memverifikasi keaslian transaksi, waktu simpan, dan tanda tangan hash kriptografis Anda.',
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
          desc: 'Konsultasikan bacaan Anda dengan AI Kurator. AI dapat merangkum sinopsis, menganalisis tokoh buku, dan memberikan saran bacaan sesuai minat Anda.',
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
          desc: 'Taklukkan labirin 3 lantai, kumpulkan buku-buku di lorong, dan raih Buku Emas beserta voucher diskon spesial.',
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
                  style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.playfairDisplay(
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
                  style: GoogleFonts.plusJakartaSans(
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
              style: GoogleFonts.plusJakartaSans(
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
