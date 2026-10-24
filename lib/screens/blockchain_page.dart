import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../services/blockchain_service.dart';

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
    final r = await BlockchainService.all();
    if (mounted) setState(() => _rows = r);
  }

  Future<void> _verify() async {
    final ok = await BlockchainService.verify();
    setState(() {
      _ok = ok;
      _msg = ok
          ? 'VALID: Seluruh blok terhubung utuh (SHA-256) & tidak ada data yang dimanipulasi.'
          : 'PERINGATAN: Integritas rantai rusak! Ada blok yang dimanipulasi.';
    });
  }

  void _simulate() {
    if (_rows.isEmpty) return;
    final copy = _rows.reversed.map((e) => Map<String, Object?>.from(e)).toList();
    copy.first['data'] = '${copy.first['data']} (DIUBAH)';
    final ok = BlockchainService.verifyRows(copy);
    setState(() {
      _ok = ok;
      _msg = ok
          ? 'Valid'
          : 'SIMULASI: Data blok #1 diubah dalam memori, hash tidak cocok lagi dan rantai TERDETEKSI RUSAK! (Data asli di database tetap aman).';
    });
  }

  void _copyHash(String hash, int blockId) {
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
      final text = rawData.startsWith('PINJAM:') ? rawData.substring(7) : rawData;
      return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
    }

    final parts = rawData.split('|').map((p) => p.trim()).toList();
    final titlePart = parts[0].replaceFirst('SEWA:', '').replaceFirst('PINJAM:', '').trim();

    String? duration;
    String? price;
    String? due;
    String? method;

    for (int i = 1; i < parts.length; i++) {
      final p = parts[i];
      if (p.startsWith('Durasi:')) duration = p.replaceFirst('Durasi:', '').trim();
      if (p.startsWith('Biaya:')) price = p.replaceFirst('Biaya:', '').trim();
      if (p.startsWith('Batas:')) due = p.replaceFirst('Batas:', '').trim();
      if (p.startsWith('Bayar:')) method = p.replaceFirst('Bayar:', '').trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titlePart,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payments_outlined, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      price,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            if (duration != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE2CF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF67343A)),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF67343A)),
                    ),
                  ],
                ),
              ),
            if (due != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 13, color: Colors.deepOrange),
                    const SizedBox(width: 4),
                    Text(
                      'Batas: $due',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.deepOrange),
                    ),
                  ],
                ),
              ),
            if (method != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  method,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
              ),
          ],
        ),
      ],
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Riwayat Blockchain', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFF67343A),
        foregroundColor: const Color(0xFFEDE2CF),
        iconTheme: const IconThemeData(color: Color(0xFFEDE2CF)),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh, color: Color(0xFFEDE2CF)),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFAF7F2),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE2CF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Blok', style: TextStyle(fontSize: 11, color: const Color(0xFF67343A))),
                            const SizedBox(height: 2),
                            Text(
                              '${_rows.length} Blok',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF67343A)),
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
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Biaya Sewa', style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
                            const SizedBox(height: 2),
                            Text(
                              _formatRupiah(totalExpense),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade900),
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
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari judul buku atau metode bayar...',
                    hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF67343A)),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
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
                    filled: true,
                    fillColor: const Color(0xFFFAF7F2),
                  ),
                  onChanged: (v) => setState(() => _filter = v.trim()),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF67343A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _verify,
                        icon: const Icon(Icons.verified, size: 18),
                        label: const Text('Verifikasi Rantai'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

          if (_msg != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _ok ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _ok ? Colors.green.shade300 : Colors.red.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_ok ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: _ok ? Colors.green : Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _msg!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _ok ? Colors.green.shade900 : Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Banner Info Etherscan Sepolia
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEADBCE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF67343A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.language_rounded, color: Color(0xFF67343A), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ethereum Sepolia Explorer',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF302622)),
                      ),
                      Text(
                        'Akun: ${_s(sepoliaWalletAddress)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B564A)),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF67343A),
                    side: const BorderSide(color: Color(0xFF67343A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openEtherscan(),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Etherscan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _filter.isEmpty
                                ? 'Belum ada transaksi sewa.\nSewa buku terlebih dahulu di katalog buku.'
                                : 'Tidak ditemukan transaksi yang cocok dengan "$_filter"',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final r = filtered[i];
                      final dataStr = (r['data'] as String?) ?? '';
                      final blockId = (r['id'] as num?)?.toInt() ?? (i + 1);
                      final hashStr = (r['hash'] as String?) ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE2CF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Blok #$blockId',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: const Color(0xFF5A2A38),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.link, size: 14, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tersambung (SHA-256)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 16),

                              // Info Buku & Sewa
                              _buildTransactionDetails(dataStr),
                              const SizedBox(height: 12),

                              // Hash Details dengan Tombol Copy
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Waktu: ${_s(r['ts'])}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                                        InkWell(
                                          onTap: () => _copyHash(hashStr, blockId),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.copy, size: 12, color: Color(0xFF67343A)),
                                              SizedBox(width: 3),
                                              Text('Salin Hash',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF67343A),
                                                      fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Prev: ${_s(r['prev_hash'])}',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey[600], fontFamily: 'monospace'),
                                    ),
                                    Text(
                                      'Hash: ${_s(hashStr)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Tombol Cek Transaksi di Etherscan
                              Builder(
                                builder: (context) {
                                  final txHash = r['tx_hash'] as String?;
                                  final hasTx = txHash != null && txHash.isNotEmpty;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: hasTx ? const Color(0xFF67343A) : const Color(0xFF9A704F),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.open_in_new, size: 14),
                                      label: Text(
                                        hasTx
                                            ? 'Cek Transaksi di Etherscan ↗'
                                            : 'Cek Akun di Etherscan ↗',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _openEtherscan(txHash),
                                    ),
                                  );
                                },
                              ),
                            ],
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