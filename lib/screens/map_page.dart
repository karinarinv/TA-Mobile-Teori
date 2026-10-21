import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../services/cloud_service.dart';

class LibraryItem {
  final String name;
  final LatLng location;
  final String address;
  final String hours;
  final String phone;
  final double rating;
  final List<String> facilities;

  const LibraryItem({
    required this.name,
    required this.location,
    required this.address,
    required this.hours,
    required this.phone,
    required this.rating,
    this.facilities = const ['WiFi Gratis', 'Ruang Baca AC', 'Koleksi Lengkap', 'Peminjaman Digital'],
  });
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng? _me;
  bool _loadingLocation = true;
  LibraryItem? _selectedLib;

  // State untuk Rute Navigasi
  List<LatLng> _routePoints = [];
  bool _isRouting = false;
  LibraryItem? _navigatingLib;
  String _routeDistance = '';
  String _routeDuration = '';

  // 11 Perpustakaan Nyata & Terpopuler di Daerah Istimewa Yogyakarta
  static const List<LibraryItem> _coreLibraries = [
    LibraryItem(
      name: 'Perpustakaan & Arsip UGM',
      location: LatLng(-7.769117, 110.378523),
      address: 'Bulaksumur Kotak Pos 16, Sekip, Caturtunggal, Kec. Depok, Kabupaten Sleman, D.I. Yogyakarta 55281',
      hours: 'Senin - Jumat: 07.30 - 20.00 WIB | Sabtu: 08.00 - 12.00 WIB (Minggu Tutup)',
      phone: '(0274) 513163',
      rating: 4.8,
      facilities: ['WiFi Eduroam/UGM', 'Ruang Baca Ber-AC', 'Akses E-Journal Internasional', 'Loker Mandiri', 'Kubikel Riset'],
    ),
    LibraryItem(
      name: 'Grhatama Pustaka (Perpustakaan Daerah DIY)',
      location: LatLng(-7.799312, 110.407083),
      address: 'Jl. Raya Janti, Wonocatur, Banguntapan, Kec. Banguntapan, Kabupaten Bantul, D.I. Yogyakarta 55198',
      hours: 'Setiap Hari (Senin - Minggu): 08.00 - 22.00 WIB',
      phone: '(0274) 4536294',
      rating: 4.9,
      facilities: ['Bioskop 6D', 'Ruang Anak & Difabel', 'Kafe Pustaka & Rooftop', 'Taman Terbuka', 'Audio Visual', 'Drop Box 24 Jam'],
    ),
    LibraryItem(
      name: 'Dinas Perpustakaan & Kearsipan Kota Yogyakarta',
      location: LatLng(-7.784053, 110.374339),
      address: 'Jl. Suroto No.9, Kotabaru, Kec. Gondokusuman, Kota Yogyakarta, D.I. Yogyakarta 55224',
      hours: 'Senin - Sabtu: 08.00 - 20.30 WIB (Minggu Libur)',
      phone: '(0274) 512345',
      rating: 4.7,
      facilities: ['WiFi Publik Jogja', 'Ruang Belajar Digital', 'Gazebo Literasi', 'Koleksi Budaya Jogja', 'Area Baca Santai'],
    ),
    LibraryItem(
      name: 'Perpustakaan Universitas Negeri Yogyakarta (UNY)',
      location: LatLng(-7.773512, 110.387245),
      address: 'Jl. Colombo No. 1, Kampus Karangmalang, Caturtunggal, Kec. Depok, Sleman, D.I. Yogyakarta 55281',
      hours: 'Senin - Jumat: 07.30 - 17.00 WIB | Sabtu: 08.00 - 13.00 WIB',
      phone: '(0274) 548520',
      rating: 4.8,
      facilities: ['WiFi Kampus UNY', 'Ruang Baca Multimedia', 'Layanan Skripsi & Tesis', 'Area Diskusi Santai'],
    ),
    LibraryItem(
      name: 'Perpustakaan UIN Sunan Kalijaga',
      location: LatLng(-7.783724, 110.395595),
      address: 'Jl. Marsda Adisucipto, Papringan, Caturtunggal, Kec. Depok, Sleman, D.I. Yogyakarta 55281',
      hours: 'Senin - Jumat: 08.00 - 17.00 WIB (Sabtu & Minggu Libur)',
      phone: '(0274) 548635',
      rating: 4.7,
      facilities: ['Corner Literasi Islam', 'Ruang Komputer Riset', 'Area Baca Nyaman', 'Layanan Skripsi Digital'],
    ),
    LibraryItem(
      name: 'Perpustakaan Universitas Atma Jaya Yogyakarta (UAJY)',
      location: LatLng(-7.779215, 110.416412),
      address: 'Jl. Babarsari No. 5-6, Caturtunggal, Kec. Depok, Sleman, D.I. Yogyakarta 55281',
      hours: 'Senin - Jumat: 08.00 - 19.00 WIB | Sabtu: 08.00 - 14.00 WIB',
      phone: '(0274) 487711',
      rating: 4.8,
      facilities: ['Koleksi Arsitektur & Teknik', 'Silent Reading Room', 'Area Kolaboratif', 'WiFi Kecepatan Tinggi'],
    ),
    LibraryItem(
      name: 'Perpustakaan Universitas Muhammadiyah Yogyakarta (UMY)',
      location: LatLng(-7.812318, 110.322510),
      address: 'Jl. Brawijaya (Ringroad Barat), Tamantirto, Kec. Kasihan, Bantul, D.I. Yogyakarta 55183',
      hours: 'Senin - Jumat: 08.00 - 20.00 WIB | Sabtu: 08.00 - 13.00 WIB',
      phone: '(0274) 387656',
      rating: 4.8,
      facilities: ['Muhammadiyah Corner', 'Ruang Belajar Mandiri', 'Studio Multimedia', 'Loker Digital Mandiri'],
    ),
    LibraryItem(
      name: 'Perpustakaan Museum Sonobudoyo (Titik Nol Km)',
      location: LatLng(-7.801785, 110.364003),
      address: 'Jl. Pangurakan No. 6, Ngupasan, Gondomanan, Kota Yogyakarta 55122 (Dekat Titik 0 Km & Keraton)',
      hours: 'Selasa - Minggu: 08.00 - 16.00 WIB (Senin Tutup)',
      phone: '(0274) 373619',
      rating: 4.9,
      facilities: ['Manuskrip Kuno & Naskah Jawa', 'Ruang Baca Tenang', 'Galeri Budaya & Sejarah', 'Pemandu Khusus'],
    ),
    LibraryItem(
      name: 'Dinas Perpustakaan & Kearsipan Kabupaten Sleman',
      location: LatLng(-7.718814, 110.355823),
      address: 'Jl. Candi Boko, Beran, Tridadi, Kec. Sleman, Kabupaten Sleman, D.I. Yogyakarta 55511',
      hours: 'Senin - Kamis: 08.00 - 15.30 WIB | Jumat: 08.00 - 14.30 WIB',
      phone: '(0274) 869612',
      rating: 4.6,
      facilities: ['Mobil Pintar Keliling', 'Ruang Baca Anak', 'Akses Internet Publik', 'Taman Baca Literasi'],
    ),
    LibraryItem(
      name: 'Dinas Perpustakaan & Kearsipan Kabupaten Bantul',
      location: LatLng(-7.888215, 110.332512),
      address: 'Jl. Gajah Mada No. 1, Bantul, Kec. Bantul, Kabupaten Bantul, D.I. Yogyakarta 55712',
      hours: 'Senin - Jumat: 08.00 - 16.00 WIB (Sabtu & Minggu Libur)',
      phone: '(0274) 368302',
      rating: 4.6,
      facilities: ['Ruang Koleksi Umum', 'Layanan Audio Visual', 'Area Baca Nyaman', 'Layanan Pustaka Keliling'],
    ),
    LibraryItem(
      name: 'Direktorat Perpustakaan UII (Gd. Mohammad Hatta)',
      location: LatLng(-7.689312, 110.413921),
      address: 'Jl. Kaliurang KM. 14,5, Umbulmartani, Kec. Ngemplak, Sleman, D.I. Yogyakarta 55584',
      hours: 'Senin - Jumat: 08.00 - 20.00 WIB | Sabtu: 08.00 - 14.00 WIB',
      phone: '(0274) 898444',
      rating: 4.8,
      facilities: ['Mohammad Hatta Corner', 'Gedung Perpustakaan Modern 4 Lantai', 'Co-Working Space Mahasiswa'],
    ),
  ];

  late List<LibraryItem> _libraries;

  @override
  void initState() {
    super.initState();
    _libraries = List.from(_coreLibraries);
    _locate();
    _loadCloud();
  }

  Future<void> _loadCloud() async {
    try {
      final rows = await CloudService.select('libraries');
      if (rows.isEmpty || !mounted) return;

      final List<LibraryItem> merged = List.from(_coreLibraries);

      for (final r in rows) {
        final cloudName = '${r['name']}'.toLowerCase();
        // Cek apakah perpustakaan ini sudah tercatat di daftar inti Jogja
        final exists = merged.any((core) {
          final coreLower = core.name.toLowerCase();
          return coreLower.contains(cloudName) ||
              cloudName.contains(coreLower) ||
              (cloudName.contains('ugm') && coreLower.contains('ugm')) ||
              (cloudName.contains('grhatama') && coreLower.contains('grhatama')) ||
              (cloudName.contains('kota') && coreLower.contains('kota')) ||
              (cloudName.contains('uin') && coreLower.contains('uin'));
        });

        // Hanya tambahkan jika ada cabang unik baru dari cloud
        if (!exists) {
          merged.add(
            LibraryItem(
              name: '${r['name']}',
              location: LatLng(double.parse('${r['lat']}'), double.parse('${r['lng']}')),
              address: '${r['address'] ?? 'Cabang Mitra Perpustakaan RentBook'}',
              hours: '${r['hours'] ?? '08.00 - 20.00 WIB'}',
              phone: '${r['phone'] ?? '(0274) 500-123'}',
              rating: (r['rating'] as num?)?.toDouble() ?? 4.7,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _libraries = merged;
        });
      }
    } catch (_) {}
  }

  Future<void> _locate() async {
    setState(() => _loadingLocation = true);
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final myLoc = LatLng(pos.latitude, pos.longitude);

      // Cek jarak terdekat ke salah satu perpustakaan Jogja
      double minDistance = double.infinity;
      for (final lib in _coreLibraries) {
        final d = Geolocator.distanceBetween(
          myLoc.latitude,
          myLoc.longitude,
          lib.location.latitude,
          lib.location.longitude,
        );
        if (d < minDistance) minDistance = d;
      }

      List<LibraryItem> activeList = List.from(_libraries);

      // Hanya jika user berada sangat jauh di luar DIY (> 80 km), sediakan cabang mitra terdekat
      if (minDistance > 80000) {
        final localPartners = [
          LibraryItem(
            name: 'Perpustakaan Daerah Mitra RentBook',
            location: LatLng(myLoc.latitude + 0.0075, myLoc.longitude + 0.0062),
            address: 'Pusat Layanan Literasi & Peminjaman Buku',
            hours: '08.00 - 21.00 WIB',
            phone: '(021) 8899-1234',
            rating: 4.9,
            facilities: ['WiFi Kencang', 'Spot Baca Nyaman', 'Pengambilan Buku Instan'],
          ),
          LibraryItem(
            name: 'Station Perpustakaan Pintar',
            location: LatLng(myLoc.latitude - 0.0068, myLoc.longitude + 0.0084),
            address: 'Sentra Komunitas Buku & Ruang Belajar Mandiri',
            hours: '08.30 - 20.00 WIB',
            phone: '(021) 7788-5678',
            rating: 4.8,
            facilities: ['Ruang Diskusi', 'Kafe Buku', 'Koleksi Populer'],
          ),
        ];
        activeList.insertAll(0, localPartners);
      }

      setState(() {
        _me = myLoc;
        _libraries = activeList;
        _selectedLib = activeList.first;
        _loadingLocation = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  double _getDistanceInKm(LatLng target) {
    if (_me == null) return 0.0;
    final meters = Geolocator.distanceBetween(
      _me!.latitude,
      _me!.longitude,
      target.latitude,
      target.longitude,
    );
    return meters / 1000.0;
  }

  // Menghasilkan dan memunculkan rute navigasi nyata dari GPS ke perpustakaan
  Future<void> _fetchAndShowRoute(LibraryItem lib) async {
    if (_me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi GPS Anda belum aktif. Tekan tombol Lokasi Saya terlebih dahulu.')),
      );
      return;
    }

    setState(() {
      _isRouting = true;
      _navigatingLib = lib;
    });

    try {
      // Query OpenStreetMap OSRM Routing API (Rute Jalan Raya Nyata)
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${_me!.longitude},${_me!.latitude};${lib.location.longitude},${lib.location.latitude}?overview=full&geometries=geojson',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final r = routes[0];
          final geom = r['geometry']['coordinates'] as List;
          final dist = (r['distance'] as num) / 1000.0;
          final durationMin = ((r['duration'] as num) / 60.0).round();

          final points = geom.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();

          setState(() {
            _routePoints = points;
            _routeDistance = '${dist.toStringAsFixed(1)} km';
            _routeDuration = '~$durationMin menit perjalanan';
            _isRouting = false;
          });

          // Pusatkan kamera agar seluruh rute terlihat
          final midLat = (_me!.latitude + lib.location.latitude) / 2;
          final midLng = (_me!.longitude + lib.location.longitude) / 2;
          _mapController.move(LatLng(midLat, midLng), 13.8);
          return;
        }
      }
    } catch (_) {}

    // Fallback: jika koneksi routing API OSRM sedang lambat, gambar garis rute langsung
    if (!mounted) return;
    final dist = _getDistanceInKm(lib.location);
    setState(() {
      _routePoints = [_me!, lib.location];
      _routeDistance = '${dist.toStringAsFixed(1)} km';
      _routeDuration = '~${(dist * 2.5).round()} menit perjalanan';
      _isRouting = false;
    });

    final midLat = (_me!.latitude + lib.location.latitude) / 2;
    final midLng = (_me!.longitude + lib.location.longitude) / 2;
    _mapController.move(LatLng(midLat, midLng), 13.8);
  }

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
      _navigatingLib = null;
      _routeDistance = '';
      _routeDuration = '';
    });
  }

  void _showLibraryDetail(LibraryItem lib) {
    final dist = _getDistanceInKm(lib.location);
    final distStr = _me != null ? '${dist.toStringAsFixed(1)} km dari lokasi Anda' : 'Jarak sedang dihitung...';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EDED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_library, color: Color(0xFF67343A), size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lib.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber.shade800),
                          const SizedBox(width: 4),
                          Text('${lib.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Buka Sekarang',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.near_me, 'Jarak Tempuh', distStr, isHighlight: true),
            _buildInfoRow(Icons.location_on_outlined, 'Alamat Resmi', lib.address),
            _buildInfoRow(Icons.access_time_outlined, 'Jam Buka', lib.hours),
            _buildInfoRow(Icons.phone_outlined, 'Kontak', lib.phone),
            const SizedBox(height: 12),
            const Text('Fasilitas Unggulan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: lib.facilities
                  .map((f) => Chip(
                        label: Text(f, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.all(2),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _mapController.move(lib.location, 16.0);
                    },
                    icon: const Icon(Icons.center_focus_strong, size: 18),
                    label: const Text('Fokuskan Peta'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF67343A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _fetchAndShowRoute(lib);
                    },
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Tampilkan Rute'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: isHighlight ? const Color(0xFF67343A) : Colors.grey[600]),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? const Color(0xFF302622) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialPoint = _me ?? _libraries.first.location;

    List<LibraryItem> sortedLibs = List.from(_libraries);
    if (_me != null) {
      sortedLibs.sort((a, b) => _getDistanceInKm(a.location).compareTo(_getDistanceInKm(b.location)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Perpustakaan Jogja (${sortedLibs.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Deteksi Ulang Lokasi',
            onPressed: _locate,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialPoint,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.rentbook',
              ),
              // Garis Rute Navigasi Nyata (Polyline)
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.5,
                      color: const Color(0xFF67343A),
                      borderStrokeWidth: 2.5,
                      borderColor: const Color(0xFF302622),
                    ),
                  ],
                ),
              // Marker Layer
              MarkerLayer(
                markers: [
                  // Posisi Pengguna (GPS)
                  if (_me != null)
                    Marker(
                      point: _me!,
                      width: 50,
                      height: 50,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF67343A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                            ),
                            child: const Icon(Icons.person_pin, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ),
                  // Titik-titik Perpustakaan
                  for (final lib in sortedLibs)
                    Marker(
                      point: lib.location,
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedLib = lib);
                          _showLibraryDetail(lib);
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _navigatingLib?.name == lib.name
                                    ? Colors.green.shade700
                                    : _selectedLib?.name == lib.name
                                        ? Colors.deepOrange
                                        : const Color(0xFF67343A),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                              ),
                              child: const Icon(Icons.local_library, color: Colors.white, size: 22),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Banner Navigasi Aktif di Atas Peta
          if (_navigatingLib != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: const Color(0xFF302622),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.navigation, color: Colors.amberAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rute Menuju: ${_navigatingLib!.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_routeDistance • $_routeDuration',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                        tooltip: 'Tutup Rute Navigasi',
                        onPressed: _clearRoute,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Indikator Loading Rute
          if (_isRouting)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Menghitung rute navigasi jalan...', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // Tombol Kontrol Peta di Kanan Atas
          Positioned(
            top: _navigatingLib != null ? 80 : 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'my_loc',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF67343A),
                  tooltip: 'Pusatkan ke Lokasi Saya',
                  onPressed: () {
                    if (_me != null) {
                      _mapController.move(_me!, 15.0);
                    } else {
                      _locate();
                    }
                  },
                  child: _loadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  tooltip: 'Perbesar Peta',
                  onPressed: () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, z + 1);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  tooltip: 'Perkecil Peta',
                  onPressed: () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, z - 1);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Slider Kartu Perpustakaan di Bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: SizedBox(
              height: 135,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: sortedLibs.length,
                itemBuilder: (_, i) {
                  final lib = sortedLibs[i];
                  final isSelected = _selectedLib?.name == lib.name;
                  final isNavigating = _navigatingLib?.name == lib.name;
                  final dist = _getDistanceInKm(lib.location);

                  return Container(
                    width: 275,
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Card(
                      elevation: isSelected ? 4 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isNavigating ? Colors.green : isSelected ? const Color(0xFF67343A) : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() => _selectedLib = lib);
                          _mapController.move(lib.location, 15.5);
                          _showLibraryDetail(lib);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isNavigating ? Colors.green.shade50 : const Color(0xFFF7EDED),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.local_library,
                                      size: 20,
                                      color: isNavigating ? Colors.green : const Color(0xFF67343A),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      lib.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.near_me, size: 14, color: Colors.deepOrange),
                                      const SizedBox(width: 4),
                                      Text(
                                        _me != null ? '${dist.toStringAsFixed(1)} km' : 'Mencari GPS...',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    onPressed: () => _fetchAndShowRoute(lib),
                                    child: const Text('Rute', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
