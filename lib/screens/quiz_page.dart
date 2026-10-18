import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

// [pertanyaan, jawaban benar, pilihan salah 1, 2, 3]
const _pool = <List<String>>[
  ['Siapa penulis novel "Laskar Pelangi"?', 'Andrea Hirata', 'Tere Liye', 'Pramoedya A. Toer', 'Habiburrahman El Shirazy'],
  ['"Bumi Manusia" ditulis oleh sastrawan terkemuka?', 'Pramoedya A. Toer', 'Andrea Hirata', 'Dee Lestari', 'Ahmad Tohari'],
  ['Siapakah pengarang serial fantasi "Harry Potter"?', 'J.K. Rowling', 'J.R.R. Tolkien', 'Rick Riordan', 'C.S. Lewis'],
  ['Novel inspiratif "Negeri 5 Menara" ditulis oleh?', 'Ahmad Fuadi', 'Tere Liye', 'Raditya Dika', 'Pidi Baiq'],
  ['Kisah petualangan epik "The Hobbit" adalah mahakarya?', 'J.R.R. Tolkien', 'George R.R. Martin', 'J.K. Rowling', 'Roald Dahl'],
  ['Novel romantis "Dilan: Dia adalah Dilanku Tahun 1990" ditulis oleh?', 'Pidi Baiq', 'Raditya Dika', 'Boy Candra', 'Fiersa Besari'],
  ['Novel religi fenomenal "Ayat-Ayat Cinta" ditulis oleh?', 'Habiburrahman El Shirazy', 'Ahmad Fuadi', 'Andrea Hirata', 'Tere Liye'],
  ['Kisah cinta "Perahu Kertas" dan karakter Kugy & Keenan diciptakan oleh?', 'Dee Lestari', 'Ayu Utami', 'Nh. Dini', 'Leila S. Chudori'],
  ['Karya sastra internasional "Cantik Itu Luka" ditulis oleh pengarang Indonesia bernama?', 'Eka Kurniawan', 'Pramoedya A. Toer', 'Ahmad Tohari', 'Okky Madasari'],
  ['Novel bertema sejarah "Laut Bercerita" karya sastrawan?', 'Leila S. Chudori', 'Dee Lestari', 'Ayu Utami', 'Intan Paramaditha'],
  ['Kelanjutan kisah Laskar Pelangi dalam "Sang Pemimpi" ditulis oleh?', 'Andrea Hirata', 'Ahmad Fuadi', 'Tere Liye', 'Pidi Baiq'],
  ['Novel misteri simbolik "The Da Vinci Code" ditulis oleh?', 'Dan Brown', 'Stephen King', 'John Grisham', 'Agatha Christie'],
  ['Karya distopia termasyhur "1984" ditulis oleh?', 'George Orwell', 'Aldous Huxley', 'Ray Bradbury', 'Franz Kafka'],
  ['Novel klasik peraih Pulitzer "To Kill a Mockingbird" ditulis oleh?', 'Harper Lee', 'Jane Austen', 'Emily Bronte', 'Mark Twain'],
  ['Kisah klasik romansa Inggris "Pride and Prejudice" karya?', 'Jane Austen', 'Charlotte Bronte', 'Mary Shelley', 'Virginia Woolf'],
  ['Kisah filosofis pengelana cilik "The Little Prince" ditulis oleh?', 'Antoine de Saint-Exupery', 'Victor Hugo', 'Albert Camus', 'Jules Verne'],
  ['Karakter detektif legendaris Sherlock Holmes diciptakan oleh penulis?', 'Arthur Conan Doyle', 'Agatha Christie', 'Edgar Allan Poe', 'Dan Brown'],
  ['Buku pengembangan diri legendaris "The Alchemist" karya penulis asal Brasil bernama?', 'Paulo Coelho', 'Gabriel Garcia Marquez', 'Haruki Murakami', 'Khaled Hosseini'],
  ['Trilogi distopia bertahan hidup "The Hunger Games" ditulis oleh?', 'Suzanne Collins', 'Veronica Roth', 'Stephenie Meyer', 'J.K. Rowling'],
  ['Karya sastra era Balai Pustaka "Siti Nurbaya" ditulis oleh?', 'Marah Rusli', 'Abdoel Moeis', 'Hamka', 'Sutan Takdir Alisjahbana'],
  ['Buku self-improvement nomor 1 "Atomic Habits" ditulis oleh pakar kebiasaan bernama?', 'James Clear', 'Robert Kiyosaki', 'Stephen Covey', 'Dale Carnegie'],
  ['Buku literasi finansial terpopuler "Rich Dad Poor Dad" ditulis oleh?', 'Robert Kiyosaki', 'James Clear', 'Napoleon Hill', 'Tony Robbins'],
];

class _QuizPageState extends State<QuizPage> {
  static const _perGame = 5;
  late List<List<String>> _game;
  late List<List<String>> _opts;
  int _i = 0;
  int _score = 0;

  String? _selectedOption;
  bool _answered = false;

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
    _selectedOption = null;
    _answered = false;
  }

  void _chooseOption(String option, String correctAnswer) {
    if (_answered) return;

    setState(() {
      _selectedOption = option;
      _answered = true;
      if (option == correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _i++;
      _selectedOption = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Layar Hasil Kuis
    if (_i >= _game.length) {
      final percentage = ((_score / _game.length) * 100).toInt();
      String badgeText;
      String descText;
      IconData badgeIcon;
      Color badgeColor;

      if (_score == _game.length) {
        badgeText = 'Kutu Buku Sejati! 🏆';
        descText = 'Sempurna! Pengetahuan literasi dan bukumu sangat mengagumkan.';
        badgeIcon = Icons.military_tech;
        badgeColor = Colors.amber.shade800;
      } else if (_score >= 3) {
        badgeText = 'Penikmat Buku Hebat! 📚';
        descText = 'Keren sekali! Wawasan literasimu sangat baik dan luas.';
        badgeIcon = Icons.workspace_premium;
        badgeColor = Colors.indigo;
      } else {
        badgeText = 'Tetap Semangat Membaca! 💪';
        descText = 'Jangan patah semangat, mari perkaya wawasan dengan membaca buku di RentBook!';
        badgeIcon = Icons.menu_book;
        badgeColor = Colors.teal;
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Hasil Kuis Buku')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(badgeIcon, size: 70, color: badgeColor),
                ),
                const SizedBox(height: 16),
                Text(
                  badgeText,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: badgeColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  descText,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Card Skor
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Total Skor Anda', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(
                        '$_score / ${_game.length}',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      Text('Nilai: $percentage%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const Divider(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.confirmation_num_outlined, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Voucher Reward: DISKON10 (Diskon 10%)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                    onPressed: () => setState(_start),
                    icon: const Icon(Icons.replay),
                    label: const Text('Main Lagi (Soal Baru Acak)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali ke Beranda'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Layar Sedang Kuis
    final cur = _game[_i];
    final question = cur[0];
    final correctAnswer = cur[1];
    final options = _opts[_i];
    final progress = (_i + 1) / _game.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Kuis Literasi (${_i + 1}/${_game.length})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Soal ${_i + 1} dari ${_game.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('Skor: $_score', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Pilihan Jawaban
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (_, idx) {
                  final opt = options[idx];
                  final isSelected = _selectedOption == opt;
                  final isCorrect = opt == correctAnswer;

                  Color bgColor = Colors.white;
                  Color borderColor = Colors.grey.shade300;
                  Color textColor = Colors.black87;
                  IconData? trailIcon;

                  if (_answered) {
                    if (isCorrect) {
                      bgColor = Colors.green.shade50;
                      borderColor = Colors.green;
                      textColor = Colors.green.shade900;
                      trailIcon = Icons.check_circle;
                    } else if (isSelected) {
                      bgColor = Colors.red.shade50;
                      borderColor = Colors.red;
                      textColor = Colors.red.shade900;
                      trailIcon = Icons.cancel;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _answered ? null : () => _chooseOption(opt, correctAnswer),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: isSelected || (_answered && isCorrect) ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected || (_answered && isCorrect) ? borderColor : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                String.fromCharCode(65 + idx), // A, B, C, D
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected || (_answered && isCorrect) ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected || (_answered && isCorrect) ? FontWeight.bold : FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (trailIcon != null)
                              Icon(trailIcon, color: borderColor, size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bagian Feedback & Tombol Lanjut
            if (_answered) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedOption == correctAnswer ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedOption == correctAnswer ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedOption == correctAnswer ? Icons.check_circle : Icons.info,
                      color: _selectedOption == correctAnswer ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedOption == correctAnswer
                            ? 'Hebat! Jawaban Anda Benar (+1 Poin)'
                            : 'Jawaban kurang tepat. Yang benar: "$correctAnswer"',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedOption == correctAnswer ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _nextQuestion,
                  child: Text(
                    _i < _game.length - 1 ? 'Lanjut ke Soal Berikutnya' : 'Lihat Hasil Kuis',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}