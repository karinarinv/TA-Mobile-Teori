import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';
import '../services/blockchain_service.dart';
import '../services/notification_service.dart';
import '../widgets/tilt_cover.dart';

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

          return {
            'title': v['title'] as String? ?? 'Tanpa Judul',
            'authors': authorsList.join(', '),
            'image': img,
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

          return {
            'title': title,
            'authors': authorsList.join(', '),
            'image': img,
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

  Future<void> _rent(String title) async {
    await BlockchainService.addTransaction('PINJAM:$title');
    await NotificationService.scheduleReturn(title);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$title" dipinjam. Transaksi dicatat di blockchain.'),
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
          children: const [
            Text('Katalog Buku RentBook', style: TextStyle(fontSize: 18)),
            Text(
              'Goyang HP untuk rekomendasi acak',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
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

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: SizedBox(
                      width: 50,
                      height: 70,
                      child: img != null
                          ? TiltCover(
                              child: Image.network(
                                img,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.book, color: Colors.grey),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.book, color: Colors.grey),
                            ),
                    ),
                    title: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      authors,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _rent(title),
                      child: const Text('Sewa'),
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