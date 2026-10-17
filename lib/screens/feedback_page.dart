import 'package:flutter/material.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Saran & Kesan')),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              'KESAN\n\n(Isi kesanmu selama mengikuti mata kuliah Pemrograman Aplikasi Mobile)\n\n'
              'SARAN\n\n(Isi saranmu untuk mata kuliah ini)',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
      );
}
