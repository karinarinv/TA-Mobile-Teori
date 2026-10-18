import 'package:flutter/material.dart';
import 'books_page.dart';
import 'converter_page.dart';
import 'map_page.dart';
import 'ai_page.dart';
import 'quiz_page.dart';
import 'blockchain_page.dart';
import 'saved_books_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});
  @override
  Widget build(BuildContext context) {
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    final items = <(IconData, String, VoidCallback)>[
      (Icons.book, 'Cari & Sewa Buku', () => go(const BooksPage())),
      (Icons.collections_bookmark, 'Buku Tersimpan', () => go(const SavedBooksPage())),
      (Icons.currency_exchange, 'Konversi Kurs & Waktu', () => go(const ConverterPage())),
      (Icons.map, 'Perpustakaan Terdekat', () => go(const MapPage())),
      (Icons.smart_toy, 'Asisten AI Buku', () => go(const AiPage())),
      (Icons.quiz, 'Kuis Buku', () => go(const QuizPage())),
      (Icons.verified, 'Riwayat Blockchain', () => go(const BlockchainPage())),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('RentBook')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final i in items)
            Card(
              child: InkWell(
                onTap: i.$3,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(i.$1, size: 48, color: Colors.indigo),
                  const SizedBox(height: 8),
                  Text(i.$2, textAlign: TextAlign.center),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}