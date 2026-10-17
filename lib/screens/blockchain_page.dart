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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Riwayat Transaksi (Blockchain)')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Setiap transaksi sewa disimpan sebagai blok. Hash tiap blok dihitung (SHA-256) dari isi '
              'transaksi + hash blok sebelumnya, jadi mengubah satu blok akan merusak seluruh rantai.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton.icon(onPressed: _verify, icon: const Icon(Icons.verified), label: const Text('Verifikasi')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _simulate, child: const Text('Simulasi manipulasi')),
          ]),
          if (_msg != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              color: _ok ? Colors.green.shade100 : Colors.red.shade100,
              child: Text(_msg!),
            ),
          Expanded(
            child: _rows.isEmpty
                ? const Center(child: Text('Belum ada transaksi. Sewa buku dulu.'))
                : ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (_, i) {
                      final r = _rows[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Blok #${r['id']}  -  ${r['data']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Waktu: ${_s(r['ts'])}'),
                            Text('Prev hash: ${_s(r['prev_hash'])}'),
                            Text('Hash: ${_s(r['hash'])}'),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      );
}