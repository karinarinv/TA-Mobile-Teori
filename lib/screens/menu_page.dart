
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
import 'book_detail_page.dart';
import 'books_page.dart';
import 'converter_page.dart';
import 'map_page.dart';
import 'notification_page.dart';
import 'profile_page.dart';
import 'rental_history_page.dart';
import '../widgets/rental_bottom_sheet.dart';

/// Beranda: profil singkat, notifikasi, banner, buku rekomendasi, dan pintasan fitur.
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Data akun yang dipakai di sapaan, avatar, dan rekomendasi.
  String _user = 'rahma';
  String? _userPhoto;
  int _unreadNotifications = 0;
  int _rentalCount = 0;
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
    RentalBottomSheet.rentalUpdateNotifier.addListener(_loadUser);
    _loadNotificationsCount();
    _loadLastRentedGenre();
    _startBannerAutoSlide();
  }

  @override
  void dispose() {
    RentalBottomSheet.rentalUpdateNotifier.removeListener(_loadUser);
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerAutoSlide() {
    // Ganti banner otomatis setiap 4 detik dan hentikan timer saat halaman ditutup.
    // Geser ke banner berikutnya setiap 4 detik; perpindahannya berlangsung 450 ms.
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        final next = (_currentBannerIndex + 1) % 2;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _loadUser() async {
    // Ambil username, foto, dan total transaksi sewa aktif dari SQLite.
    final u = await AuthService.currentSession();
    String? photo;
    int rentalCount = 0;
    if (u != null && u.isNotEmpty) {
      try {
        final db = await DbHelper.db;
        final rows = await db.query(
          'users',
          where: 'username=?',
          whereArgs: [u],
        );
        if (rows.isNotEmpty) {
          photo = rows.first['photo'] as String?;
        }
        final txRows = await db.query(
          'riwayat_transaksi',
          where: 'username=?',
          whereArgs: [u],
        );
        rentalCount = txRows.length;
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        if (u != null && u.isNotEmpty) _user = u;
        _userPhoto = photo;
        _rentalCount = rentalCount;
      });
    }
  }

  Future<void> _loadNotificationsCount() async {
    // Perbarui angka badge dari jumlah notifikasi yang belum dibaca.
    final c = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() => _unreadNotifications = c);
    }
  }

  Future<void> _loadLastRentedGenre() async {
    // Genre sewa terakhir dipakai untuk mengurutkan rekomendasi buku.
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
    // Dahulukan buku dengan genre sama, lalu tambahkan genre lainnya.
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
      // WARNA: latar belakang utama halaman Beranda (MenuPage).
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: RefreshIndicator(
          // WARNA: warna panah indikator tarik-untuk-refresh di halaman Beranda.
          color: AppColors.oxblood,
          // WARNA: warna latar lingkaran indikator tarik-untuk-refresh di halaman Beranda.
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
                    // WARNA: latar belakang kartu header besar di bagian atas Beranda (area sapaan 'Selamat datang' & banner carousel).
                    color: Color(0xFF67343A),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        // WARNA: bayangan di bawah kartu header besar bagian atas Beranda.
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
                        // WARNA: latar bar paling atas di Beranda (tempat avatar, tanggal, status anggota, ikon '?', dan lonceng notifikasi) — marun lebih gelap.
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
                                    // WARNA: latar lingkaran avatar foto profil pengguna di bar paling atas Beranda (krem parchment).
                                    color: const Color(0xFFEDE2CF),
                                    border: Border.all(
                                      // WARNA: garis tepi lingkaran avatar foto profil pengguna di bar paling atas Beranda (emas krem).
                                      color: const Color(0xFFD4BE9D),
                                      width: 1.8,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        // WARNA: bayangan di bawah lingkaran avatar foto profil di bar atas Beranda.
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
                                                      // WARNA: warna huruf inisial fallback di dalam lingkaran avatar (saat file foto gagal dimuat) di bar atas Beranda.
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
                                                    // WARNA: warna huruf inisial di dalam lingkaran avatar (saat user belum punya foto profil) di bar atas Beranda.
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
                                          // WARNA: warna teks tanggal hari ini di sebelah avatar pada bar atas Beranda.
                                          color: const Color(0xFFD4BE9D),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Anggota Perpustakaan',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          // WARNA: warna teks 'Anggota Perpustakaan' di bawah tanggal pada bar atas Beranda.
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
                                  // WARNA: warna ikon tanda tanya (?) tombol Panduan RentBook di pojok kanan bar atas Beranda.
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
                                      // WARNA: warna ikon lonceng notifikasi di pojok kanan bar atas Beranda.
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
                                          // WARNA: latar lingkaran merah badge jumlah notifikasi belum dibaca di atas ikon lonceng Beranda.
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
                                            // WARNA: warna angka putih di dalam badge merah notifikasi belum dibaca pada ikon lonceng Beranda.
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
                                // WARNA: warna teks judul sapaan 'Selamat datang [user]!' di atas banner carousel Beranda.
                                color: const Color(0xFFEDE2CF),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Temukan bacaan yang mungkin kamu sukai.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                // WARNA: warna subteks 'Temukan bacaan yang mungkin kamu sukai.' di bawah sapaan Beranda.
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
                                    // WARNA: bayangan di bawah kartu banner gambar carousel di header Beranda.
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

                                      // Banner 2: Buku Project Hail Mary (Arahkan ke Detail Hail Mary)
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Indikator Titik-Titik (...)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(2, (index) {
                                final isCur = _currentBannerIndex == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: isCur ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    // WARNA: warna titik indikator halaman banner carousel (krem terang jika aktif, krem redup transparan jika tidak aktif).
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
                      // WARNA: warna teks judul bagian 'Eksplor fitur Rentbook' di Beranda.
                      color: const Color(0xFF302622),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildServicesGrid(go),
                ),

                const SizedBox(height: 18),

                // Kartu Ringkasan Total Sewa Buku
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RentalHistoryPage(),
                          ),
                        );
                        _loadUser();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          // WARNA: gradasi latar belakang kartu pintasan 'Riwayat Sewa' di tengah Beranda (kiri atas marun oxblood -> kanan bawah marun gelap).
                          gradient: const LinearGradient(
                            colors: [Color(0xFF67343A), Color(0xFF4C272C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          // WARNA: garis tepi krem emas transparan di sekeliling kartu pintasan 'Riwayat Sewa' di Beranda.
                          border: Border.all(
                            color: const Color(0xFFD4BE9D).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              // WARNA: bayangan di bawah kartu pintasan 'Riwayat Sewa' di Beranda.
                              color: const Color(0xFF67343A)
                                  .withValues(alpha: 0.22),
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
                                // WARNA: latar lingkaran krem di belakang ikon struk pada kartu pintasan 'Riwayat Sewa' di Beranda.
                                color: const Color(0xFFFAF7F2),
                                shape: BoxShape.circle,
                                // WARNA: garis tepi lingkaran ikon struk pada kartu pintasan 'Riwayat Sewa' di Beranda.
                                border: Border.all(
                                  color: const Color(0xFFEDE2CF),
                                  width: 1.5,
                                ),
                              ),
                              // WARNA: warna ikon struk di dalam lingkaran kiri kartu pintasan 'Riwayat Sewa' di Beranda.
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFF67343A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Riwayat Sewa',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      // WARNA: warna teks judul 'Riwayat Sewa' pada kartu pintasan di Beranda.
                                      color: const Color(0xFFEDE2CF),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pantau buku & batas pengembalian',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      // WARNA: warna subteks 'Pantau buku & batas pengembalian' pada kartu pintasan 'Riwayat Sewa' di Beranda.
                                      color: const Color(0xFFD4BE9D),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                // WARNA: latar tombol pil 'Lihat' di sebelah kanan kartu pintasan 'Riwayat Sewa' di Beranda.
                                color: const Color(0xFFEDE2CF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lihat',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      // WARNA: warna teks 'Lihat' di dalam tombol pil sebelah kanan kartu pintasan 'Riwayat Sewa' di Beranda.
                                      color: const Color(0xFF67343A),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  // WARNA: warna ikon panah kanan (>) di dalam tombol pil 'Lihat' pada kartu pintasan 'Riwayat Sewa' di Beranda.
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF67343A),
                                    size: 15,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ============================================================
                // 5. PILIHAN UNTUKMU (BUKU-BUKU REKOMENDASI SETELAH CHATBOT)
                // ============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilihan untukmu',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                // WARNA: warna teks judul bagian 'Pilihan untukmu' di Beranda.
                                color: const Color(0xFF302622),
                              ),
                            ),
                            if (_lastRentedGenre != null &&
                                _lastRentedGenre!.isNotEmpty)
                              Text(
                                'Berdasarkan bacaan terakhir: $_lastRentedGenre',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  // WARNA: warna teks subjudul 'Berdasarkan bacaan terakhir: ...' di bawah judul 'Pilihan untukmu' Beranda.
                                  color: const Color(0xFF9A704F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => go(const BooksPage()),
                        child: Text(
                          'Lihat Semua',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            // WARNA: warna teks tombol 'Lihat Semua' di pojok kanan judul bagian 'Pilihan untukmu' Beranda.
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
              // WARNA: bayangan di bawah tiap banner gambar carousel Beranda.
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
              // WARNA: latar belakang fallback jika gambar banner carousel gagal dimuat (merah marun oxblood).
              color: const Color(0xFF67343A),
              child: const Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  // WARNA: warna ikon buku fallback di tengah banner jika gambar banner gagal dimuat.
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
        // WARNA: latar belakang kartu buku rekomendasi horizontal ('Pilihan untukmu') di Beranda (putih).
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        // WARNA: garis tepi kartu buku rekomendasi horizontal ('Pilihan untukmu') di Beranda.
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.1),
        boxShadow: [
          BoxShadow(
            // WARNA: bayangan tipis di bawah kartu buku rekomendasi horizontal ('Pilihan untukmu') di Beranda.
            color: const Color(0xFF302622).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        // WARNA: latar Material InkWell kartu buku rekomendasi dibuat transparan agar warna putih kartu tetap terlihat.
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
                            // WARNA: bayangan 3D di bawah sampul mini buku pada kartu rekomendasi horizontal Beranda.
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
                    // WARNA: warna teks judul buku pada kartu rekomendasi horizontal ('Pilihan untukmu') di Beranda.
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
                    // WARNA: warna teks nama penulis pada kartu rekomendasi horizontal ('Pilihan untukmu') di Beranda.
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
                        // WARNA: warna teks harga sewa harian di pojok kiri bawah kartu rekomendasi horizontal Beranda.
                        color: const Color(0xFF67343A),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          // WARNA: warna ikon bintang rating di pojok kanan bawah kartu rekomendasi horizontal Beranda (emas).
                          color: Color(0xFFD4AF37),
                        ),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            // WARNA: warna angka rating di sebelah ikon bintang pada kartu rekomendasi horizontal Beranda.
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
      // WARNA: latar belakang sampul buku mini fallback (saat gambar gagal dimuat) pada kartu rekomendasi horizontal Beranda.
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
            // WARNA: warna teks judul buku pada sampul mini fallback di kartu rekomendasi horizontal Beranda.
            color: const Color(0xFFEDE2CF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 1. Gambar untuk Fitur Cari & Sewa Buku:
  static const String pathGambarCariBuku = 'assets/images/cari dan sewa.png';
  static const String? pathGambarPerpustakaanGps = 'assets/images/gps.png';
  static const String? pathGambarKonversiKurs = 'assets/images/konversi.png';

  Widget _buildServicesGrid(void Function(Widget) go) {
    final services = [
      _ServiceItem(
        title: 'Cari Buku',
        imageAsset: pathGambarCariBuku,
        fallbackIcon: Icons.menu_book_rounded,
        // WARNA: warna aksen ikon & latar tipis fallback tombol layanan 'Cari Buku' (jika aset gambar gagal dimuat).
        fallbackColor: const Color(0xFF67343A),
        onTap: () => go(const BooksPage()),
      ),
      _ServiceItem(
        title: 'Perpustakaan GPS',
        imageAsset: pathGambarPerpustakaanGps,
        fallbackIcon: Icons.location_on_rounded,
        // WARNA: warna aksen ikon & latar tipis fallback tombol layanan 'Perpustakaan GPS' (jika aset gambar gagal dimuat).
        fallbackColor: const Color(0xFF43634B),
        onTap: () => go(const MapPage()),
      ),
      _ServiceItem(
        title: 'Konversi Kurs & Jam',
        imageAsset: pathGambarKonversiKurs,
        fallbackIcon: Icons.currency_exchange_rounded,
        // WARNA: warna aksen ikon & latar tipis fallback tombol layanan 'Konversi Kurs & Jam' (jika aset gambar gagal dimuat).
        fallbackColor: const Color(0xFF3B506B),
        onTap: () => go(const ConverterPage()),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 106,
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
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      // WARNA: latar kotak pembungkus ikon 3 menu fitur ('Cari Buku', 'Perpustakaan GPS', 'Konversi Kurs & Jam') di Beranda.
                      color: const Color(0xFFF1EAE1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: s.imageAsset != null
                        ? Image.asset(
                            s.imageAsset!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                _buildFallbackServiceIllustration(s),
                          )
                        : _buildFallbackServiceIllustration(s),
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
                      // WARNA: warna teks judul di bawah kotak ikon 3 menu fitur ('Eksplor fitur Rentbook') di Beranda.
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
        // WARNA: latar belakang kotak ilustrasi fallback fitur Beranda (menggunakan fallbackColor dengan transparansi 12%).
        color: s.fallbackColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            // WARNA: lingkaran putih di tengah kotak ilustrasi fallback menu fitur Beranda.
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                // WARNA: bayangan tipis di bawah lingkaran putih ilustrasi fallback menu fitur Beranda.
                color: s.fallbackColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          // WARNA: warna ikon fallback di dalam lingkaran putih menu fitur Beranda (mengikuti s.fallbackColor).
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

  _ServiceItem({
    required this.title,
    this.imageAsset,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.onTap,
  });
}

// LOGIKA FITUR PANDUAN APLIKASI (INTERACTIVE GUIDE BOOK DIALOG)
// =========================================================================
// Dialog berbentuk buku interaktif beranimasi lembaran halaman:
// - PageController: Mengatur perpindahan lembaran buku dengan animasi 'easeInOutCubic'.
// - 5 Halaman Panduan Lengkap:
//   * Hal 1: Konsep & Pengenalan RentBook.
//   * Hal 2: Cara Mencari & Menjelajahi Katalog Buku Fisik.
//   * Hal 3: Alur Peminjaman, Durasi Sewa, & Pembayaran Digital.
//   * Hal 4: Hak Istimewa & Aktivasi Member VIP.
//   * Hal 5: Panduan Fitur Tambahan (AI Vision, Chatbot, Peta LBS).
// - Memiliki tombol navigasi 'Sebelumnya', 'Halaman Berikutnya', dan 'Tutup Panduan'.
class _LibraryBookGuideDialog extends StatefulWidget {
  const _LibraryBookGuideDialog();

  @override
  State<_LibraryBookGuideDialog> createState() =>
      _LibraryBookGuideDialogState();
}

class _LibraryBookGuideDialogState extends State<_LibraryBookGuideDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

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
      // WARNA: latar belakang pembungkus Dialog Panduan RentBook dibuat transparan agar sampul buku dialog terlihat mengambang.
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 580),
          decoration: BoxDecoration(
            // WARNA: latar bingkai luar berbentuk sampul buku keras (hardcover) pada Dialog Panduan RentBook (marun tua).
            color: const Color(0xFF5A252C),
            borderRadius: BorderRadius.circular(22),
            // WARNA: garis tepi emas pada bingkai luar sampul buku Dialog Panduan RentBook.
            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
            boxShadow: [
              BoxShadow(
                // WARNA: bayangan di bawah jendela Dialog Panduan RentBook.
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
                    // WARNA: latar pita pembatas buku merah sutra yang menjuntai di atas kanan Dialog Panduan RentBook.
                    color: const Color(0xFF8B2635),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        // WARNA: bayangan kecil di bawah pita pembatas buku Dialog Panduan RentBook.
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bookmark_rounded,
                      // WARNA: warna ikon bookmark kecil di atas pita pembatas buku Dialog Panduan RentBook.
                      color: Color(0xFFF1E6D4),
                      size: 14,
                    ),
                  ),
                ),
              ),

              // Lembaran Buku Bertekstur Kertas Tua
              Container(
                decoration: BoxDecoration(
                  // WARNA: latar belakang kertas halaman isi di dalam Dialog Panduan RentBook (krem kertas).
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    // WARNA: garis tepi tipis lembaran kertas halaman di dalam Dialog Panduan RentBook.
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
                        // WARNA: latar bar header atas ('Panduan RentBook') di dalam Dialog Panduan RentBook (krem tua transparan).
                        color: const Color(0xFFEDE2CF).withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        border: const Border(
                          // WARNA: garis pembatas bawah header atas Dialog Panduan RentBook.
                          bottom: BorderSide(color: Color(0xFFEADBCE)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            // WARNA: warna ikon buku terbuka di kiri judul header 'Panduan RentBook'.
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
                                // WARNA: warna teks judul 'Panduan RentBook' di bar header dialog panduan.
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
                                // WARNA: warna ikon silang (X) tutup di pojok kanan header Dialog Panduan RentBook.
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
                        // WARNA: latar bar navigasi bawah ('Kembali' / 'Hal X dari 3' / 'Lanjut') di dalam Dialog Panduan RentBook.
                        color: const Color(0xFFEDE2CF).withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                        border: const Border(
                          // WARNA: garis pembatas atas bar navigasi bawah Dialog Panduan RentBook.
                          top: BorderSide(color: Color(0xFFEADBCE)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              // WARNA: warna teks dan ikon panah tombol 'Kembali' di bar bawah Dialog Panduan RentBook.
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
                              // WARNA: latar pil penunjuk halaman ('Hal 1 dari 3') di tengah bar bawah Dialog Panduan RentBook.
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                // WARNA: garis tepi pil penunjuk halaman ('Hal 1 dari 3') di bar bawah Dialog Panduan RentBook.
                                color: const Color(0xFFEADBCE),
                              ),
                            ),
                            child: Text(
                              'Hal ${_currentPage + 1} dari $_totalPages',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                // WARNA: warna teks 'Hal X dari 3' di dalam pil penunjuk halaman Dialog Panduan RentBook.
                                color: const Color(0xFF67343A),
                              ),
                            ),
                          ),

                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              // WARNA: latar tombol 'Lanjut' / 'Selesai' di pojok kanan bawah Dialog Panduan RentBook.
                              backgroundColor: const Color(0xFF67343A),
                              // WARNA: warna teks dan ikon tombol 'Lanjut' / 'Selesai' di pojok kanan bawah Dialog Panduan RentBook.
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
          desc: 'Pindai kode QRIS menggunakan e-Wallet (GoPay, OVO, Dana) atau Mobile Banking. Pembayaran terverifikasi otomatis secara instan.',
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
      title: 'Perpustakaan GPS & Konversi Kurs',
      icon: Icons.explore_rounded,
      sections: [
        _buildSectionItem(
          title: 'Perpustakaan GPS (LBS)',
          desc: 'Temukan perpustakaan terdekat dengan rute navigasi interaktif OpenStreetMap, penghitungan jarak langsung, serta informasi jam operasional.',
        ),
        _buildSectionItem(
          title: 'Konversi Kurs Mata Uang & Waktu',
          desc: 'Akses konversi nilai tukar mata uang global realtime melalui REST API serta konverter zona waktu dunia untuk kebutuhan referensi internasional Anda.',
        ),
        _buildSectionItem(
          title: 'Koleksi & Penyimpanan Lokal',
          desc: 'Simpan buku favorit Anda ke dalam memori lokal perangkat untuk dibaca sewaktu-waktu tanpa memerlukan koneksi internet.',
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
                  // WARNA: latar lencana label bab ('BAB I', 'BAB II', 'BAB III') di isi halaman Dialog Panduan RentBook.
                  color: const Color(0xFF67343A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  chapter,
                  style: GoogleFonts.plusJakartaSans(
                    // WARNA: warna teks 'BAB I'/'BAB II'/'BAB III' di dalam lencana bab Dialog Panduan RentBook.
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
                    // WARNA: warna teks judul bab di halaman isi Dialog Panduan RentBook.
                    color: const Color(0xFF302622),
                  ),
                ),
              ),
              // WARNA: warna ikon bab di sebelah kanan judul bab pada halaman isi Dialog Panduan RentBook.
              Icon(icon, color: const Color(0xFF67343A), size: 20),
            ],
          ),
          // WARNA: warna garis pembatas di bawah judul bab pada halaman isi Dialog Panduan RentBook.
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
                  // WARNA: warna titik bullet bulat di kiri judul poin panduan pada Dialog Panduan RentBook.
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
                    // WARNA: warna teks judul tiap poin panduan di dalam Dialog Panduan RentBook.
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
                // WARNA: warna teks paragraf penjelasan tiap poin panduan di dalam Dialog Panduan RentBook.
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
