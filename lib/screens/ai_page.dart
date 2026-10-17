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
    String ans;
    try {
      final r = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$geminiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Kamu adalah asisten buku RentBook. Rekomendasikan 3 buku (judul & penulis, 1 kalimat alasan) '
                    'sesuai genre/mood berikut, jawab dalam Bahasa Indonesia: $q'}
              ]
            }
          ]
        }),
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
              if (_msgs.isEmpty) const Text('Contoh: "Aku lagi sedih, mau baca novel yang menghibur"'),
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
              Expanded(child: TextField(controller: _c, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Genre / mood...', border: OutlineInputBorder()))),
              IconButton(onPressed: _send, icon: const Icon(Icons.send)),
            ]),
          ),
        ]),
      );
}
