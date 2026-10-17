import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final _c = TextEditingController();
  final _msgs = <(bool, String)>[]; // (isUser, text)
  bool _busy = false;

  Future<void> _send() async {
    final q = _c.text.trim();
    if (q.isEmpty) return;
    _c.clear();
    
    setState(() {
      _msgs.add((true, q));
      _busy = true;
    });

    // Menyusun riwayat percakapan agar Gemini memahami konteks pesan sebelumnya
    final contents = <Map<String, dynamic>>[];
    
    // System instruction awal
    contents.add({
      'role': 'user',
      'parts': [
        {
          'text': 'Aturan: Kamu adalah asisten buku RentBook. Berikan rekomendasi buku (judul, penulis, dan alasan singkat) '
              'sesuai permintaan pengguna. Jika pengguna meminta jumlah spesifik (misal 10 buku), berikan persis sesuai jumlah tersebut. '
              'Jawab dalam Bahasa Indonesia.'
        }
      ]
    });
    contents.add({
      'role': 'model',
      'parts': [{'text': 'Baik, saya asisten buku RentBook siap membantu!'}]
    });

    // Memasukkan riwayat percakapan yang ada di layar
    for (final m in _msgs) {
      contents.add({
        'role': m.$1 ? 'user' : 'model',
        'parts': [{'text': m.$2}]
      });
    }

    String ans;
    try {
      final r = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$geminiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': contents}),
      );
      final j = jsonDecode(r.body);
      ans = j['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Error: ${j['error']?['message'] ?? r.body}';
    } catch (e) {
      ans = 'Gagal terhubung: $e';
    }

    setState(() {
      _msgs.add((false, ans));
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Asisten AI Buku (Gemini)')),
        body: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.all(12), children: [
              if (_msgs.isEmpty) const Text('Contoh: "Berikan 7 rekomendasi novel yang best seller"'),
              for (final m in _msgs)
                Align(
                  alignment: m.$1 ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: m.$1 ? Colors.indigo.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(m.$2),
                  ),
                ),
            ]),
          ),
          if (_busy) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _c,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Genre / mood / jumlah buku...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(onPressed: _send, icon: const Icon(Icons.send)),
            ]),
          ),
        ]),
      );
}