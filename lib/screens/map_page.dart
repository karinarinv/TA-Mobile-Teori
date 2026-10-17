import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/cloud_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _me;
  // Contoh data (ganti/tambah dari database online)
  Map<String, LatLng> _libs = const {
    'Perpustakaan Kota Yogyakarta': LatLng(-7.7829, 110.3671),
    'Grhatama Pustaka': LatLng(-7.7889, 110.4086),
    'Perpustakaan UGM': LatLng(-7.7713, 110.3774),
  };

  @override
  void initState() {
    super.initState();
    _locate();
    _loadCloud();
  }

  Future<void> _loadCloud() async {
    final rows = await CloudService.select('libraries');
    if (rows.isEmpty) return;
    setState(() => _libs = {for (final r in rows) r['name']: LatLng(double.parse('${r['lat']}'), double.parse('${r['lng']}'))});
  }

  Future<void> _locate() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition();
    setState(() => _me = LatLng(pos.latitude, pos.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final center = _me ?? _libs.values.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Perpustakaan / Tempat Sewa Terdekat')),
      body: FlutterMap(
        key: ValueKey(center),
        options: MapOptions(initialCenter: center, initialZoom: 13),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.rentbook',
          ),
          MarkerLayer(markers: [
            for (final e in _libs.entries)
              Marker(
                point: e.value,
                width: 40,
                height: 40,
                child: Tooltip(message: e.key, child: const Icon(Icons.local_library, color: Colors.indigo, size: 36)),
              ),
            if (_me != null)
              Marker(point: _me!, width: 40, height: 40, child: const Icon(Icons.my_location, color: Colors.red, size: 32)),
          ]),
        ],
      ),
    );
  }
}
