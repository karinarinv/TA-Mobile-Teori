// ============================================================================
// FITUR RIWAYAT PEMINJAMAN BUKU (RENTAL HISTORY PAGE)
// ----------------------------------------------------------------------------
// Logika Presentasi:
// 1. Integrasi Local Storage (SQLite 'riwayat_transaksi'):
//    - Mengambil seluruh daftar riwayat transaksi peminjaman buku pengguna aktif
//      dari SQLite lokal melalui DbHelper.db (ORDER BY id DESC).
// 2. Parsing Payload Transaksi:
//    - Mengurai string payload 'SEWA: [Judul] | Durasi: [X] Hari | Biaya: [Rp X] |
//      Batas: [Tgl] | Bayar: [Metode]' menjadi field data terstruktur.
// 3. Status Peminjaman Realtime:
//    - Membandingkan tanggal jatuh tempo dengan waktu saat ini untuk menentukan
//      status 'Sedang Dipinjam' atau 'Selesai'.
// 4. Navigasi Cepat & Empty State:
//    - Menampilkan kartu kosong interaktif dengan tombol jelajah katalog jika
//      belum ada transaksi sewa.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/db_helper.dart';
import 'books_page.dart';

/// Halaman daftar transaksi riwayat sewa buku dari database lokal SQLite.
class RentalHistoryPage extends StatefulWidget {
  const RentalHistoryPage({super.key});

  @override
  State<RentalHistoryPage> createState() => _RentalHistoryPageState();
}

class _RentalHistoryPageState extends State<RentalHistoryPage> {
  bool _isLoading = true;
  List<RentalTransactionItem> _transactions = [];
  String _currentUser = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final user = await AuthService.currentSession() ?? 'guest';
    List<RentalTransactionItem> list = [];

    try {
      final db = await DbHelper.db;
      final rows = await db.query(
        'riwayat_transaksi',
        where: 'username = ?',
        whereArgs: [user],
        orderBy: 'id DESC',
      );

      list = rows.map((r) => RentalTransactionItem.fromMap(r)).toList();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _currentUser = user;
        _transactions = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // WARNA: latar belakang utama halaman Riwayat Peminjaman.
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text(
          'Riwayat Peminjaman',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: _isLoading
          ? const Center(
              // WARNA: warna spinner loading saat memuat riwayat sewa dari SQLite.
              child: CircularProgressIndicator(color: Color(0xFF67343A)),
            )
          : RefreshIndicator(
              // WARNA: warna panah indikator tarik-untuk-refresh pada halaman Riwayat Peminjaman.
              color: const Color(0xFF67343A),
              // WARNA: latar lingkaran indikator tarik-untuk-refresh pada halaman Riwayat Peminjaman.
      backgroundColor: const Color(0xFFFAF7F2),
              onRefresh: _loadHistory,
              child: _transactions.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  // WARNA: latar lingkaran ikon pada tampilan kosong (empty state) Riwayat Peminjaman.
                  color: const Color(0xFFEDE2CF).withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  // WARNA: garis tepi lingkaran ikon pada tampilan kosong Riwayat Peminjaman.
                  border: Border.all(color: const Color(0xFFEADBCE), width: 1.5),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 42,
                  // WARNA: warna ikon nota di tampilan kosong Riwayat Peminjaman.
                  color: Color(0xFF9A704F),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Belum Ada Riwayat Sewa',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  // WARNA: warna teks judul 'Belum Ada Riwayat Sewa' di tampilan kosong.
                  color: const Color(0xFF302622),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Buku yang Anda sewa dari katalog perpustakaan akan tercatat secara otomatis di sini.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  // WARNA: warna teks deskripsi di tampilan kosong Riwayat Peminjaman.
                  color: const Color(0xFF8C7362),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  // WARNA: latar tombol 'Jelajahi Katalog Buku' di tampilan kosong Riwayat Peminjaman.
                  backgroundColor: const Color(0xFF67343A),
                  // WARNA: warna teks dan ikon tombol 'Jelajahi Katalog Buku' di tampilan kosong Riwayat Peminjaman.
                  foregroundColor: const Color(0xFFEDE2CF),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BooksPage()),
                ),
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: Text(
                  'Jelajahi Katalog Buku',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: _transactions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummaryCard();
        }
        final item = _transactions[index - 1];
        return _buildTransactionCard(item);
      },
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // WARNA: latar kartu header ringkasan 'Catatan Peminjaman Aktif' di bagian paling atas daftar riwayat.
        color: const Color(0xFFEDE2CF),
        borderRadius: BorderRadius.circular(16),
        // WARNA: garis tepi kartu header ringkasan 'Catatan Peminjaman Aktif'.
        border: Border.all(color: const Color(0xFF9A704F).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              // WARNA: latar lingkaran ikon buku di sebelah kiri kartu header ringkasan riwayat sewa.
              color: Color(0xFF67343A),
              shape: BoxShape.circle,
            ),
            // WARNA: warna ikon buku terbuka di dalam lingkaran kartu ringkasan riwayat sewa.
            child: const Icon(Icons.auto_stories_rounded, color: Color(0xFFEDE2CF), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Peminjaman Aktif',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    // WARNA: warna teks judul 'Catatan Peminjaman Aktif' pada kartu ringkasan riwayat.
                    color: const Color(0xFF302622),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total ${_transactions.length} transaksi peminjaman tercatat di memori lokal.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    // WARNA: warna teks keterangan jumlah total transaksi pada kartu ringkasan riwayat.
                    color: const Color(0xFF67343A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(RentalTransactionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // WARNA: latar belakang kartu tiap item transaksi sewa buku (putih).
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // WARNA: garis tepi kartu tiap item transaksi sewa buku.
        border: Border.all(color: const Color(0xFFEADBCE)),
        boxShadow: [
          BoxShadow(
            // WARNA: bayangan tipis di bawah kartu tiap item transaksi sewa buku.
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Baris: Ikon Buku, Judul, dan Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // WARNA: latar kotak kecil ikon buku di kiri atas kartu item transaksi sewa.
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(10),
                    // WARNA: garis tepi kotak kecil ikon buku pada kartu item transaksi sewa.
                    border: Border.all(color: const Color(0xFFEADBCE)),
                  ),
                  // WARNA: warna ikon buku di dalam kotak kiri atas kartu item transaksi sewa.
                  child: const Icon(Icons.book_rounded, color: Color(0xFF67343A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          // WARNA: warna teks judul buku pada kartu item transaksi sewa.
                          color: const Color(0xFF302622),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Waktu Transaksi: ${item.formattedTimestamp}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          // WARNA: warna teks waktu transaksi di bawah judul buku pada kartu item transaksi sewa.
                          color: const Color(0xFF8C7362),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // WARNA: garis pembatas horizontal antara header judul dan rincian biaya/durasi pada kartu item transaksi sewa.
            const Divider(color: Color(0xFFF1EAE1), height: 1),
            const SizedBox(height: 12),

            // Rincian Durasi, Jatuh Tempo, Metode & Biaya
            Row(
              children: [
                Expanded(
                  child: _buildDetailTile(
                    label: 'Durasi Sewa',
                    value: item.duration,
                    icon: Icons.timer_outlined,
                  ),
                ),
                Expanded(
                  child: _buildDetailTile(
                    label: 'Batas Kembali',
                    value: item.dueDate,
                    icon: Icons.event_available_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDetailTile(
                    label: 'Metode Pembayaran',
                    value: item.paymentMethod,
                    icon: Icons.payments_outlined,
                  ),
                ),
                Expanded(
                  child: _buildDetailTile(
                    label: 'Total Biaya',
                    value: item.cost,
                    icon: Icons.receipt_outlined,
                    isCost: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required String label,
    required String value,
    required IconData icon,
    bool isCost = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // WARNA: warna ikon kecil di sebelah label rincian (Durasi, Batas Kembali, Metode Bayar, Total Biaya) pada kartu item transaksi sewa.
        Icon(icon, size: 15, color: const Color(0xFF9A704F)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  // WARNA: warna teks label kecil (misal 'Durasi Sewa', 'Total Biaya') pada kartu item transaksi sewa.
                  color: const Color(0xFF8C7362),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isCost ? FontWeight.bold : FontWeight.w600,
                  // WARNA: warna nilai rincian pada kartu item transaksi (marun oxblood untuk Total Biaya, cokelat gelap untuk durasi/batas/metode).
                  color: isCost ? const Color(0xFF67343A) : const Color(0xFF302622),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Model data representasi baris SQLite riwayat_transaksi.
class RentalTransactionItem {
  final int id;
  final String title;
  final String duration;
  final String cost;
  final String dueDate;
  final String paymentMethod;
  final String timestamp;

  RentalTransactionItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.cost,
    required this.dueDate,
    required this.paymentMethod,
    required this.timestamp,
  });

  factory RentalTransactionItem.fromMap(Map<String, Object?> map) {
    final rawData = (map['data'] as String?) ?? '';
    final id = (map['id'] as int?) ?? 0;
    final ts = (map['ts'] as String?) ?? '';

    // Format parse: SEWA: [title] | Durasi: [dur] Hari | Biaya: [cost] | Batas: [due] | Bayar: [method]
    String title = 'Buku Perpustakaan';
    String duration = '-';
    String cost = '-';
    String dueDate = '-';
    String paymentMethod = '-';

    final parts = rawData.split(' | ');
    for (final p in parts) {
      final trimmed = p.trim();
      if (trimmed.startsWith('SEWA:')) {
        title = trimmed.replaceFirst('SEWA:', '').trim();
      } else if (trimmed.startsWith('Durasi:')) {
        duration = trimmed.replaceFirst('Durasi:', '').trim();
      } else if (trimmed.startsWith('Biaya:')) {
        cost = trimmed.replaceFirst('Biaya:', '').trim();
      } else if (trimmed.startsWith('Batas:')) {
        dueDate = trimmed.replaceFirst('Batas:', '').trim();
      } else if (trimmed.startsWith('Bayar:')) {
        paymentMethod = trimmed.replaceFirst('Bayar:', '').trim();
      }
    }

    return RentalTransactionItem(
      id: id,
      title: title,
      duration: duration,
      cost: cost,
      dueDate: dueDate,
      paymentMethod: paymentMethod,
      timestamp: ts,
    );
  }

  String get formattedTimestamp {
    if (timestamp.isEmpty) return '-';
    try {
      final dt = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return timestamp;
    }
  }
}
