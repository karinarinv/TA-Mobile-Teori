import 'package:flutter/material.dart';
import '../services/bookmark_service.dart';
import '../widgets/rental_bottom_sheet.dart';
import 'book_detail_page.dart';

class SavedBooksPage extends StatefulWidget {
  const SavedBooksPage({super.key});

  @override
  State<SavedBooksPage> createState() => _SavedBooksPageState();
}

class _SavedBooksPageState extends State<SavedBooksPage> {
  List<Map<String, dynamic>> _savedBooks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _loading = true);
    final list = await BookmarkService.getBookmarks();
    if (mounted) {
      setState(() {
        _savedBooks = list;
        _loading = false;
      });
    }
  }

  Future<void> _remove(Map<String, dynamic> book) async {
    final title = (book['title'] as String?) ?? '';
    await BookmarkService.removeBookmark(title);
    await _loadBookmarks();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF302622),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '"$title" dihapus dari daftar tersimpan.',
          style: const TextStyle(color: Color(0xFFEDE2CF)),
        ),
        action: SnackBarAction(
          label: 'Urungkan',
          textColor: const Color(0xFFD4BE9D),
          onPressed: () async {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            await BookmarkService.toggleBookmark(book);
            _loadBookmarks();
          },
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buku Tersimpan (${_savedBooks.length})'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _savedBooks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE2CF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bookmark_border, size: 64, color: const Color(0xFF9A704F)),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Belum Ada Buku Tersimpan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Simpan buku favorit Anda dari halaman detail buku untuk mengaksesnya dengan cepat di sini.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF67343A),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.search),
                          label: const Text('Jelajahi Katalog Buku'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _savedBooks.length,
                  itemBuilder: (_, i) {
                    final item = _savedBooks[i];
                    final title = item['title'] as String? ?? 'Tanpa Judul';
                    final authors = item['authors'] as String? ?? 'Penulis tidak diketahui';
                    final img = item['image'] as String?;
                    final pricePerDay = (item['pricePerDay'] as num?)?.toInt() ?? 5000;
                    final rating = item['rating']?.toString() ?? '4.5';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1.5,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookDetailPage(book: item),
                            ),
                          );
                          _loadBookmarks();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                                            color: const Color(0xFFEDE2CF),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Rp ${_formatNumber(pricePerDay)}/hari',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF5A2A38),
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
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.bookmark_remove_outlined, color: Colors.redAccent),
                                    tooltip: 'Hapus dari Tersimpan',
                                    onPressed: () => _remove(item),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF67343A),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => RentalBottomSheet.show(context, item),
                                    child: const Text('Sewa', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
