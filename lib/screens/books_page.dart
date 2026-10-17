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
  final _q = TextEditingController(text: 'flutter');
  List _books = [];
  bool _loading = false;
  StreamSubscription? _sub;
  DateTime _lastShake = DateTime.now();

  @override
  void initState() {
    super.initState();
    _search();
    // Sensor 1: Accelerometer -> kocok HP untuk buku acak
    _sub = userAccelerometerEventStream().listen((e) {
      final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (g > 15 && DateTime.now().difference(_lastShake).inSeconds > 2) {
        _lastShake = DateTime.now();
        const genres = ['fiction', 'history', 'science', 'romance', 'novel', 'technology'];
        _q.text = genres[Random().nextInt(genres.length)];
        _search();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final r = await http.get(Uri.parse(
          'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeQueryComponent(_q.text)}&maxResults=20'));
      _books = (jsonDecode(r.body)['items'] ?? []) as List;
    } catch (_) {
      _books = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _rent(String title) async {
    await BlockchainService.addTransaction('PINJAM:$title');
    await NotificationService.scheduleReturn(title);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$title" dipinjam. Transaksi dicatat di blockchain.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cari Buku (kocok HP = acak)')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _q,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Judul / penulis',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _books.length,
              itemBuilder: (_, i) {
                final v = _books[i]['volumeInfo'] ?? {};
                final img = v['imageLinks']?['thumbnail'];
                final title = v['title'] ?? '-';
                return ListTile(
                  leading: img != null ? TiltCover(child: Image.network(img)) : const Icon(Icons.book),
                  title: Text(title),
                  subtitle: Text((v['authors'] ?? ['-']).join(', ')),
                  trailing: TextButton(onPressed: () => _rent(title), child: const Text('Sewa')),
                );
              },
            ),
          ),
        ]),
      );
}
