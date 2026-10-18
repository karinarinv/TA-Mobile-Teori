import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show DateFormat;

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});
  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _amt = TextEditingController(text: '50000');
  Map<String, dynamic> _rates = {};
  String _err = '';

  Future<void> _convert() async {
    try {
      final r = await http.get(Uri.parse(
          'https://api.frankfurter.app/latest?from=IDR&to=USD,EUR,JPY'));
      _rates = jsonDecode(r.body)['rates'];
      _err = '';
    } catch (_) {
      _err = 'Gagal mengambil kurs (cek internet)';
    }
    if (!mounted) return;
    setState(() {});
  }

  bool _bst(DateTime u) {
    DateTime lastSun(int m) {
      var d = DateTime.utc(u.year, m + 1, 0, 1);
      while (d.weekday != DateTime.sunday) {
        d = d.subtract(const Duration(days: 1));
      }
      return d;
    }
    return u.isAfter(lastSun(3)) && u.isBefore(lastSun(10));
  }

  @override
  void initState() {
    super.initState();
    _convert();
  }

  @override
  Widget build(BuildContext context) {
    final utc = DateTime.now().toUtc();
    final f = DateFormat('HH:mm, dd MMM');
    final zones = {
      'WIB': utc.add(const Duration(hours: 7)),
      'WITA': utc.add(const Duration(hours: 8)),
      'WIT': utc.add(const Duration(hours: 9)),
      'London': utc.add(Duration(hours: _bst(utc) ? 1 : 0)),
    };
    final a = double.tryParse(_amt.text) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Konversi Harga Sewa & Jam Buka')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Harga sewa buku impor (IDR)', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: _amt,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(prefixText: 'Rp ', border: OutlineInputBorder()),
        ),
        if (_err.isNotEmpty) Text(_err, style: const TextStyle(color: Colors.red)),
        for (final e in _rates.entries)
          ListTile(title: Text(e.key), trailing: Text((a * (e.value as num)).toStringAsFixed(2))),
        const Divider(),
        const Text('Jam operasional perpustakaan', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final z in zones.entries)
          ListTile(title: Text(z.key), trailing: Text(f.format(z.value))),
      ]),
    );
  }
}
