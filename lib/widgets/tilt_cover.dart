import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Sensor 2: Gyroscope -> sampul buku miring 3D saat HP diputar.
class TiltCover extends StatefulWidget {
  final Widget child;
  const TiltCover({super.key, required this.child});
  @override
  State<TiltCover> createState() => _TiltCoverState();
}

class _TiltCoverState extends State<TiltCover> {
  double _x = 0, _y = 0;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = gyroscopeEventStream().listen((e) {
      if (!mounted) return;
      setState(() {
        _x = (_x + e.x * 0.05).clamp(-0.5, 0.5) * 0.95;
        _y = (_y + e.y * 0.05).clamp(-0.5, 0.5) * 0.95;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateX(_x)
          ..rotateY(_y),
        child: widget.child,
      );
}
