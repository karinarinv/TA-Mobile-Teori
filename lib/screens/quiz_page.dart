import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // [pertanyaan, jawaban benar, opsi...]
  final _q = const [
    ['Siapa penulis novel "Laskar Pelangi"?', 'Andrea Hirata', 'Tere Liye', 'Pramoedya A. Toer', 'Habiburrahman'],
    ['"Bumi Manusia" ditulis oleh?', 'Pramoedya A. Toer', 'Andrea Hirata', 'Dee Lestari', 'Ahmad Tohari'],
    ['Penulis serial "Harry Potter"?', 'J.K. Rowling', 'Tolkien', 'Rick Riordan', 'C.S. Lewis'],
    ['"Negeri 5 Menara" ditulis oleh?', 'Ahmad Fuadi', 'Tere Liye', 'Raditya Dika', 'Pidi Baiq'],
    ['"The Hobbit" karya?', 'J.R.R. Tolkien', 'George Martin', 'J.K. Rowling', 'Roald Dahl'],
  ];
  int _i = 0, _score = 0;

  @override
  Widget build(BuildContext context) {
    if (_i >= _q.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kuis Buku')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Skor: $_score / ${_q.length}', style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => setState(() => _i = _score = 0), child: const Text('Main lagi')),
          ]),
        ),
      );
    }
    final cur = _q[_i];
    final opts = cur.sublist(1)..shuffle();
    return Scaffold(
      appBar: AppBar(title: Text('Kuis Buku ${_i + 1}/${_q.length}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(cur[0], style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          for (final o in opts)
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    if (o == cur[1]) _score++;
                    _i++;
                  }),
                  child: Text(o),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
