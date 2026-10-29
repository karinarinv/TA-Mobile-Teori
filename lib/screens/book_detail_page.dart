import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../widgets/tilt_cover.dart';
import '../widgets/rental_bottom_sheet.dart';
import '../services/bookmark_service.dart';
import 'saved_books_page.dart';

/// Menampilkan detail buku terpilih dan menyediakan bookmark serta alur sewa.
class BookDetailPage extends StatefulWidget {
  final Map<String, dynamic> book;

  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool _isBookmarked = false;
  String? _openLibraryDescription;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
    _loadOpenLibraryDescription();
  }

  Future<void> _loadOpenLibraryDescription() async {
    // Ambil sinopsis cadangan hanya jika katalog utama tidak menyediakannya.
    final currentDescription = widget.book['description']?.toString().trim() ?? '';
    final workKey = widget.book['openLibraryKey']?.toString();
    if (currentDescription.isNotEmpty || workKey == null || workKey.isEmpty) {
      return;
    }

    try {
      final uri = Uri.https('openlibrary.org', '$workKey.json');
      // Request sinopsis dibatasi 6 detik agar halaman detail tidak menunggu lama.
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return;

      final work = jsonDecode(response.body) as Map<String, dynamic>;
      final rawDescription = work['description'];
      final description = rawDescription is Map
          ? rawDescription['value']?.toString().trim()
          : rawDescription?.toString().trim();
      if (description != null && description.isNotEmpty && mounted) {
        setState(() => _openLibraryDescription = description);
      }
    } catch (_) {
      // Detail buku tetap dapat dibuka walau layanan sinopsis sedang gagal.
    }
  }

  Future<void> _checkBookmark() async {
    final title = widget.book['title']?.toString() ?? '';
    final b = await BookmarkService.isBookmarked(title);
    if (mounted) setState(() => _isBookmarked = b);
  }

  Future<void> _toggleBookmark() async {
    // Bookmark tersimpan lokal; Snackbar menawarkan pintasan ke daftar tersimpan.
    final title = widget.book['title']?.toString() ?? 'Buku';
    final nowSaved = await BookmarkService.toggleBookmark(widget.book);
    if (!mounted) return;
    setState(() => _isBookmarked = nowSaved);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        // WARNA: latar notifikasi.
        backgroundColor: const Color(0xFF67343A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          nowSaved
              ? '"$title" disimpan ke Buku Tersimpan.'
              : '"$title" dihapus dari Buku Tersimpan.',
          // WARNA: teks 'nowSaved'.
          style: const TextStyle(color: Color(0xFFEDE2CF), fontWeight: FontWeight.w600),
        ),
        action: nowSaved
            ? SnackBarAction(
                label: 'Lihat',
                // WARNA: teks 'nowSaved'.
                textColor: const Color(0xFFEDE2CF),
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  navigator.push(
                    MaterialPageRoute(builder: (_) => const SavedBooksPage()),
                  );
                },
              )
            : null,
      ),
    );
  }

  String _formatRupiah(int amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(amount).replaceAll(',', '.')}';
  }

  @override
  Widget build(BuildContext context) {
    // Penanganan null-safety 
    final book = widget.book;
    final title = book['title']?.toString() ?? 'Tanpa Judul';
    final authors = book['authors']?.toString() ?? 'Penulis tidak diketahui';
    final img = book['image']?.toString();
    final savedDescription = book['description']?.toString().trim() ?? '';
    final description = savedDescription.isNotEmpty
        ? savedDescription
        : _openLibraryDescription ?? 'Sinopsis belum tersedia dari penyedia data.';
    final publisher = (book['publisher']?.toString() ?? '').trim();
    final publishedDate = (book['publishedDate']?.toString() ?? '').trim();
    final pageCount = (book['pageCount'] as num?)?.toInt();
    final category = (book['category']?.toString() ?? '').trim();
    final rating = (book['rating'] as num?)?.toDouble();
    final languageCode = (book['language']?.toString() ?? '').trim();
    final language = switch (languageCode) {
      'en' => 'English',
      'id' => 'Bahasa Indonesia',
      '' => 'Tidak tersedia',
      _ => languageCode,
    };
    final pricePerDay = (book['pricePerDay'] as num?)?.toInt() ?? 5000;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Buku', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              // WARNA: teks judul/isi pada bagian ini.
              color: _isBookmarked ? Colors.amber.shade700 : null,
            ),
            tooltip: _isBookmarked ? 'Hapus dari Tersimpan' : 'Simpan Buku',
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            tooltip: 'Lihat Semua Buku Tersimpan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedBooksPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // WARNA: gradasi komponen ini.
                  colors: [const Color(0xFFFAF7F2), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 140,
                    height: 200,
                    child: TiltCover(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              // WARNA: bayangan kartu.
                              color: const Color(0x40000000),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (img != null && img.isNotEmpty)
                              ? Image.network(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    // WARNA: warna komponen.
                                    color: Colors.grey[300],
                                    // WARNA: warna komponen.
                                    child: const Icon(Icons.book, size: 60, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  // WARNA: ikon book.
                                  color: Colors.grey[300],
                                  // WARNA: ikon book.
                                  child: const Icon(Icons.book, size: 60, color: Colors.grey),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // WARNA: ikon book.
                      Icon(Icons.screen_rotation, size: 14, color: const Color(0xFF9A704F)),
                      const SizedBox(width: 4),
                      Text(
                        'Miringkan HP Anda untuk efek sensor 3D',
                        // WARNA: ikon screen_rotation.
                        style: TextStyle(fontSize: 12, color: const Color(0xFF67343A)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // WARNA: judul buku.
                      const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          authors,
                          style: TextStyle(
                            fontSize: 15,
                            // WARNA: nama penulis buku.
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (rating != null) ...[
                          // WARNA: teks dari variabel 'title'.
                          _buildBadge(Icons.star, '${rating.toStringAsFixed(1)} / 5.0', Colors.amber.shade800, Colors.amber.shade50),
                          const SizedBox(width: 8),
                        ],
                        if (category.isNotEmpty) ...[
                          // WARNA: teks dari variabel 'authors'.
                          _buildBadge(Icons.category_outlined, category, const Color(0xFF67343A), const Color(0xFFEDE2CF)),
                          const SizedBox(width: 8),
                        ],
                        if (pageCount != null) ...[
                          // WARNA: teks dari variabel 'authors'.
                          _buildBadge(Icons.menu_book_outlined, '$pageCount Hal', Colors.teal, Colors.teal.shade50),
                          const SizedBox(width: 8),
                        ],
                        if (publishedDate.isNotEmpty)
                          // WARNA: teks dari variabel 'authors'.
                          _buildBadge(Icons.calendar_today_outlined, publishedDate, Colors.deepPurple, Colors.deepPurple.shade50),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      // WARNA: latar kartu/komponen.
                      color: const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(16),
                      // WARNA: latar kartu/komponen.
                      border: Border.all(color: const Color(0xFFEADBCE)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Harga Tarif Sewa',
                                // WARNA: garis tepi kartu/komponen.
                                style: TextStyle(fontSize: 12, color: Color(0xFF67343A), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${_formatRupiah(pricePerDay)} / hari',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    // WARNA: teks 'Harga Tarif Sewa'.
                                    color: Color(0xFF302622),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            // WARNA: latar kartu/komponen.
                            color: const Color(0xFFEDE2CF),
                            borderRadius: BorderRadius.circular(20),
                            // WARNA: latar kartu/komponen.
                            border: Border.all(color: const Color(0xFFD4BE9D)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              // WARNA: garis tepi kartu/komponen.
                              Icon(Icons.menu_book_rounded, size: 15, color: Color(0xFF67343A)),
                              SizedBox(width: 4),
                              Text(
                                'Data katalog',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  // WARNA: teks 'Data katalog'.
                                  color: Color(0xFF67343A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Sinopsis Buku',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      // WARNA: teks 'Sinopsis Buku'.
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Spesifikasi & Informasi Buku',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecBox(Icons.business_rounded, 'Penerbit', publisher.isEmpty ? 'Tidak tersedia' : publisher),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSpecBox(Icons.calendar_month_rounded, 'Tanggal Rilis', publishedDate.isEmpty ? 'Tidak tersedia' : publishedDate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecBox(Icons.translate_rounded, 'Bahasa', language),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSpecBox(
                          Icons.menu_book_rounded,
                          'Jumlah Halaman',
                          pageCount == null ? 'Tidak tersedia' : '$pageCount halaman',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          // WARNA: latar kartu/komponen.
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // WARNA: bayangan kartu.
              color: const Color(0x14000000),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // WARNA: warna komponen.
                  const Text('Mulai Dari', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    _formatRupiah(pricePerDay),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      // WARNA: teks 'Mulai Dari'.
                      color: const Color(0xFF302622),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    // WARNA: latar tombol.
                    backgroundColor: const Color(0xFF67343A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text(
                    'Sewa Buku',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => RentalBottomSheet.show(context, book),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        // WARNA: latar kartu/komponen.
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WARNA: latar kartu/komponen.
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            // WARNA: ikon icon.
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        // WARNA: latar kartu/komponen.
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(12),
        // WARNA: latar kartu/komponen.
        border: Border.all(color: const Color(0xFFEADBCE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // WARNA: garis tepi kartu/komponen.
              Icon(icon, size: 16, color: const Color(0xFF67343A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  // WARNA: ikon icon.
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            // WARNA: teks 'label'.
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF302622)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
