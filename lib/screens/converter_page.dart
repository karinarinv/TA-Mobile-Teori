import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
    'USD': ('Dolar Amerika Serikat', '🇺🇸 \$'),
    'EUR': ('Euro Eropa', '🇪🇺 €'),
    'SGD': ('Dolar Singapura', '🇸🇬 S\$'),
    'JPY': ('Yen Jepang', '🇯🇵 ¥'),
    'GBP': ('Poundsterling Inggris', '🇬🇧 £'),
    'AUD': ('Dolar Australia', '🇦🇺 A\$'),
    'MYR': ('Ringgit Malaysia', '🇲🇾 RM'),
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
        'flag': '🇮🇩',
      },
      {
        'name': 'WITA (Waktu Indonesia Tengah)',
        'city': 'Denpasar Bali, Makassar, Balikpapan',
        'time': utc.add(const Duration(hours: 8)),
        'badge': 'UTC+8',
        'flag': '🇮🇩',
      },
      {
        'name': 'WIT (Waktu Indonesia Timur)',
        'city': 'Jayapura, Ambon, Manokwari',
        'time': utc.add(const Duration(hours: 9)),
        'badge': 'UTC+9',
        'flag': '🇮🇩',
      },
      {
        'name': 'Tokyo (JST)',
        'city': 'Tokyo, Osaka, Kyoto',
        'time': utc.add(const Duration(hours: 9)),
        'badge': 'UTC+9',
        'flag': '🇯🇵',
      },
      {
        'name': 'London (GMT / BST)',
        'city': 'London, Oxford, Manchester',
        'time': utc.add(Duration(hours: _bst(utc) ? 1 : 0)),
        'badge': _bst(utc) ? 'BST (UTC+1)' : 'GMT (UTC+0)',
        'flag': '🇬🇧',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Konversi Kurs & Jam', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFF67343A),
        foregroundColor: const Color(0xFFEDE2CF),
        iconTheme: const IconThemeData(color: Color(0xFFEDE2CF)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFEDE2CF),
          unselectedLabelColor: const Color(0xFFD4BE9D),
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
              Card(
                color: const Color(0xFFFAF7F2),
                surfaceTintColor: Colors.transparent,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFEADBCE)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Harga Sewa Buku (IDR / Rupiah)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amt,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          hintText: '50.000',
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
                        Text(_err, style: TextStyle(color: Colors.orange.shade800, fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Nilai Konversi ke Mata Uang Asing (Buku Impor)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 10),

              // Daftar Kartu Mata Uang
              ..._rates.entries.map((e) {
                final code = e.key;
                final rate = e.value;
                final converted = amount * rate;
                final info = _currencyInfo[code] ?? (code, '🌐 $code');

                return Card(
                  color: const Color(0xFFFAF7F2),
                  surfaceTintColor: Colors.transparent,
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFEADBCE)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                info.$2.split(' ').first,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  code,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  info.$1,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF67343A),
                              ),
                            ),
                            Text(
                              '1 $code = ${_formatRupiah((1 / rate).round())}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4BE9D)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFF67343A), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Jam operasional perpustakaan acuan: 08:00 - 16:00 waktu setempat.',
                        style: TextStyle(fontSize: 12, color: const Color(0xFF302622)),
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
                  color: const Color(0xFFFAF7F2),
                  surfaceTintColor: Colors.transparent,
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                            Text(z['flag'] as String, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                z['name'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
                                color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isOpen ? Colors.green.shade200 : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                isOpen ? '● Buka' : '○ Tutup',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOpen ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          z['city'] as String,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _formatDate(t),
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
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    z['badge'] as String,
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  fTime.format(t),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
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
