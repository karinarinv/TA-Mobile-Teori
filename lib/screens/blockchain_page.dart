import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await BlockchainService.all();
    if (mounted) setState(() => _rows = r);
  }

  Future<void> _verify() async {
    final ok = await BlockchainService.verify();
    setState(() {
      _ok = ok;
      _msg = ok ? 'VALID: semua blok terhubung dan tidak berubah' : 'TIDAK VALID: ada blok yang dimanipulasi!';
    });
  }

  /// Simulasi: ubah blok paling lama di salinan (memori), data asli tidak disentuh.
  void _simulate() {
    if (_rows.isEmpty) return;
    final copy = _rows.reversed.map((e) => Map<String, Object?>.from(e)).toList();
    copy.first['data'] = '${copy.first['data']} (DIUBAH)';
    final ok = BlockchainService.verifyRows(copy);
    setState(() {
      _ok = ok;
      _msg = ok
          ? 'Valid'
          : 'SIMULASI: data blok #1 diubah, hash tidak cocok lagi, rantai TERDETEKSI RUSAK. (Data asli aman)';
    });
  }

  String _s(Object? v) {
    final t = '$v';
    return t.length > 18 ? '${t.substring(0, 18)}...' : t;
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
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.indigo),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo),
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Riwayat Transaksi (Blockchain)')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Setiap transaksi sewa disimpan sebagai blok. Hash tiap blok dihitung (SHA-256) dari isi '
              'transaksi + hash blok sebelumnya, jadi mengubah satu blok akan merusak seluruh rantai.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: _verify,
              icon: const Icon(Icons.verified),
              label: const Text('Verifikasi Rantai'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _simulate, child: const Text('Simulasi manipulasi')),
          ]),
          if (_msg != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _ok ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _ok ? Colors.green.shade300 : Colors.red.shade300),
              ),
              child: Text(
                _msg!,
                style: TextStyle(color: _ok ? Colors.green.shade900 : Colors.red.shade900),
              ),
            ),
          Expanded(
            child: _rows.isEmpty
                ? const Center(child: Text('Belum ada transaksi sewa. Sewa buku terlebih dahulu di katalog.'))
                : ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (_, i) {
                      final r = _rows[i];
                      final dataStr = (r['data'] as String?) ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Blok #${r['id']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.indigo.shade800,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.link, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tersambung (SHA-256)',
                                      style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            _buildTransactionDetails(dataStr),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Waktu: ${_s(r['ts'])}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                                  Text('Prev Hash: ${_s(r['prev_hash'])}', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'monospace')),
                                  Text('Block Hash: ${_s(r['hash'])}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      );
}