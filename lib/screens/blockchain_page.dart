import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../constants/app_colors.dart';
import '../services/blockchain_service.dart';

/// Menampilkan catatan transaksi lokal, memeriksa rantai hash, dan membuka explorer.
class BlockchainPage extends StatefulWidget {
  const BlockchainPage({super.key});
  @override
  State<BlockchainPage> createState() => _BlockchainPageState();
}

class _BlockchainPageState extends State<BlockchainPage> {
  List<Map<String, Object?>> _rows = [];
  String? _msg;
  bool _ok = true;
  String _filter = '';
  final TextEditingController _searchCtrl = TextEditingController();

  Future<void> _openEtherscan([String? txHash]) async {
    // Buka transaksi Sepolia jika punya txHash; jika tidak, buka alamat wallet.
    final String url = (txHash != null && txHash.isNotEmpty)
        ? 'https://sepolia.etherscan.io/tx/$txHash'
        : 'https://sepolia.etherscan.io/address/$sepoliaWalletAddress';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: $url')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Ambil riwayat yang sudah disimpan BlockchainService di database lokal.
    final r = await BlockchainService.all();
    if (mounted) setState(() => _rows = r);
  }

  Future<void> _verify() async {
    // Periksa urutan prev_hash dan hitung ulang hash untuk semua catatan.
    final ok = await BlockchainService.verify();
    setState(() {
      _ok = ok;
      _msg = ok
          ? 'VALID: Seluruh blok terhubung utuh (SHA-256) & tidak ada data yang dimanipulasi.'
          : 'PERINGATAN: Integritas rantai rusak! Ada blok yang dimanipulasi.';
    });
  }

  void _simulate() {
    // Ubah salinan data di memori untuk demo deteksi manipulasi; database asli tidak diubah.
    if (_rows.isEmpty) return;
    final copy = _rows.reversed
        .map((e) => Map<String, Object?>.from(e))
        .toList();
    copy.first['data'] = '${copy.first['data']} (DIUBAH)';
    final ok = BlockchainService.verifyRows(copy);
    setState(() {
      _ok = ok;
      _msg = ok ? 'Valid' : 'SIMULASI: Data blok #1 diubah dalam memori, hash tidak cocok lagi dan rantai TERDETEKSI RUSAK! (Data asli di database tetap aman).';
    });
  }

  void _copyHash(String hash, int blockId) {
    // Salin hash ke clipboard lalu tampilkan notifikasi selama 2 detik.
    Clipboard.setData(ClipboardData(text: hash));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hash Blok #$blockId disalin ke papan klip.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _s(Object? v) {
    final t = '$v';
    return t.length > 20 ? '${t.substring(0, 20)}...' : t;
  }

  int _calculateTotalExpense() {
    // Jumlahkan nilai setelah teks 'Biaya:' dari catatan sewa yang tersimpan.
    int total = 0;
    for (final r in _rows) {
      final rawData = (r['data'] as String?) ?? '';
      final parts = rawData.split('|');
      for (final p in parts) {
        final trimmed = p.trim();
        if (trimmed.startsWith('Biaya:')) {
          final numStr = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
          total += int.tryParse(numStr) ?? 0;
        }
      }
    }
    return total;
  }

  String _formatRupiah(int n) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(n).replaceAll(',', '.')}';
  }

  Widget _buildTransactionDetails(String rawData) {
    if (!rawData.contains('|')) {
      final text = rawData.startsWith('PINJAM:')
          ? rawData.substring(7)
          : rawData;
      return Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          // WARNA: teks 'text'.
          color: AppColors.walnut,
        ),
      );
    }

    final parts = rawData.split('|').map((p) => p.trim()).toList();
    final titlePart = parts[0]
        .replaceFirst('SEWA:', '')
        .replaceFirst('PINJAM:', '')
        .trim();

    String? duration;
    String? price;
    String? due;
    String? method;

    for (int i = 1; i < parts.length; i++) {
      final p = parts[i];
      if (p.startsWith('Durasi:'))
        duration = p.replaceFirst('Durasi:', '').trim();
      if (p.startsWith('Biaya:')) price = p.replaceFirst('Biaya:', '').trim();
      if (p.startsWith('Batas:')) due = p.replaceFirst('Batas:', '').trim();
      if (p.startsWith('Bayar:')) method = p.replaceFirst('Bayar:', '').trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titlePart,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            // WARNA: teks 'titlePart'.
            color: AppColors.walnut,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (price != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // WARNA: latar kartu/komponen.
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  // WARNA: latar kartu/komponen.
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 14,
                      // WARNA: garis tepi kartu/komponen.
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        // WARNA: teks 'price'.
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            if (duration != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // WARNA: latar kartu/komponen.
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      // WARNA: ikon timer_outlined.
                      color: AppColors.oxblood,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        // WARNA: teks 'duration'.
                        color: AppColors.oxblood,
                      ),
                    ),
                  ],
                ),
              ),
            if (due != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // WARNA: latar kartu/komponen.
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 13,
                      // WARNA: ikon calendar_today.
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Batas: $due',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        // WARNA: teks 'Batas: $due'.
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),
            if (method != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // WARNA: latar kartu/komponen.
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  // WARNA: latar kartu/komponen.
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  method,
                  style: const TextStyle(
                    fontSize: 12,
                    // WARNA: teks 'method'.
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlockCard(Map<String, Object?> r, int i) {
    final dataStr = (r['data'] as String?) ?? '';
    final blockId = (r['id'] as num?)?.toInt() ?? (i + 1);
    final hashStr = (r['hash'] as String?) ?? '';
    final txHash = r['tx_hash'] as String?;
    final hasTx = txHash != null && txHash.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0.8,
      // WARNA: warna komponen.
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        // WARNA: warna komponen.
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Blok
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    // WARNA: latar kartu/komponen.
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Blok #$blockId',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      // WARNA: teks 'Blok #$blockId'.
                      color: AppColors.oxblood,
                    ),
                  ),
                ),
                Row(
                  children: [
                    // WARNA: teks 'Blok #$blockId'.
                    const Icon(Icons.link, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Tersambung (SHA-256)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        // WARNA: teks 'Tersambung (SHA-256)'.
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // WARNA: warna komponen.
            const Divider(height: 16, color: AppColors.border),

            // Info Buku & Sewa
            _buildTransactionDetails(dataStr),
            const SizedBox(height: 12),

            // Hash Details dengan Tombol Copy
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                // WARNA: latar kartu/komponen.
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Waktu: ${_s(r['ts'])}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          // WARNA: teks 'Waktu: ${_s(r['.
                          color: AppColors.textSecondary,
                        ),
                      ),
                      InkWell(
                        onTap: () => _copyHash(hashStr, blockId),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.copy,
                              size: 12,
                              // WARNA: ikon copy.
                              color: AppColors.oxblood,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Salin Hash',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                // WARNA: teks 'Salin Hash'.
                                color: AppColors.oxblood,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prev: ${_s(r['prev_hash'])}',
                    style: TextStyle(
                      fontSize: 11,
                      // WARNA: teks 'Prev: ${_s(r['.
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'Hash: ${_s(hashStr)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      // WARNA: teks 'Prev: ${_s(r['.
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Tombol Cek Transaksi di Etherscan
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  // WARNA: latar tombol.
                  backgroundColor: hasTx
                      ? AppColors.oxblood
                      : AppColors.tobacco,
                  // WARNA: teks/ikon tombol.
                  foregroundColor: AppColors.parchment,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: Text(
                  hasTx
                      ? 'Cek Transaksi di Etherscan'
                      : 'Cek Akun di Etherscan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _openEtherscan(txHash),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter.isEmpty
        ? _rows
        : _rows.where((r) {
            final d = ((r['data'] as String?) ?? '').toLowerCase();
            return d.contains(_filter.toLowerCase());
          }).toList();

    final totalExpense = _calculateTotalExpense();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // WARNA: latar halaman.
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Riwayat Blockchain',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        elevation: 0,
        // WARNA: latar AppBar.
        backgroundColor: AppColors.oxblood,
        // WARNA: teks/ikon tombol.
        foregroundColor: AppColors.parchment,
        // WARNA: teks 'Riwayat Blockchain'.
        iconTheme: const IconThemeData(color: AppColors.parchment),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            // WARNA: teks pada komponen ini.
            icon: const Icon(Icons.refresh, color: AppColors.parchment),
            onPressed: _load,
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              // WARNA: warna komponen.
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // WARNA: latar kartu/komponen.
                            color: AppColors.parchment,
                            borderRadius: BorderRadius.circular(12),
                            // WARNA: latar kartu/komponen.
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Blok',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  // WARNA: teks 'Total Blok'.
                                  color: AppColors.oxblood,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_rows.length} Blok',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  // WARNA: teks 'Total Blok'.
                                  color: AppColors.oxblood,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // WARNA: latar kartu/komponen.
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            // WARNA: latar kartu/komponen.
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Biaya Sewa',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  // WARNA: teks 'Total Biaya Sewa'.
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatRupiah(totalExpense),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  // WARNA: teks 'Total Biaya Sewa'.
                                  color: Colors.green.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      // WARNA: teks judul/isi pada bagian ini.
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari judul buku atau metode bayar...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        // WARNA: teks judul/isi pada bagian ini.
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        // WARNA: teks judul/isi pada bagian ini.
                        color: AppColors.oxblood,
                      ),
                      suffixIcon: _filter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _filter = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 18,
                      ),
                      // WARNA: garis tepi komponen.
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        // WARNA: warna komponen.
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        // WARNA: garis tepi kartu/komponen.
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                          // WARNA: garis tepi kartu/komponen.
                          color: AppColors.oxblood,
                          width: 1.6,
                        ),
                      ),
                      filled: true,
                      // WARNA: garis tepi kartu/komponen.
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) => setState(() => _filter = v.trim()),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            // WARNA: latar tombol.
                            backgroundColor: AppColors.oxblood,
                            // WARNA: teks/ikon tombol 'Verifikasi Rantai'.
                            foregroundColor: AppColors.parchment,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _verify,
                          icon: const Icon(Icons.verified, size: 18),
                          label: const Text('Verifikasi Rantai'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          // WARNA: teks/ikon tombol 'Simulasi Rusak'.
                          foregroundColor: AppColors.walnut,
                          // WARNA: ikon verified.
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _simulate,
                        icon: const Icon(Icons.bug_report_outlined, size: 18),
                        label: const Text('Simulasi Rusak'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_msg != null)
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // WARNA: latar kartu/komponen.
                  color: _ok ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  // WARNA: garis tepi komponen.
                  border: Border.all(
                    // WARNA: garis tepi kartu/komponen.
                    color: _ok ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _ok ? Icons.check_circle : Icons.warning_amber_rounded,
                      // WARNA: garis tepi kartu/komponen.
                      color: _ok ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _msg!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          // WARNA: teks '_msg'.
                          color: _ok
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // WARNA: latar kartu/komponen.
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      // WARNA: latar kartu/komponen.
                      color: AppColors.oxblood.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      // WARNA: latar kartu/komponen.
                      color: AppColors.oxblood,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ethereum Sepolia Explorer',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            // WARNA: teks 'Ethereum Sepolia Explorer'.
                            color: AppColors.walnut,
                          ),
                        ),
                        Text(
                          'Akun: ${_s(sepoliaWalletAddress)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            // WARNA: teks 'Ethereum Sepolia Explorer'.
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      // WARNA: teks/ikon tombol 'Etherscan'.
                      foregroundColor: AppColors.oxblood,
                      // WARNA: ikon pada komponen ini.
                      side: const BorderSide(color: AppColors.oxblood),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _openEtherscan(),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text(
                      'Etherscan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 44,
                        // WARNA: ikon inventory_2_outlined.
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _filter.isEmpty
                            ? 'Belum ada transaksi sewa.\nSewa buku terlebih dahulu di katalog buku.'
                            : 'Tidak ditemukan transaksi yang cocok dengan "$_filter"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          // WARNA: teks '_filter.isEmpty'.
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 4, bottom: 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildBlockCard(filtered[i], i),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
