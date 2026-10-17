import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

// [pertanyaan, jawaban benar, pilihan salah 1, 2, 3]
const _pool = <List<String>>[
  ['Siapa penulis novel "Laskar Pelangi"?', 'Andrea Hirata', 'Tere Liye', 'Pramoedya A. Toer', 'Habiburrahman El Shirazy'],
  ['"Bumi Manusia" ditulis oleh?', 'Pramoedya A. Toer', 'Andrea Hirata', 'Dee Lestari', 'Ahmad Tohari'],
  ['Penulis serial "Harry Potter"?', 'J.K. Rowling', 'J.R.R. Tolkien', 'Rick Riordan', 'C.S. Lewis'],
  ['"Negeri 5 Menara" ditulis oleh?', 'Ahmad Fuadi', 'Tere Liye', 'Raditya Dika', 'Pidi Baiq'],
  ['"The Hobbit" karya?', 'J.R.R. Tolkien', 'George R.R. Martin', 'J.K. Rowling', 'Roald Dahl'],
  ['"Dilan 1990" ditulis oleh?', 'Pidi Baiq', 'Raditya Dika', 'Boy Candra', 'Fiersa Besari'],
  ['"Ayat-Ayat Cinta" ditulis oleh?', 'Habiburrahman El Shirazy', 'Ahmad Fuadi', 'Andrea Hirata', 'Tere Liye'],
  ['"Perahu Kertas" ditulis oleh?', 'Dee Lestari', 'Ayu Utami', 'Nh. Dini', 'Leila S. Chudori'],
  ['"Cantik Itu Luka" ditulis oleh?', 'Eka Kurniawan', 'Pramoedya A. Toer', 'Ahmad Tohari', 'Okky Madasari'],
  ['"Laut Bercerita" ditulis oleh?', 'Leila S. Chudori', 'Dee Lestari', 'Ayu Utami', 'Intan Paramaditha'],
  ['"Sang Pemimpi" ditulis oleh?', 'Andrea Hirata', 'Ahmad Fuadi', 'Tere Liye', 'Pidi Baiq'],
  ['"The Da Vinci Code" karya?', 'Dan Brown', 'Stephen King', 'John Grisham', 'Agatha Christie'],
  ['"1984" ditulis oleh?', 'George Orwell', 'Aldous Huxley', 'Ray Bradbury', 'Franz Kafka'],
  ['"To Kill a Mockingbird" karya?', 'Harper Lee', 'Jane Austen', 'Emily Bronte', 'Mark Twain'],
  ['"Pride and Prejudice" karya?', 'Jane Austen', 'Charlotte Bronte', 'Mary Shelley', 'Virginia Woolf'],
  ['"The Little Prince" ditulis oleh?', 'Antoine de Saint-Exupery', 'Victor Hugo', 'Albert Camus', 'Jules Verne'],
  ['Tokoh detektif Sherlock Holmes diciptakan oleh?', 'Arthur Conan Doyle', 'Agatha Christie', 'Edgar Allan Poe', 'Dan Brown'],
  ['"The Alchemist" ditulis oleh?', 'Paulo Coelho', 'Gabriel Garcia Marquez', 'Haruki Murakami', 'Khaled Hosseini'],
  ['"The Hunger Games" ditulis oleh?', 'Suzanne Collins', 'Veronica Roth', 'Stephenie Meyer', 'J.K. Rowling'],
  ['"Siti Nurbaya" ditulis oleh?', 'Marah Rusli', 'Abdoel Moeis', 'Hamka', 'Sutan Takdir Alisjahbana'],
  ['"Salah Asuhan" ditulis oleh?', 'Abdoel Moeis', 'Marah Rusli', 'Armijn Pane', 'Chairil Anwar'],
  ['"Atomic Habits" ditulis oleh?', 'James Clear', 'Robert Kiyosaki', 'Stephen Covey', 'Dale Carnegie'],
  ['"Rich Dad Poor Dad" ditulis oleh?', 'Robert Kiyosaki', 'James Clear', 'Napoleon Hill', 'Tony Robbins'],
];

class _QuizPageState extends State<QuizPage> {
  static const _perGame = 5;
  late List<List<String>> _game; // soal terpilih (acak tiap permainan)
  late List<List<String>> _opts; // pilihan jawaban teracak per soal
  int _i = 0, _score = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final p = [..._pool]..shuffle();
    _game = p.take(_perGame).toList();
    _opts = _game.map((q) => ([...q.sublist(1)]..shuffle())).toList();
    _i = 0;
    _score = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_i >= _game.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kuis Buku')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Skor: $_score / ${_game.length}', style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => setState(_start), child: const Text('Main lagi (soal baru)')),
          ]),
        ),
      );
    }
    final cur = _game[_i];
    return Scaffold(
      appBar: AppBar(title: Text('Kuis Buku ${_i + 1}/${_game.length}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(cur[0], style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          for (final o in _opts[_i])
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