import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';

import 'book_detail_page.dart';
import 'saved_books_page.dart';

/// Katalog buku: pencarian API, filter genre, dan navigasi ke detail buku.
class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final _q = TextEditingController();
  List _books = [];
  bool _loading = false;
  String _status = '';
  StreamSubscription? _sub;
  DateTime _lastShake = DateTime.now();
  String _selectedGenre = 'Semua';
  final List<String> _genres = const [
    'Semua',
    'Bestseller',
    'Fiksi',
    'Sejarah',
    'Sains',
    'Bisnis',
    'Seni',
    'Filosofi',
    'Teknologi',
  ];

  @override
  void initState() {
    super.initState();
    // Tampilkan daftar awal setelah frame pertama siap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search();
    });

    // Goyangan kuat (lebih dari 16) mengganti kata pencarian, dengan jeda 3 detik.
    _sub = userAccelerometerEventStream().listen((e) {
      final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (g > 16 &&
          DateTime.now().difference(_lastShake).inSeconds > 3 &&
          !_loading) {
        _lastShake = DateTime.now();
        const genres = [
          'fiction',
          'history',
          'science',
          'romance',
          'novel',
          'technology',
          'art',
          'fantasy',
        ];
        _q.text = genres[Random().nextInt(genres.length)];
        _search();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _q.dispose();
    super.dispose();
  }

  int _calcPrice(String title) {
    // Harga demo dibuat konsisten dari judul, bukan berasal dari API katalog.
    final hash = title.hashCode.abs();
    return ((hash % 10) + 3) * 1000;
  }

  String _formatNumber(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  // Membersihkan tag HTML bawaan Google Books
  String _cleanHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  Future<void> _search() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final queryText = _q.text.trim();
    final q = queryText.isEmpty ? 'bestseller' : queryText;

    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
        'q': q,
        'maxResults': '30',
        'printType': 'books',
      });

      // Sumber utama katalog; bila kosong/gagal, _searchOpenLibrary menjadi cadangan.
      final r = await http.get(uri).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final items = (data['items'] as List?) ?? [];
        if (items.isEmpty) {
          await _searchOpenLibrary(q);
          return;
        }

        final parsedBooks = items
            .map<Map<String, dynamic>?>((item) {
              final v = (item['volumeInfo'] as Map<String, dynamic>?) ?? {};
              final imageLinks = v['imageLinks'] as Map<String, dynamic>?;
              String? img =
                  imageLinks?['thumbnail'] as String? ??
                  imageLinks?['smallThumbnail'] as String?;
              if (img != null) img = img.replaceFirst('http://', 'https://');

              final authorsList =
                  (v['authors'] as List?)?.cast<String>() ??
                  ['Penulis tidak diketahui'];
              final authors = authorsList.join(', ');
              final title = v['title'] as String?;
              if (title == null || title.trim().isEmpty) return null;
              final categories =
                  (v['categories'] as List?)?.cast<String>() ??
                  const <String>[];

              // Ambil deskripsi asli & bersihkan dari tag HTML
              String rawDesc = (v['description'] as String?) ?? '';
              String cleanDesc = _cleanHtml(rawDesc);

              // Ambil penerbit & tanggal rilis asli
              final publisher = v['publisher'] as String?;
              final publishedDate = v['publishedDate'] as String?;
              final pageCount = (v['pageCount'] as num?)?.toInt();
              final rating = (v['averageRating'] as num?)?.toDouble();

              return {
                'title': title,
                'authors': authors,
                'image': img,
                'description': cleanDesc,
                'publisher': publisher,
                'publishedDate': publishedDate,
                'pageCount': pageCount,
                'category': categories.firstOrNull,
                'language': v['language'] as String?,
                'rating': rating,
                'pricePerDay': _calcPrice(title),
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList();

        setState(() {
          _books = parsedBooks;
          if (_books.isEmpty) {
            _status = 'Tidak ada hasil untuk "$q"';
          }
        });
      } else {
        await _searchOpenLibrary(q);
      }
    } catch (_) {
      await _searchOpenLibrary(q);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _searchOpenLibrary(String q) async {
    // Sumber katalog cadangan dengan batas waktu request 10 detik.
    try {
      final uri = Uri.https('openlibrary.org', '/search.json', {
        'q': q,
        'limit': '30',
        'fields': 'key,title,author_name,cover_i,first_publish_year,publisher,number_of_pages_median,subject',
      });

      final r = await http.get(uri).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final docs = (data['docs'] as List?) ?? [];

        final parsedBooks = docs
            .map((doc) {
              final title = doc['title'] as String?;
              if (title == null || title.trim().isEmpty) return null;
              final authorsList =
                  (doc['author_name'] as List?)?.cast<String>() ??
                  ['Penulis tidak diketahui'];
              final authors = authorsList.join(', ');
              final coverId = doc['cover_i'];
              String? img;
              if (coverId != null) {
                img = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
              }

              final firstYear = doc['first_publish_year']?.toString();
              final publisher = (doc['publisher'] as List?)?.firstOrNull
                  ?.toString();
              final pageCount = (doc['number_of_pages_median'] as num?)
                  ?.toInt();
              final subjects =
                  (doc['subject'] as List?)?.cast<String>() ?? const <String>[];

              return {
                'title': title,
                'authors': authors,
                'image': img,
                'description': '',
                'openLibraryKey': doc['key'] as String?,
                'publisher': publisher,
                'publishedDate': firstYear,
                'pageCount': pageCount,
                'category': subjects.firstOrNull,
                'rating': null,
                'pricePerDay': _calcPrice(title),
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList();

        setState(() {
          _books = parsedBooks;
          if (_books.isEmpty) {
            _status = 'Tidak ada hasil untuk "$q"';
          } else {
            _status = '';
          }
        });
      } else {
        setState(() {
          _books = [];
          _status = 'Gagal memuat data dari server. Coba lagi nanti.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _books = [];
        _status = 'Gagal terhubung ke internet.';
      });
    }
  }

  Widget _buildFallbackCover(String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          // WARNA: gradasi komponen ini.
          colors: [Color(0xFF7A4B3A), Color(0xFF67343A), Color(0xFF302622)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              // WARNA: ikon menu_book_rounded.
              color: Color(0xFFEDE2CF),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                // WARNA: judul buku.
                color: const Color(0xFFEDE2CF),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Katalog Buku RentBook',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              'Goyang HP untuk rekomendasi acak',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            tooltip: 'Buku Tersimpan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedBooksPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: TextField(
              controller: _q,
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Cari judul, penulis, atau genre...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  // WARNA: teks judul/isi pada bagian ini.
                  color: Colors.grey.shade500,
                ),
                filled: true,
                // WARNA: teks judul/isi pada bagian ini.
                fillColor: const Color(0xFFFAF7F2),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                // WARNA: garis tepi komponen.
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  // WARNA: warna komponen.
                  borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  // WARNA: garis tepi kartu/komponen.
                  borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    // WARNA: garis tepi kartu/komponen.
                    color: Color(0xFF67343A),
                    width: 1.6,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.menu_book,
                  // WARNA: garis tepi kartu/komponen.
                  color: Color(0xFF67343A),
                ),
                suffixIcon: IconButton(
                  // WARNA: ikon menu_book.
                  icon: const Icon(Icons.search, color: Color(0xFF67343A)),
                  onPressed: _search,
                ),
              ),
            ),
          ),

          // Baris Filter Kategori Cepat (Elegan & Halus)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _genres.length,
              itemBuilder: (context, idx) {
                final genre = _genres[idx];
                final isSelected = _selectedGenre == genre;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(genre),
                    selected: isSelected,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      // WARNA: teks 'genre'.
                      color: isSelected
                          ? const Color(0xFFEDE2CF)
                          : const Color(0xFF302622),
                    ),
                    // WARNA: latar komponen.
                    backgroundColor: const Color(0xFFFAF7F2),
                    // WARNA: warna komponen.
                    selectedColor: const Color(0xFF67343A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        // WARNA: garis tepi kartu/komponen.
                        color: isSelected
                            ? const Color(0xFF67343A)
                            : const Color(0xFFEADBCE),
                      ),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedGenre = genre;
                        _q.text = genre == 'Semua' ? '' : genre;
                      });
                      _search();
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          if (_loading) const LinearProgressIndicator(),
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _status,
                // WARNA: teks '_status'.
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.62,
              ),
              itemCount: _books.length,
              itemBuilder: (context, i) {
                final item = _books[i] as Map<String, dynamic>;
                final title = item['title'] as String;
                final authors = item['authors'] as String;
                final img = item['image'] as String?;
                final pricePerDay =
                    (item['pricePerDay'] as num?)?.toInt() ?? 5000;
                final rating = item['rating'] as num?;
                final displayRating = rating != null
                    ? rating.toDouble()
                    : (4.6 + (title.hashCode.abs() % 5) * 0.1);

                return Container(
                  decoration: BoxDecoration(
                    // WARNA: latar kartu/komponen.
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    // WARNA: garis tepi komponen.
                    border: Border.all(
                      // WARNA: garis tepi kartu/komponen.
                      color: const Color(0xFFEADBCE),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        // WARNA: bayangan kartu.
                        color: const Color(0xFF302622).withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    // WARNA: bayangan kartu.
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailPage(book: item),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Cover Buku Elegan dengan Spine Shadow
                            Expanded(
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        // WARNA: bayangan kartu.
                                        color: Colors.black.withValues(
                                          alpha: 0.20,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(2, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: AspectRatio(
                                      aspectRatio: 0.70,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (img != null)
                                            Image.network(
                                              img,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _buildFallbackCover(title),
                                            )
                                          else
                                            _buildFallbackCover(title),
                                          // Efek realistis tulang punggung buku (spine shadow) di sisi kiri
                                          Positioned(
                                            left: 0,
                                            top: 0,
                                            bottom: 0,
                                            width: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  // WARNA: gradasi komponen ini.
                                                  colors: [
                                                    Colors.black.withValues(
                                                      alpha: 0.38,
                                                    ),
                                                    // WARNA: latar kartu.
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 2. Judul Buku (Serif Klasik)
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                // WARNA: judul buku.
                                color: const Color(0xFF302622),
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),

                            // 3. Nama Penulis
                            Text(
                              authors,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                // WARNA: nama penulis buku.
                                color: const Color(0xFF9A704F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 4. Baris Harga Sewa & Rating Bintang
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Harga Sewa (Badge Krim Klasik)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    // WARNA: latar kartu/komponen.
                                    color: const Color(0xFFEDE2CF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Rp ${_formatNumber(pricePerDay)}/hr',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      // WARNA: teks 'Rp ${_formatNumber(pricePerDay)}/hr'.
                                      color: const Color(0xFF67343A),
                                    ),
                                  ),
                                ),

                                // Rating Bintang
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      // WARNA: ikon star_rounded.
                                      color: Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 2.5),
                                    Text(
                                      displayRating.toStringAsFixed(1),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        // WARNA: rating buku.
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
