import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
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
  // Controller diawali kosong agar hintText "Cari judul..." muncul rapi
  final _q = TextEditingController();
  List _books = [];
  bool _loading = false;
  String _status = '';
  StreamSubscription? _sub;
  DateTime _lastShake = DateTime.now();

  @override
  void initState() {
    super.initState();
    
    // Memuat daftar buku default secara otomatis saat pertama kali halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search();
    });

    // Sensor Shake HP untuk rekomendasi acak
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

  Future<void> _search() async {
    FocusManager.instance.primaryFocus?.unfocus();

    // Jika input kosong, gunakan pencarian default 'bestseller' agar buku langsung muncul
    final queryText = _q.text.trim();
    final q = queryText.isEmpty ? 'bestseller' : queryText;

    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      // 1. Coba panggil Google Books API
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

        final parsedBooks = items.map((item) {
          final v = (item['volumeInfo'] as Map<String, dynamic>?) ?? {};
          final imageLinks = v['imageLinks'] as Map<String, dynamic>?;
          String? img = imageLinks?['thumbnail'] as String? ?? imageLinks?['smallThumbnail'] as String?;
          if (img != null) img = img.replaceFirst('http://', 'https://');

          final authorsList = (v['authors'] as List?)?.cast<String>() ?? ['Penulis tidak diketahui'];
          final title = v['title'] as String? ?? 'Tanpa Judul';
          final categories = (v['categories'] as List?)?.cast<String>() ?? ['Pilihan Populer'];
          final desc = v['description'] as String? ?? 'Buku ini menceritakan kisah yang memikat dengan wawasan mendalam. Cocok untuk dibaca dalam mengisi waktu luang dan memperluas wawasan Anda.';
          final publisher = v['publisher'] as String? ?? 'Penerbit Mitra RentBook';
          final publishedDate = v['publishedDate'] as String? ?? '2023';
          final pageCount = (v['pageCount'] as num?)?.toInt() ?? 260;
          final rating = ((v['averageRating'] as num?)?.toDouble() ?? (4.0 + (title.hashCode.abs() % 10) / 10)).clamp(3.8, 5.0);

          return {
            'title': title,
            'authors': authorsList.join(', '),
            'image': img,
            'description': desc,
            'publisher': publisher,
            'publishedDate': publishedDate,
            'pageCount': pageCount,
            'category': categories.first,
            'rating': double.parse(rating.toStringAsFixed(1)),
            'pricePerDay': _calcPrice(title),
          };
        }).toList();

        // Mengurutkan daftar buku secara alfabetis (A sampai Z) berdasarkan judul
        parsedBooks.sort((a, b) => (a['title'] as String).toLowerCase().compareTo((b['title'] as String).toLowerCase()));

        setState(() {
          _books = parsedBooks;
          if (_books.isEmpty) {
            _status = 'Tidak ada hasil untuk "$q"';
          }
        });
      } else {
        // Jika Google API mengalami limit/error (misal HTTP 429), gunakan OpenLibrary
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

  // Backup API: Open Library
  Future<void> _searchOpenLibrary(String q) async {
    try {
      final uri = Uri.https('openlibrary.org', '/search.json', {
        'q': q,
        'limit': '30',
      });

      final r = await http.get(uri).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final docs = (data['docs'] as List?) ?? [];

        final parsedBooks = docs.map((doc) {
          final title = doc['title'] as String? ?? 'Tanpa Judul';
          final authorsList = (doc['author_name'] as List?)?.cast<String>() ?? ['Penulis tidak diketahui'];
          final coverId = doc['cover_i'];
          String? img;
          if (coverId != null) {
            img = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
          }
          final firstYear = doc['first_publish_year']?.toString() ?? '2022';
          final publisher = (doc['publisher'] as List?)?.firstOrNull?.toString() ?? 'Penerbit Mitra';
          final pageCount = (doc['number_of_pages_median'] as num?)?.toInt() ?? 280;
          final subjects = (doc['subject'] as List?)?.cast<String>() ?? ['Koleksi Unggulan'];
          final rating = (4.0 + (title.hashCode.abs() % 9) / 10).clamp(4.0, 5.0);

          return {
            'title': title,
            'authors': authorsList.join(', '),
            'image': img,
            'description': 'Buku "$title" karya ${authorsList.join(", ")} adalah salah satu koleksi unggulan di RentBook.',
            'publisher': publisher,
            'publishedDate': firstYear,
            'pageCount': pageCount,
            'category': subjects.first,
            'rating': double.parse(rating.toStringAsFixed(1)),
            'pricePerDay': _calcPrice(title),
          };
        }).toList();

        // Mengurutkan daftar buku secara alfabetis (A sampai Z) berdasarkan judul
        parsedBooks.sort((a, b) => (a['title'] as String).toLowerCase().compareTo((b['title'] as String).toLowerCase()));

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
          children: const [
            Text('Katalog Buku RentBook', style: TextStyle(fontSize: 18)),
            Text(
              'Goyang HP untuk rekomendasi acak',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
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
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _q,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Cari judul, penulis, atau genre...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.menu_book),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
            ),
          ),
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
                final rating = item['rating']?.toString() ?? '4.5';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 52,
                              height: 76,
                              child: img != null
                                  ? Image.network(
                                      img,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.book, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.book, color: Colors.grey),
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
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Rp ${_formatNumber(pricePerDay)}/hari',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.star, size: 13, color: Colors.amber.shade800),
                                    const SizedBox(width: 2),
                                    Text(
                                      rating,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.indigo,
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