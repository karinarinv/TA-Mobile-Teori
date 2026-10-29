import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});
  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amt = TextEditingController(text: '50000');
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _loadingRates = false;
  String _err = '';

  // Kurs acuan default (fallback bila internet lambat / offline)
  Map<String, double> _rates = {
    'USD': 0.000062,
    'EUR': 0.000058,
    'SGD': 0.000083,
    'JPY': 0.009400,
    'GBP': 0.000049,
    'AUD': 0.000095,
    'MYR': 0.000280,
  };

  final Map<String, (String, String)> _currencyInfo = {
    'USD': ('Dolar Amerika Serikat', '\$'),
    'EUR': ('Euro Eropa', '€'),
    'SGD': ('Dolar Singapura', 'S\$'),
    'JPY': ('Yen Jepang', '¥'),
    'GBP': ('Poundsterling Inggris', '£'),
    'AUD': ('Dolar Australia', 'A\$'),
    'MYR': ('Ringgit Malaysia', 'RM'),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Live clock timer 
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    _fetchRates();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _amt.dispose();
    super.dispose();
  }

  Future<void> _fetchRates() async {
    setState(() => _loadingRates = true);
    try {
      final r = await http
          .get(Uri.parse('https://api.frankfurter.app/latest?from=IDR&to=USD,EUR,JPY,GBP,AUD'))
          .timeout(const Duration(seconds: 5));

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body)['rates'] as Map<String, dynamic>;
        final newRates = Map<String, double>.from(_rates);
        data.forEach((k, v) {
          if (v is num) newRates[k] = v.toDouble();
        });

        if (mounted) {
          setState(() {
            _rates = newRates;
            _err = '';
          });
        }
      }
    } catch (_) {
      // Gunakan kurs default yang sudah ada
      if (mounted) {
        setState(() {
          _err = 'Mode offline: Menggunakan kurs referensi standar.';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingRates = false);
    }
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

  String _formatRupiah(num n) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(n).replaceAll(',', '.')}';
  }

  String _flagFor(String code) {
    final points = switch (code) {
      'ID' => [0x1F1EE, 0x1F1E9], 'JP' => [0x1F1EF, 0x1F1F5], 'GB' => [0x1F1EC, 0x1F1E7],
      'USD' => [0x1F1FA, 0x1F1F8], 'EUR' => [0x1F1EA, 0x1F1FA], 'SGD' => [0x1F1F8, 0x1F1EC],
      'JPY' => [0x1F1EF, 0x1F1F5], 'GBP' => [0x1F1EC, 0x1F1E7], 'AUD' => [0x1F1E6, 0x1F1FA], 'MYR' => [0x1F1F2, 0x1F1FE],
      _ => [0x1F30D],
    };
    return String.fromCharCodes(points);
  }

  String _formatDate(DateTime d) {
    try {
      return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(d);
    } catch (_) {
      const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amt.text.replaceAll('.', '')) ?? 0;
    final utc = _now.toUtc();
    final fTime = DateFormat('HH:mm:ss');

    final zones = <Map<String, dynamic>>[
      {
        'name': 'WIB (Waktu Indonesia Barat)',
        'city': 'Jakarta, Yogyakarta, Bandung',
        'time': utc.add(const Duration(hours: 7)),
        'badge': 'UTC+7',
        'flag': 'ID',
      },
      {
        'name': 'WITA (Waktu Indonesia Tengah)',
        'city': 'Denpasar Bali, Makassar, Balikpapan',
        'time': utc.add(const Duration(hours: 8)),
        'badge': 'UTC+8',
        'flag': 'ID',
      },
      {
        'name': 'WIT (Waktu Indonesia Timur)',
        'city': 'Jayapura, Ambon, Manokwari',
        'time': utc.add(const Duration(hours: 9)),
        'badge': 'UTC+9',
        'flag': 'ID',
      },
      {
        'name': 'Tokyo (JST)',
        'city': 'Tokyo, Osaka, Kyoto',
        'time': utc.add(const Duration(hours: 9)),
        'badge': 'UTC+9',
        'flag': 'JP',
      },
      {
        'name': 'London (GMT / BST)',
        'city': 'London, Oxford, Manchester',
        'time': utc.add(Duration(hours: _bst(utc) ? 1 : 0)),
        'badge': _bst(utc) ? 'BST (UTC+1)' : 'GMT (UTC+0)',
        'flag': 'GB',
      },
    ];

    return Scaffold(
      // WARNA: latar halaman.
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text('Konversi Kurs & Jam', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
        elevation: 0,
        // WARNA: latar AppBar.
        backgroundColor: const Color(0xFF67343A),
        // WARNA: teks/ikon tombol.
        foregroundColor: const Color(0xFFEDE2CF),
        // WARNA: teks judul/isi pada bagian ini.
        iconTheme: const IconThemeData(color: Color(0xFFEDE2CF)),
        bottom: TabBar(
          controller: _tabController,
          // WARNA: teks judul/isi pada bagian ini.
          labelColor: const Color(0xFFEDE2CF),
          // WARNA: teks 'Konversi Kurs & Jam'.
          unselectedLabelColor: const Color(0xFFD4BE9D),
          // WARNA: warna komponen.
          indicatorColor: const Color(0xFFEDE2CF),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.currency_exchange), text: 'Kurs Mata Uang'),
            Tab(icon: Icon(Icons.access_time_filled), text: 'Jam Dunia'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: KONVERSI MATA UANG
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  // WARNA: gradasi komponen ini.
                  gradient: const LinearGradient(colors: [Color(0xFF67343A), Color(0xFF92565A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  // WARNA: latar kartu/komponen.
                  boxShadow: [BoxShadow(color: const Color(0xFF67343A).withValues(alpha: .18), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Row(children: [
                  // WARNA: bayangan kartu.
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.currency_exchange_rounded, color: Color(0xFFEDE2CF), size: 27)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // WARNA: ikon currency_exchange_rounded.
                    Text('Jelajahi kurs dunia', style: GoogleFonts.poppins(color: const Color(0xFFEDE2CF), fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    // WARNA: teks judul/isi pada bagian ini.
                    Text('Cek perkiraan harga buku impor dalam rupiah.', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: .85), fontSize: 11, fontWeight: FontWeight.w500)),
                  ])),
                ]),
              ),
              const SizedBox(height: 14),
              Card(
                // WARNA: teks 'Jelajahi kurs dunia'.
                color: const Color(0xFFFAF7F2),
                // WARNA: teks 'Jelajahi kurs dunia'.
                surfaceTintColor: Colors.transparent,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  // WARNA: warna komponen.
                  side: const BorderSide(color: Color(0xFFEADBCE)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masukkan harga buku',
                        // WARNA: garis tepi kartu/komponen.
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF302622)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amt,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          hintText: '50.000',
                          // WARNA: garis tepi komponen.
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          suffixIcon: _loadingRates
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  tooltip: 'Segarkan Kurs',
                                  onPressed: _fetchRates,
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [10000, 25000, 50000, 100000].map((val) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(_formatRupiah(val)),
                                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                // WARNA: latar komponen.
                                backgroundColor: const Color(0xFFFAF7F2),
                                onPressed: () {
                                  _amt.text = val.toString();
                                  setState(() {});
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_err.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        // WARNA: warna komponen.
                        Text(_err, style: TextStyle(color: Colors.orange.shade800, fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Perkiraan harga di luar negeri',
                // WARNA: teks judul/isi pada bagian ini.
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF302622)),
              ),
              const SizedBox(height: 10),

              // Daftar Kartu Mata Uang
              ..._rates.entries.map((e) {
                final code = e.key;
                final rate = e.value;
                final converted = amount * rate;
                final info = _currencyInfo[code] ?? (code, code);

                // WARNA: teks 'Perkiraan harga di luar negeri'.
                final accent = code == 'JPY' || code == 'SGD' ? const Color(0xFFB9854D) : const Color(0xFF8B5555);
                return Card(
                  // WARNA: warna komponen.
                  color: const Color(0xFFFFFDF9),
                  // WARNA: warna komponen.
                  surfaceTintColor: Colors.transparent,
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    // WARNA: warna komponen.
                    side: BorderSide(color: accent.withValues(alpha: .35)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44, height: 44, alignment: Alignment.center,
                              // WARNA: garis tepi komponen.
                              decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
                              child: Text(_flagFor(code), style: const TextStyle(fontSize: 25)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  code,
                                  // WARNA: teks judul/isi pada bagian ini.
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF302622)),
                                ),
                                Text(
                                  info.$1,
                                  // WARNA: teks '_flagFor'.
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              code == 'JPY' ? '¥ ${converted.toStringAsFixed(0)}' : '${info.$2.split(' ').last} ${converted.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                // WARNA: teks 'info.'.
                                color: Color(0xFF67343A),
                              ),
                            ),
                            Text(
                              '1 $code = ${_formatRupiah((1 / rate).round())}',
                              // WARNA: teks 'info.'.
                              style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

          // TAB 2: JAM OPERASIONAL DUNIA
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  // WARNA: gradasi komponen ini.
                  gradient: const LinearGradient(colors: [Color(0xFF67343A), Color(0xFF92565A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  // WARNA: latar kartu/komponen.
                  boxShadow: [BoxShadow(color: const Color(0xFF67343A).withValues(alpha: .18), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Row(children: [
                  // WARNA: bayangan kartu.
                  Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), shape: BoxShape.circle), child: Text(_flagFor('ID'), style: const TextStyle(fontSize: 29))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // WARNA: teks judul/isi pada bagian ini.
                    Text('Waktu Indonesia Barat', style: GoogleFonts.poppins(color: const Color(0xFFEDE2CF), fontSize: 12, fontWeight: FontWeight.w600)),
                    // WARNA: teks '_flagFor'.
                    Text(fTime.format(utc.add(const Duration(hours: 7))), style: GoogleFonts.poppins(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800, height: 1.2)),
                    // WARNA: teks 'Waktu Indonesia Barat'.
                    Text(_formatDate(utc.add(const Duration(hours: 7))), style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: .8), fontSize: 10, fontWeight: FontWeight.w500)),
                  ])),
                  // WARNA: teks 'Waktu Indonesia Barat'.
                  const Icon(Icons.public_rounded, color: Color(0xFFEDE2CF), size: 32),
                ]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  // WARNA: latar kartu/komponen.
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(12),
                  // WARNA: latar kartu/komponen.
                  border: Border.all(color: const Color(0xFFD4BE9D)),
                ),
                child: Row(
                  children: [
                    // WARNA: garis tepi kartu/komponen.
                    Icon(Icons.info_outline, color: const Color(0xFF67343A), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Jam operasional perpustakaan acuan: 08:00 - 16:00 waktu setempat.',
                        // WARNA: ikon info_outline.
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF302622)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              ...zones.map((z) {
                final t = z['time'] as DateTime;
                final isWib = (z['name'] as String).startsWith('WIB');
                final hour = t.hour;
                final isOpen = hour >= 8 && hour < 16;

                return Card(
                  // WARNA: warna komponen.
                  color: const Color(0xFFFAF7F2),
                  // WARNA: warna komponen.
                  surfaceTintColor: Colors.transparent,
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    // WARNA: warna komponen.
                    side: const BorderSide(color: Color(0xFFEADBCE)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(_flagFor(z['flag'] as String), style: const TextStyle(fontSize: 23)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                z['name'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  // WARNA: teks '_flagFor'.
                                  color: isWib ? const Color(0xFF67343A) : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                // WARNA: latar kartu/komponen.
                                color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                // WARNA: garis tepi komponen.
                                border: Border.all(
                                  // WARNA: garis tepi kartu/komponen.
                                  color: isOpen ? Colors.green.shade200 : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                isOpen ? '● Buka' : '○ Tutup',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  // WARNA: teks 'isOpen'.
                                  color: isOpen ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          z['city'] as String,
                          // WARNA: teks 'z'.
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _formatDate(t),
                                // WARNA: teks 'z'.
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    // WARNA: latar kartu/komponen.
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    z['badge'] as String,
                                    // WARNA: latar kartu/komponen.
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  fTime.format(t),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    // WARNA: teks 'z'.
                                    color: Color(0xFF67343A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
