import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/tilt_cover.dart';
import '../widgets/rental_bottom_sheet.dart';
import '../services/bookmark_service.dart';
import 'saved_books_page.dart';

class BookDetailPage extends StatefulWidget {
  final Map<String, dynamic> book;

  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final title = widget.book['title'] as String? ?? '';
    final b = await BookmarkService.isBookmarked(title);
    if (mounted) setState(() => _isBookmarked = b);
  }

  Future<void> _toggleBookmark() async {
    final title = widget.book['title'] as String? ?? 'Buku';
    final nowSaved = await BookmarkService.toggleBookmark(widget.book);
    if (!mounted) return;
    setState(() => _isBookmarked = nowSaved);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowSaved ? '"$title" disimpan ke Buku Tersimpan.' : '"$title" dihapus dari Buku Tersimpan.',
        ),
        action: nowSaved
            ? SnackBarAction(
                label: 'Lihat',
                textColor: Colors.amberAccent,
                onPressed: () {
                  Navigator.push(
                    context,
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
    final book = widget.book;
    final title = book['title'] as String? ?? 'Tanpa Judul';
    final authors = book['authors'] as String? ?? 'Penulis tidak diketahui';
    final img = book['image'] as String?;
    final description = book['description'] as String? ??
        'Buku ini menceritakan kisah yang memikat dengan wawasan mendalam. Cocok untuk dibaca dalam mengisi waktu luang dan memperluas wawasan Anda.';
    final publisher = book['publisher'] as String? ?? 'Penerbit Mitra RentBook';
    final publishedDate = book['publishedDate'] as String? ?? '-';
    final pageCount = (book['pageCount'] as num?)?.toInt() ?? 240;
    final category = book['category'] as String? ?? 'Umum / Pilihan';
    final rating = (book['rating'] as num?)?.toDouble() ?? 4.6;
    final pricePerDay = (book['pricePerDay'] as num?)?.toInt() ?? 5000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Buku'),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
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
            // Header cover dengan efek sensor gyroscope TiltCover
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade50, Colors.white],
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
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: img != null
                              ? Image.network(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.book, size: 60, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[300],
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
                      Icon(Icons.screen_rotation, size: 14, color: Colors.indigo.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Miringkan HP Anda untuk efek sensor 3D',
                        style: TextStyle(fontSize: 12, color: Colors.indigo.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Info Judul dan Pengarang
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
                      const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          authors,
                          style: TextStyle(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row Chips Spesifikasi Buku
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildBadge(Icons.star, '$rating / 5.0', Colors.amber.shade800, Colors.amber.shade50),
                        const SizedBox(width: 8),
                        _buildBadge(Icons.category_outlined, category, Colors.indigo, Colors.indigo.shade50),
                        const SizedBox(width: 8),
                        _buildBadge(Icons.menu_book_outlined, '$pageCount Hal', Colors.teal, Colors.teal.shade50),
                        const SizedBox(width: 8),
                        _buildBadge(Icons.calendar_today_outlined, publishedDate, Colors.deepPurple, Colors.deepPurple.shade50),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Kartu Harga Sewa
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Harga Tarif Sewa',
                              style: TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatRupiah(pricePerDay)} / hari',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade900,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle, size: 16, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Stok Siap Sewa',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sinopsis
                  const Text(
                    'Sinopsis Buku',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),

                  // Informasi Tambahan
                  const Text(
                    'Informasi Tambahan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Penerbit', publisher),
                  _buildDetailRow('Tanggal Rilis', publishedDate),
                  _buildDetailRow('Bahasa', 'Indonesia / Terjemahan Resmi'),
                  _buildDetailRow('Keamanan Transaksi', 'Dicatat di Blockchain Ledger (SHA-256)'),
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
                  const Text('Mulai Dari', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    _formatRupiah(pricePerDay),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigo,
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
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
