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
  final TextEditingController _c = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<(bool, String)> _msgs = []; // (isUser, text)
  bool _busy = false;

  final List<String> _quickPrompts = [
    'Rekomendasi 5 novel best seller Indonesia',
    'Buku self-improvement paling laris',
    'Novel fiksi ilmiah dan fantasi seru',
    'Buku literasi keuangan untuk pemula',
    'Rekomendasi novel misteri & detektif',
  ];

  @override
  void dispose() {
    _c.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? customText]) async {
    final q = (customText ?? _c.text).trim();
    if (q.isEmpty || _busy) return;
    _c.clear();

    setState(() {
      _msgs.add((true, q));
      _busy = true;
    });
    _scrollToBottom();

    final contents = <Map<String, dynamic>>[];

    // System instruction awal
    contents.add({
      'role': 'user',
      'parts': [
        {
          'text': 'Kamu adalah asisten kurator buku pintar untuk aplikasi sewa buku "RentBook". '
              'Tugasmu adalah memberikan rekomendasi buku berkualitas lengkap dengan judul, penulis, dan alasan singkat kenapa buku tersebut menarik dibaca. '
              'Gunakan gaya bahasa yang ramah, santun, dan mudah dipahami dalam Bahasa Indonesia.'
        }
      ]
    });
    contents.add({
      'role': 'model',
      'parts': [{'text': 'Halo! Saya asisten kurator buku RentBook, siap membantu mencarikan rekomendasi buku terbaik untuk Anda.'}]
    });

    for (final m in _msgs) {
      contents.add({
        'role': m.$1 ? 'user' : 'model',
        'parts': [{'text': m.$2}]
      });
    }

    String ans = '';
    final modelsToTry = [
      geminiModel,
      'gemini-flash-lite-latest',
      'gemini-3.1-flash-lite',
      'gemini-3.5-flash',
    ];

    for (final model in modelsToTry) {
      try {
        final r = await http
            .post(
              Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiKey'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'contents': contents}),
            )
            .timeout(const Duration(seconds: 25));

        if (!mounted) return;

        if (r.statusCode == 200) {
          final j = jsonDecode(r.body);
          final text = j['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            ans = text.trim();
            break;
          }
        }
      } catch (_) {
        continue;
      }
    }

    if (ans.isEmpty) {
      if (!mounted) return;
      ans = 'Maaf, asisten AI sedang mengalami antrean tinggi. Silakan coba kirim kembali dalam beberapa detik.';
    }

    if (!mounted) return;
    setState(() {
      _msgs.add((false, ans));
      _busy = false;
    });
    _scrollToBottom();
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Percakapan'),
        content: const Text('Apakah Anda yakin ingin mengosongkan riwayat tanya-jawab AI ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _msgs.clear());
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Asisten Buku AI', style: TextStyle(fontSize: 18)),
            Text('Didukung Google Gemini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          if (_msgs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Bersihkan Percakapan',
              onPressed: _clearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          // Daftar Pesan Chat
          Expanded(
            child: _msgs.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.smart_toy, size: 54, color: Colors.indigo),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tanya Apa Saja tentang Buku!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bingung mau baca buku apa? Pilih saran cepat di bawah atau ketik langsung permintaan Anda:',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _quickPrompts
                                .map((p) => ActionChip(
                                      label: Text(p, style: const TextStyle(fontSize: 12)),
                                      avatar: const Icon(Icons.auto_awesome, size: 14, color: Colors.indigo),
                                      backgroundColor: Colors.indigo.shade50.withValues(alpha: 0.5),
                                      onPressed: () => _send(p),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) {
                      final isUser = _msgs[i].$1;
                      final text = _msgs[i].$2;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.indigo.shade100,
                                child: const Icon(Icons.smart_toy, size: 18, color: Colors.indigo),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isUser ? Colors.indigo : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  border: isUser ? null : Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: SelectableText(
                                  text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: isUser ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.indigo.shade700,
                                child: const Icon(Icons.person, size: 18, color: Colors.white),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Indikator Loading Mengetik
          if (_busy)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Asisten AI sedang menyusun rekomendasi...',
                    style: TextStyle(fontSize: 12, color: Colors.indigo.shade700, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Tanyakan genre, mood, atau rekomendasi buku...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.indigo),
                    icon: const Icon(Icons.send, size: 20),
                    onPressed: _busy ? null : () => _send(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}