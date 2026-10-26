import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';
import '../widgets/rental_bottom_sheet.dart';
import 'book_detail_page.dart';
import 'saved_books_page.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search();
    });

    _sub = userAccelerometerEventStream().listen((e) {
      final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (g > 16 && DateTime.now().difference(_lastShake).inSeconds > 3 && !_loading) {
        _lastShake = DateTime.now();
        const genres = [
          'fiction',
          'history',
          'science',
          'romance',
          'novel',
          'technology',
          'art',
          'fantasy'
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

      final r = await http.get(uri).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final items = (data['items'] as List?) ?? [];
        if (items.isEmpty) {
          await _searchOpenLibrary(q);
          return;
        }

        final parsedBooks = items.map<Map<String, dynamic>?>((item) {
          final v = (item['volumeInfo'] as Map<String, dynamic>?) ?? {};
          final imageLinks = v['imageLinks'] as Map<String, dynamic>?;
          String? img = imageLinks?['thumbnail'] as String? ?? imageLinks?['smallThumbnail'] as String?;
          if (img != null) img = img.replaceFirst('http://', 'https://');

          final authorsList = (v['authors'] as List?)?.cast<String>() ?? ['Penulis tidak diketahui'];
          final authors = authorsList.join(', ');
          final title = v['title'] as String?;
          if (title == null || title.trim().isEmpty) return null;
          final categories = (v['categories'] as List?)?.cast<String>() ?? const <String>[];
          
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
        }).whereType<Map<String, dynamic>>().toList();

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

        final parsedBooks = docs.map((doc) {
          final title = doc['title'] as String?;
          if (title == null || title.trim().isEmpty) return null;
          final authorsList = (doc['author_name'] as List?)?.cast<String>() ?? ['Penulis tidak diketahui'];
          final authors = authorsList.join(', ');
          final coverId = doc['cover_i'];
          String? img;
          if (coverId != null) {
            img = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
          }

          final firstYear = doc['first_publish_year']?.toString();
          final publisher = (doc['publisher'] as List?)?.firstOrNull?.toString();
          final pageCount = (doc['number_of_pages_median'] as num?)?.toInt();
          final subjects = (doc['subject'] as List?)?.cast<String>() ?? const <String>[];

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
        }).whereType<Map<String, dynamic>>().toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Katalog Buku RentBook', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              'Goyang HP untuk rekomendasi acak',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.normal),
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
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFFFAF7F2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: Color(0xFF67343A), width: 1.6),
                ),
                prefixIcon: const Icon(Icons.menu_book, color: Color(0xFF67343A)),
                suffixIcon: IconButton(
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFFEDE2CF) : const Color(0xFF302622),
                    ),
                    backgroundColor: const Color(0xFFFAF7F2),
                    selectedColor: const Color(0xFF67343A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF67343A) : const Color(0xFFEADBCE),
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
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _books.length,
              itemBuilder: (_, i) {
                final item = _books[i] as Map<String, dynamic>;
                final title = item['title'] as String;
                final authors = item['authors'] as String;
                final img = item['image'] as String?;
                final pricePerDay = (item['pricePerDay'] as num?)?.toInt() ?? 5000;
                final rating = item['rating'] as num?;

                return Card(
                  color: const Color(0xFFFAF7F2),
                  surfaceTintColor: Colors.transparent,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFEADBCE)),
                  ),
                  elevation: 1.5,
                  child: InkWell(
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 6,
                                  offset: const Offset(1, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    width: 54,
                                    height: 80,
                                    child: img != null
                                        ? Image.network(
                                            img,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.menu_book_rounded, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.menu_book_rounded, color: Colors.grey),
                                          ),
                                  ),
                                  // Efek realistis tulang punggung buku (spine shadow) di sisi kiri
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: 6,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.35),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authors,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDE2CF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Rp ${_formatNumber(pricePerDay)}/hari',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF67343A),
                                        ),
                                      ),
                                    ),
                                    if (rating != null) ...[
                                      Icon(Icons.star, size: 13, color: Colors.amber.shade800),
                                      const SizedBox(width: 2),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        'Rating belum tersedia',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF67343A),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => RentalBottomSheet.show(context, item),
                            child: const Text('Sewa', style: TextStyle(fontSize: 13)),
                          ),
                        ],
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
