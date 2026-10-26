import 'dart:io';

import 'package:intl/intl.dart';

import '../services/db_helper.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import 'ai_page.dart';
import 'ai_vision_page.dart';
import 'blockchain_page.dart';
import 'book_detail_page.dart';
import 'books_page.dart';
import 'converter_page.dart';
import 'game_page.dart';
import 'map_page.dart';
import 'notification_page.dart';
import 'profile_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _user = 'rahma';
  String? _userPhoto;
  bool _isVip = false;
  int _unreadNotifications = 0;
  String? _lastRentedGenre;

  // Banner Carousel
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Buku Project Hail Mary Khusus Banner
  final Map<String, dynamic> _projectHailMaryBook = {
    'title': 'Project Hail Mary',
    'authors': 'Andy Weir',
    'image': 'https://covers.openlibrary.org/b/id/11183350-L.jpg',
    'category': 'Fiksi Ilmiah',
    'rating': 4.9,
    'pricePerDay': 6000,
    'publishedDate': '2021',
    'publisher': 'Ballantine Books',
    'pageCount': 496,
    'description': 'Ryland Grace adalah satu-satunya penyintas dalam misi keputusasaan terakhir untuk menyelamatkan bumi dari kepunahan. Jauh dari rumah, sendirian di antara bintang-bintang. Bahkan di tempat paling asing sekalipun, kita masih bisa menemukan teman.',
  };

  // Koleksi Buku Terkurasi
  final List<Map<String, dynamic>> _masterBooks = [
    {
      'title': 'As Long as the Lemon Trees Grow',
      'authors': 'Zoulfa Katouh',
      'image': 'https://cdn.gramedia.com/uploads/product-metas/ese--a5-o2.jpeg',
      'category': 'Sejarah',
      'rating': 4.9,
      'pricePerDay': 4000,
      'publishedDate': '2022',
      'publisher': 'Bloomsbury Publishing',
      'pageCount': 448,
      'description': 'Salama, mahasiswi farmasi yang menjadi relawan di rumah sakit Homs selama Revolusi Suriah, berjuang memilih antara meninggalkan tanah air demi keselamatan atau bertahan membantu sesama. Di tengah konflik dan kehilangan, ia menemukan harapan serta cinta.',
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

  List<Map<String, dynamic>> _recommendedBooks = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadNotificationsCount();
    _loadLastRentedGenre();
    _startBannerAutoSlide();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
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
    String? photo;
    String? displayName;
    if (u != null && u.isNotEmpty) {
      try {
        final rows = await (await DbHelper.db).query(
          'users',
          where: 'username=?',
          whereArgs: [u],
        );
        if (rows.isNotEmpty) {
          photo = rows.first['photo'] as String?;
          displayName = rows.first['display_name'] as String?;
        }
      } catch (_) {}
    }
    final isVip = await SubscriptionService.isVip();
    if (mounted) {
      setState(() {
        if (u != null && u.isNotEmpty) {
          _user = displayName?.trim().isNotEmpty == true
              ? displayName!.trim()
              : u;
        }
        _userPhoto = photo;
        _isVip = isVip;
      });
    }
  }

  Future<void> _loadNotificationsCount() async {
    final c = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() => _unreadNotifications = c);
    }
  }

  Future<void> _loadLastRentedGenre() async {
    final user = await AuthService.currentSession() ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    final genre = prefs.getString('last_rented_genre_$user');
    if (mounted) {
      setState(() {
        _lastRentedGenre = genre;
        _updateRecommendedBooks();
      });
    }
  }

  void _updateRecommendedBooks() {
    if (_lastRentedGenre != null && _lastRentedGenre!.isNotEmpty) {
      final matching = _masterBooks.where((b) {
        final cat = (b['category'] as String? ?? '').toLowerCase();
        return cat.contains(_lastRentedGenre!.toLowerCase());
      }).toList();

      final others = _masterBooks.where((b) {
        final cat = (b['category'] as String? ?? '').toLowerCase();
        return !cat.contains(_lastRentedGenre!.toLowerCase());
      }).toList();

      _recommendedBooks = [
        ...matching,
        _projectHailMaryBook,
        ...others,
      ].take(5).toList();
    } else {
      _recommendedBooks = [
        _projectHailMaryBook,
        _masterBooks[0], // Think and Grow Rich
        _masterBooks[2], // Bumi Manusia
        _masterBooks[1], // The Stranger in the Lifeboat
        _masterBooks[3], // Filosofi Teras
      ];
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _LibraryBookGuideDialog(),
    );
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
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.oxblood,
          backgroundColor: AppColors.parchment,
          onRefresh: () async {
            await _loadUser();
            await _loadNotificationsCount();
            await _loadLastRentedGenre();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF67343A),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris Profil Pengguna, Ikon Panduan & Notifikasi
                      Container(
                        color: const Color(0xFF4C272C),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Avatar bulat mengikuti ProfilePage (diklik mengarah ke ProfilePage)
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfilePage(),
                                    ),
                                  );
                                  _loadUser();
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFEDE2CF),
                                    border: Border.all(
                                      color: const Color(0xFFD4BE9D),
                                      width: 1.8,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child:
                                        (_userPhoto != null &&
                                            File(_userPhoto!).existsSync())
                                        ? Image.file(
                                            File(_userPhoto!),
                                            fit: BoxFit.cover,
                                            width: 44,
                                            height: 44,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                _user.isNotEmpty
                                                    ? _user[0].toUpperCase()
                                                    : 'R',
                                                style:
                                                    GoogleFonts.playfairDisplay(
                                                      color: const Color(
                                                        0xFF67343A,
                                                      ),
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              _user.isNotEmpty
                                                  ? _user[0].toUpperCase()
                                                  : 'R',
                                              style:
                                                  GoogleFonts.playfairDisplay(
                                                    color: const Color(
                                                      0xFF67343A,
                                                    ),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Tanggal / Status Keanggotaan
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ProfilePage(),
                                      ),
                                    );
                                    _loadUser();
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'EEEE, d MMM yyyy',
                                          'id_ID',
                                        ).format(DateTime.now()),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFD4BE9D),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isVip ? 'VIP Member' : 'Anggota',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFEDE2CF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Ikon Panduan '?'
                              IconButton(
                                tooltip: 'Panduan RentBook',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.help_outline_rounded,
                                  color: Color(0xFFEDE2CF),
                                  size: 24,
                                ),
                                onPressed: _showHelpDialog,
                              ),

                              // Ikon Lonceng Notifikasi (Bell) dengan Badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    tooltip: 'Pemberitahuan & Promo',
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Color(0xFFEDE2CF),
                                      size: 24,
                                    ),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationPage(),
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
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFC0392B),
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          '$_unreadNotifications',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
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

                      // Teks: Selamat Datang [user]! dan subteks Temukan bacaan yang mungkin kamu sukai
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat datang $_user!',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEDE2CF),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Temukan bacaan yang mungkin kamu sukai.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: const Color(0xFFD4BE9D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. BANNER CAROUSEL (DENGAN SHADOW AGAR TIDAK MENYATU DENGAN HEADERBAR)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  height: 168,
                                  child: PageView(
                                    controller: _bannerController,
                                    onPageChanged: (i) =>
                                        setState(() => _currentBannerIndex = i),
                                    children: [
                                      // Banner 1: Selamat Datang (Arahkan ke Katalog Buku)
                                      _buildImageBanner(
                                        imagePath:
                                            'assets/images/banner_welcome.png',
                                        onTap: () => go(const BooksPage()),
                                      ),

                                      // Banner 2: Game Labirin (Arahkan ke Menu Game / Cek VIP)
                                      _buildImageBanner(
                                        imagePath:
                                            'assets/images/banner_game.png',
                                        onTap: () {
                                          SubscriptionService.checkAccess(
                                            context,
                                            featureName: 'Labirin Perpustakaan',
                                            onAllowed: () =>
                                                go(const GamePage()),
                                          );
                                        },
                                      ),

                                      // Banner 3: Buku Project Hail Mary (Arahkan ke Detail Hail Mary)
                                      _buildImageBanner(
                                        imagePath: 'assets/images/banner_hail_mary.png',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BookDetailPage(
                                                book: _projectHailMaryBook,
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      // Banner 4: VIP Membership (Langsung Pop up Upgrade VIP)
                                      _buildImageBanner(
                                        imagePath:
                                            'assets/images/banner_vip.png',
                                        onTap: () {
                                          SubscriptionService.showPaywallDialog(
                                            context,
                                            featureName: 'Membership VIP',
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Indikator Titik-Titik (...)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                final isCur = _currentBannerIndex == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: isCur ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isCur
                                        ? const Color(0xFFEDE2CF)
                                        : const Color(0xFFD4BE9D)
                                              .withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ============================================================
                // 3. EKSPLOR FITUR RENTBOOK (MENU GOJEK STYLE: 3 ATAS, 3 BAWAH)
                // ============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    'Eksplor fitur Rentbook',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF302622),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildServicesGrid(go),
                ),

                const SizedBox(height: 24),

                // ============================================================
                // 4. CHATBOT KURATOR BUKU AI (LANGSUNG SETELAH EKSPLOR FITUR)
                // ============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => go(const AiPage()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF67343A), Color(0xFF4C272C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF67343A)
                                  .withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFAF7F2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF67343A),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Asisten Buku AI',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFEDE2CF),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cari rekomendasi bacaan dan tanya sinopsis.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFFEDE2CF)
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE2CF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Tanya AI',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF67343A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // ============================================================
                // 5. PILIHAN UNTUKMU (BUKU-BUKU REKOMENDASI SETELAH CHATBOT)
                // ============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilihan untukmu',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF302622),
                            ),
                          ),
                          if (_lastRentedGenre != null &&
                              _lastRentedGenre!.isNotEmpty)
                            Text(
                              'Berdasarkan bacaan terakhir: $_lastRentedGenre',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF9A704F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => go(const BooksPage()),
                        child: Text(
                          'Lihat Semua',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF67343A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Daftar Kartu Buku Rekomendasi Horizontal
                SizedBox(
                  height: 228,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: _recommendedBooks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final b = _recommendedBooks[i];
                      return _buildRecommendedBookCard(b);
                    },
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGET: BANNER GAMBAR NYATA
  // =========================================================================
  Widget _buildImageBanner({
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF67343A),
              child: const Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFFEDE2CF),
                  size: 36,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGET: KARTU BUKU REKOMENDASI HARI INI
  // =========================================================================
  Widget _buildRecommendedBookCard(Map<String, dynamic> b) {
    final title = b['title']?.toString() ?? 'Buku';
    final authors = b['authors']?.toString() ?? 'Penulis';
    final price = b['pricePerDay'] is int ? b['pricePerDay'] as int : 4000;
    final rating = (b['rating'] as num?)?.toDouble() ?? 4.9;
    final img = b['image'] as String?;

    return Container(
      width: 136,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF302622).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookDetailPage(book: b)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Buku dengan Bayangan
                Expanded(
                  child: Center(
                    child: Container(
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
                        child: AspectRatio(
                          aspectRatio: 0.7,
                          child: img != null
                              ? Image.network(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildFallbackMiniCover(title),
                                )
                              : _buildFallbackMiniCover(title),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Judul
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF302622),
                  ),
                ),

                // Penulis
                Text(
                  authors,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF7A685A),
                  ),
                ),
                const SizedBox(height: 3),

                // Harga & Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp ${_formatNumber(price)}/hr',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF67343A),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Color(0xFFD4AF37),
                        ),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF302622),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackMiniCover(String title) {
    return Container(
      color: const Color(0xFF67343A),
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: 9,
            color: const Color(0xFFEDE2CF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 1. Gambar untuk Fitur Cari & Sewa Buku:
  static const String pathGambarCariBuku = 'assets/images/cari dan sewa.png';

  // 2. Gambar untuk Fitur Kenali Buku (Pindai Cover):
  static const String pathGambarKenaliBuku = 'assets/images/kenali buku.png';

  // 3. Gambar untuk Fitur Labirin Game:
  static const String? pathGambarLabirinGame = 'assets/images/labirin.png';

  // 4. Gambar untuk Fitur Perpustakaan GPS:
  static const String? pathGambarPerpustakaanGps = 'assets/images/gps.png';

  // 5. Gambar untuk Fitur Riwayat Blockchain:
  static const String? pathGambarRiwayatBlockchain =
      'assets/images/blockchain.png';

  // 6. Gambar untuk Fitur Konversi Kurs:
  static const String? pathGambarKonversiKurs = 'assets/images/konversi.png';

  // =========================================================================
  // WIDGET: EKSPLOR FITUR RENTBOOK
  // =========================================================================
  Widget _buildServicesGrid(void Function(Widget) go) {
    final services = [
      _ServiceItem(
        title: 'Cari Buku',
        imageAsset: pathGambarCariBuku,
        fallbackIcon: Icons.menu_book_rounded,
        fallbackColor: const Color(0xFF67343A),
        onTap: () => go(const BooksPage()),
      ),
      _ServiceItem(
        title: 'Perpustakaan GPS',
        imageAsset: pathGambarPerpustakaanGps,
        fallbackIcon: Icons.location_on_rounded,
        fallbackColor: const Color(0xFF43634B),
        onTap: () => go(const MapPage()),
      ),
      _ServiceItem(
        title: 'Riwayat Blockchain',
        imageAsset: pathGambarRiwayatBlockchain,
        fallbackIcon: Icons.lock_clock_rounded,
        fallbackColor: const Color(0xFF7C3F2B),
        onTap: () => go(const BlockchainPage()),
      ),
      _ServiceItem(
        title: 'Kenali Buku',
        imageAsset: pathGambarKenaliBuku,
        fallbackIcon: Icons.camera_enhance_rounded,
        fallbackColor: const Color(0xFF4C3B71),
        requiresVip: true,
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Kenali Buku',
          onAllowed: () => go(const AiVisionPage()),
          onSubscribed: () => _loadUser(),
        ),
      ),
      _ServiceItem(
        title: 'Labirin Game',
        imageAsset: pathGambarLabirinGame,
        fallbackIcon: Icons.sports_esports_rounded,
        fallbackColor: const Color(0xFFB45309),
        requiresVip: true,
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Labirin Perpustakaan',
          onAllowed: () => go(const GamePage()),
          onSubscribed: () => _loadUser(),
        ),
      ),
      _ServiceItem(
        title: 'Konversi Kurs & Jam',
        imageAsset: pathGambarKonversiKurs,
        fallbackIcon: Icons.currency_exchange_rounded,
        fallbackColor: const Color(0xFF3B506B),
        requiresVip: true,
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Konversi Kurs & Jam',
          onAllowed: () => go(const ConverterPage()),
          onSubscribed: () => _loadUser(),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        mainAxisExtent: 104,
      ),
      itemBuilder: (context, i) {
        final s = services[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: s.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EAE1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        s.imageAsset != null
                            ? Image.asset(
                                s.imageAsset!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _buildFallbackServiceIllustration(s),
                              )
                            : _buildFallbackServiceIllustration(s),
                        if (s.requiresVip && !_isVip)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xCC302622),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFFEDE2CF),
                                  size: 22,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'VIP',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFD4AF37),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      color: const Color(0xFF302622),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackServiceIllustration(_ServiceItem s) {
    return Container(
      decoration: BoxDecoration(
        color: s.fallbackColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: s.fallbackColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(s.fallbackIcon, size: 26, color: s.fallbackColor),
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final String? imageAsset;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final VoidCallback onTap;
  final bool requiresVip;

  _ServiceItem({
    required this.title,
    this.imageAsset,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.onTap,
    this.requiresVip = false,
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
          desc: 'Jelajahi ribuan koleksi sastra, teknologi, dan sejarah. Gunakan bilah pencarian cerdas untuk memfilter berdasarkan judul atau pengarang.',
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
