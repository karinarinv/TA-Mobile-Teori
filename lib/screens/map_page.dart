import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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
    required this.facilities,
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

  List<LibraryItem> _libraries = [];
  bool _loadingLibraries = true;
  String? _libraryLoadError;

  @override
  void initState() {
    super.initState();
    _loadCloud().then((_) {
      if (mounted && _libraries.isNotEmpty) _locate();
    });
  }

  Future<void> _loadCloud() async {
    if (mounted) {
      setState(() {
        _loadingLibraries = true;
        _libraryLoadError = null;
      });
    }
    final result = await CloudService.selectWhere('libraries', filters: {});
    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _libraries = [];
        _libraryLoadError = result.message;
        _loadingLibraries = false;
      });
      return;
    }

    // Supabase may contain repeated rows for the same branch, including rows
    // where only some fields were filled. Merge those rows before displaying.
    final librariesByKey = <String, LibraryItem>{};
    for (final row in result.rows) {
      final latitude = double.tryParse('${row['lat']}');
      final longitude = double.tryParse('${row['lng']}');
      final name = row['name']?.toString().trim() ?? '';
      if (name.isEmpty ||
          latitude == null ||
          longitude == null ||
          !latitude.isFinite ||
          !longitude.isFinite ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        continue;
      }

      final rawFacilities = row['facilities'];
      final facilities = rawFacilities is List
          ? rawFacilities.map((value) => value.toString()).toList()
          : const <String>[];
      final item = LibraryItem(
          name: name,
          location: LatLng(latitude, longitude),
          address: row['address']?.toString() ?? '',
          hours: row['hours']?.toString() ?? '',
          phone: row['phone']?.toString() ?? '',
          rating: (row['rating'] as num?)?.toDouble() ?? 0,
          facilities: facilities,
        );
      final key = '${name.toLowerCase()}|${latitude.toStringAsFixed(5)}|${longitude.toStringAsFixed(5)}';
      final existing = librariesByKey[key];
      if (existing == null) {
        librariesByKey[key] = item;
      } else {
        librariesByKey[key] = LibraryItem(
          name: existing.name,
          location: existing.location,
          address: _firstNonEmpty(existing.address, item.address),
          hours: _firstNonEmpty(existing.hours, item.hours),
          phone: _firstNonEmpty(existing.phone, item.phone),
          rating: existing.rating > 0 ? existing.rating : item.rating,
          facilities: {...existing.facilities, ...item.facilities}.toList(),
        );
      }
    }
    final libraries = librariesByKey.values.toList();

    setState(() {
      _libraries = libraries;
      _libraryLoadError = libraries.isEmpty
          ? 'Belum ada lokasi perpustakaan di database.'
          : null;
      _loadingLibraries = false;
    });
  }

  String _firstNonEmpty(String first, String second) =>
      first.trim().isNotEmpty ? first : second;

  Future<void> _refreshLibraries() async {
    await _loadCloud();
    if (mounted && _libraries.isNotEmpty) await _locate();
  }

  Future<void> _locate() async {
    setState(() => _loadingLocation = true);
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final myLoc = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _me = myLoc;
        if (_libraries.isNotEmpty) _selectedLib = _libraries.first;
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
        const SnackBar(
          content: Text(
            'Lokasi GPS Anda belum aktif. Tekan tombol Lokasi Saya terlebih dahulu.',
          ),
        ),
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

          final points = geom
              .map(
                (c) =>
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
              )
              .toList();

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
    final distStr = _me != null
        ? '${dist.toStringAsFixed(1)} km dari lokasi Anda'
        : 'Jarak sedang dihitung...';

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
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_library,
                    color: Color(0xFF67343A),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lib.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lib.rating}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Buka Sekarang',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
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
            _buildInfoRow(
              Icons.near_me,
              'Jarak Tempuh',
              distStr,
              isHighlight: true,
            ),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Alamat Resmi',
              lib.address,
            ),
            _buildInfoRow(Icons.access_time_outlined, 'Jam Buka', lib.hours),
            _buildInfoRow(Icons.phone_outlined, 'Kontak', lib.phone),
            const SizedBox(height: 12),
            const Text(
              'Fasilitas Unggulan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: lib.facilities
                  .map(
                    (f) => Chip(
                      label: Text(f, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.all(2),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isHighlight ? const Color(0xFF67343A) : Colors.grey[600],
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
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
    final initialPoint = _libraries.isEmpty
        ? const LatLng(-7.7956, 110.3695)
        : _me ?? _libraries.first.location;

    List<LibraryItem> sortedLibs = List.from(_libraries);
    if (_me != null) {
      sortedLibs.sort(
        (a, b) =>
            _getDistanceInKm(a.location)
                .compareTo(_getDistanceInKm(b.location)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perpustakaan Terdekat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Deteksi Ulang Lokasi',
            onPressed: _refreshLibraries,
          ),
        ],
      ),
      body: _loadingLibraries
          ? const Center(child: CircularProgressIndicator())
          : _libraries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_library_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _libraryLoadError ??
                          'Lokasi perpustakaan belum tersedia.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _refreshLibraries,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialPoint,
                    initialZoom: 13.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_pin,
                                    color: Colors.white,
                                    size: 24,
                                  ),
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
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.local_library,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                if (_navigatingLib != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: const Color(0xFF302622),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.amberAccent,
                                size: 22,
                              ),
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
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 22,
                              ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Menghitung rute navigasi jalan...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                          _mapController.move(
                            _mapController.camera.center,
                            z + 1,
                          );
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
                          _mapController.move(
                            _mapController.camera.center,
                            z - 1,
                          );
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),

                // Slider card Perpustakaan Elegan & Nyaman
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: SizedBox(
                    height: 146,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: sortedLibs.length,
                      itemBuilder: (_, i) {
                        final lib = sortedLibs[i];
                        final isSelected = _selectedLib?.name == lib.name;
                        final isNavigating = _navigatingLib?.name == lib.name;
                        final dist = _getDistanceInKm(lib.location);

                        return Container(
                          width: 285,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isNavigating
                                  ? Colors.green.shade600
                                  : isSelected
                                  ? const Color(0xFF67343A)
                                  : const Color(0xFFEADBCE),
                              width: isNavigating || isSelected ? 2.0 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF302622)
                                    .withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                setState(() => _selectedLib = lib);
                                _mapController.move(lib.location, 15.5);
                                _showLibraryDetail(lib);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isNavigating
                                                ? Colors.green.shade50
                                                : const Color(0xFFEDE2CF),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.local_library_rounded,
                                            size: 20,
                                            color: isNavigating
                                                ? Colors.green.shade700
                                                : const Color(0xFF67343A),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lib.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Color(0xFF302622),
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.star_rounded,
                                                    size: 14,
                                                    color:
                                                        Colors.amber.shade700,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${lib.rating}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFAF7F2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFEADBCE),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.near_me_rounded,
                                                size: 13,
                                                color: Color(0xFF9A704F),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _me != null
                                                    ? '${dist.toStringAsFixed(1)} km'
                                                    : 'Mencari GPS...',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF67343A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: isNavigating
                                                ? Colors.green.shade700
                                                : const Color(0xFF67343A),
                                            foregroundColor: Colors.white,
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.directions_rounded,
                                            size: 15,
                                          ),
                                          label: Text(
                                            isNavigating ? 'Aktif' : 'Rute',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: () =>
                                              _fetchAndShowRoute(lib),
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
