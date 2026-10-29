import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/game_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  // Halaman yang dibuka setelah animasi selesai; nilainya dipilih di main.dart.
  final Widget destination;

  const SplashScreen({super.key, required this.destination});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // WARNA: warna elemen.
  static const _background = Color(0xFFEDE2CF);
  // WARNA: warna elemen.
  static const _coverColor = Color(0xFF67343A);
  // WARNA: warna elemen.
  static const _logoColor = Color(0xFFEDE2CF);

  // Mengendalikan seluruh animasi splash dari awal sampai selesai.
  late final AnimationController _controller;
  // Progress buka sampul, nilainya 0.0 sampai 1.0.
  late final Animation<double> _open;
  // Skala buku: mulai kecil, mendekat, lalu zoom untuk transisi.
  late final Animation<double> _zoom;
  // Progress animasi lembar halaman dibalik.
  late final Animation<double> _pageTurn;
  // Opacity lapisan putih untuk menyamarkan perpindahan halaman.
  late final Animation<double> _whiteFade;
  Timer? _pageSound;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Durasi total animasi splash adalah 2,8 detik.
      duration: const Duration(milliseconds: 2800),
    );
    _open = CurvedAnimation(
      parent: _controller,
      // Sampul membuka dari sekitar detik 0,64 sampai detik 1,46.
      curve: const Interval(.23, .52, curve: Curves.easeInOutCubic),
    );
    _zoom = TweenSequence<double>([
      // Weight adalah porsi relatif tiap tahap zoom, bukan satuan waktu.
      TweenSequenceItem(
        tween: Tween(begin: .9, end: .9),
        weight: 23,
      ),
      // Tahap 1: zoom perlahan dari 0,9 ke 1,02.
      TweenSequenceItem(
        tween: Tween(begin: .9, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 12,
      ),
      // Tahap 2: zoom sedikit dari 1,02 ke 1,06.
      TweenSequenceItem(
        tween: Tween(begin: 1.02, end: 1.06)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      // Tahap 3: zoom cepat ke 2,45 untuk transisi keluar.
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 2.45)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 26,
      ),
    ]).animate(_controller);
    _pageTurn = CurvedAnimation(
      parent: _controller,
      // Halaman dibalik dari sekitar detik 1,37 sampai detik 2,24.
      curve: const Interval(.49, .8, curve: Curves.easeInOutCubic),
    );
    _whiteFade = CurvedAnimation(
      parent: _controller,
      // Lapisan putih muncul dari sekitar detik 2,35 sampai 2,8.
      curve: const Interval(.84, 1, curve: Curves.easeIn),
    );
    // Efek suara membalik halaman diputar 0,7 detik setelah splash mulai.
    _pageSound = Timer(const Duration(milliseconds: 700), () {
      if (mounted) unawaited(GameAudioService.playPageTurn());
    });
    // Setelah controller mencapai akhir, lanjut ke halaman tujuan.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) _openApp();
    });
    _checkPendingAndStart();
  }

  Future<void> _checkPendingAndStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Jika aplikasi kembali dari kamera AI Vision, jangan tampilkan splash lagi.
      if (prefs.getBool('ai_vision_camera_pending') == true) {
        if (mounted) _openApp();
        return;
      }
    } catch (_) {}
    // Mulai animasi hanya jika widget masih berada di layar.
    if (mounted) {
      _controller.forward();
    }
  }

  void _openApp() {
    // Ganti splash dengan tujuan supaya tombol Back tidak kembali ke splash.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => widget.destination,
        // Halaman tujuan muncul dengan transisi fade selama 0,28 detik.
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _bookCover() {
    // Sampul 2D dengan logo, ornamen, gradasi, dan bayangan.
    return Container(
      width: 204,
      height: 282,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          // WARNA: gradasi komponen ini.
          colors: [Color(0xFF82464C), _coverColor, Color(0xFF4E252B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, .28, 1],
        ),
        borderRadius: BorderRadius.circular(8),
        // WARNA: latar kartu/komponen.
        border: Border.all(color: const Color(0xFFD4BE9D), width: 1.5),
        boxShadow: const [
          BoxShadow(
            // WARNA: bayangan kartu.
            color: Color(0x55271A16),
            blurRadius: 22,
            offset: Offset(7, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BookCoverOrnamentPainter()),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  _logoColor,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/rentbook_logo.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Hentikan timer dan animasi agar tidak berjalan setelah halaman ditutup.
    _pageSound?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // WARNA: latar halaman.
      backgroundColor: _background,
      body: SafeArea(
        child: AnimatedBuilder(
            // Bangun ulang tampilan ketika nilai animasi berubah.
            animation: _controller,
            builder: (context, _) {
              final open = _open.value;
              // Sampul mulai memudar setelah progress buka melewati 0,72.
              final coverFade = (1 - ((open - .72) / .28).clamp(0.0, 1.0))
                  .toDouble();

              return Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Transform.scale(
                      scale: _zoom.value,
                      child: SizedBox(
                        width: 310,
                        height: 330,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _OpenBookPainter(
                                  // Kirim progress buka dan balik halaman ke painter.
                                  progress: open,
                                  turnProgress: _pageTurn.value,
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: coverFade,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  // Angka ini memberi perspektif; rotateY memutar sampul pada sumbu Y.
                                  ..setEntry(3, 2, .0017)
                                  ..rotateY(-1.43 * open),
                                child: _bookCover(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        // WARNA: warna komponen.
                        color: Colors.white.withValues(alpha: _whiteFade.value),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ),
    );
  }
}

class _BookCoverOrnamentPainter extends CustomPainter {
  // Menggambar garis hias emas pada sampul buku.
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      // WARNA: gambar ilustrasi burung hantu.
      ..color = const Color(0xFFD4BE9D).withValues(alpha: .76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fineGold = Paint()
      // WARNA: gambar ilustrasi burung hantu.
      ..color = const Color(0xFFD4BE9D).withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
        const Radius.circular(4),
      ),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(17, 17, size.width - 34, size.height - 34),
        const Radius.circular(3),
      ),
      fineGold,
    );

    for (final corner in const [
      Offset(22, 22),
      Offset(-1, 22),
      Offset(22, -1),
      Offset(-1, -1),
    ]) {
      canvas.save();
      canvas.translate(
        corner.dx < 0 ? size.width - 22 : corner.dx,
        corner.dy < 0 ? size.height - 22 : corner.dy,
      );
      canvas.scale(corner.dx < 0 ? -1 : 1, corner.dy < 0 ? -1 : 1);
      final flourish = Path()
        ..moveTo(0, 28)
        ..cubicTo(0, 11, 8, 0, 28, 0)
        ..cubicTo(18, 4, 17, 13, 27, 14)
        ..cubicTo(19, 18, 13, 17, 14, 27)
        ..cubicTo(8, 19, 4, 22, 0, 28)
        ..close();
      canvas.drawPath(flourish, gold);
      canvas.drawCircle(const Offset(5, 5), 2.2, fineGold);
      canvas.restore();
    }

    canvas.drawLine(
      Offset(size.width * .2, size.height * .83),
      Offset(size.width * .8, size.height * .83),
      fineGold,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height * .83), 3, gold);
  }

  @override
  bool shouldRepaint(covariant _BookCoverOrnamentPainter oldDelegate) => false;
}

class _OpenBookPainter extends CustomPainter {
  // Nilai animasi dari SplashScreen; painter tidak memiliki controller sendiri.
  final double progress;
  final double turnProgress;

  const _OpenBookPainter({required this.progress, required this.turnProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // Belum gambar halaman sebelum animasi buka dimulai.
    if (progress <= 0) return;

    final centerX = size.width / 2;
    final top = size.height * .13;
    final bottom = size.height * .87;
    final spread = size.width * .47 * progress;

    final leftPage = Path()
      ..moveTo(centerX, top + 4)
      ..cubicTo(centerX - spread * .34, top - 5, centerX - spread * .78, top - 1, centerX - spread, top + 9)
      ..lineTo(centerX - spread, bottom - 8)
      ..cubicTo(centerX - spread * .62, bottom - 1, centerX - spread * .25, bottom + 2, centerX, bottom - 5)
      ..close();
    final rightPage = Path()
      ..moveTo(centerX, top + 4)
      ..cubicTo(centerX + spread * .34, top - 5, centerX + spread * .78, top - 1, centerX + spread, top + 9)
      ..lineTo(centerX + spread, bottom - 8)
      ..cubicTo(centerX + spread * .62, bottom - 1, centerX + spread * .25, bottom + 2, centerX, bottom - 5)
      ..close();

    // WARNA: gambar ilustrasi burung hantu.
    canvas.drawShadow(leftPage, Colors.black.withValues(alpha: .2 * progress), 8, true);
    // WARNA: gambar ilustrasi burung hantu.
    canvas.drawShadow(rightPage, Colors.black.withValues(alpha: .2 * progress), 8, true);
    // WARNA: bayangan ikon/teks.
    canvas.drawPath(leftPage, Paint()..color = const Color(0xFFFFFCF3).withValues(alpha: progress));
    // WARNA: bayangan ikon/teks.
    canvas.drawPath(rightPage, Paint()..color = const Color(0xFFFFFCF3).withValues(alpha: progress));

    final pageEdge = Paint()
      // WARNA: bayangan ikon/teks.
      ..color = const Color(0xFFD4BE9D).withValues(alpha: .82 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Delapan lembar memakai progress berbeda agar terlihat seperti halaman dibalik berurutan.
    const pageCount = 8;
    for (var page = 0; page < pageCount; page++) {
      final turn = (turnProgress * pageCount - page)
          .clamp(0.0, 1.0)
          .toDouble();
      final angle = turn * 3.141592653589793;
      final direction = angle < 1.5707963267948966 ? 1.0 : -1.0;
      final pageWidth = spread * math.cos(angle).abs();
      final curl = (9 + page % 3 * 2) *
          progress *
          (1 - (2 * turn - 1).abs());
      final sheet = Path()
        ..moveTo(centerX, top + 5)
        ..cubicTo(
          centerX + direction * pageWidth * .36,
          top - curl,
          centerX + direction * pageWidth * .78,
          top + curl * .35,
          centerX + direction * pageWidth,
          top + 10,
        )
        ..lineTo(centerX + direction * pageWidth, bottom - 8)
        ..cubicTo(
          centerX + direction * pageWidth * .72,
          bottom + curl * .4,
          centerX + direction * pageWidth * .34,
          bottom - curl,
          centerX,
          bottom - 5,
        )
        ..close();
      // WARNA: warna elemen.
      canvas.drawShadow(sheet, Colors.black.withValues(alpha: .12 * progress), 5, true);
      canvas.drawPath(
        sheet,
        // WARNA: bayangan ikon/teks.
        Paint()..color = const Color(0xFFFFFDF7).withValues(alpha: .94 * progress),
      );
      canvas.drawPath(sheet, pageEdge..strokeWidth = .8..style = PaintingStyle.stroke);
    }

    for (var i = 0; i < 4; i++) {
      final y = bottom - 5 + i * 1.7;
      canvas.drawLine(Offset(centerX - spread, y), Offset(centerX, y + 4), pageEdge);
      canvas.drawLine(Offset(centerX, y + 4), Offset(centerX + spread, y), pageEdge);
    }

    final textRule = Paint()
      // WARNA: gambar ilustrasi burung hantu.
      ..color = const Color(0xFFB9A687).withValues(alpha: .48 * progress)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = top + 34 + i * 17;
      if (y < bottom - 20) {
        canvas.drawLine(Offset(centerX - spread * .82, y), Offset(centerX - spread * .16, y + 2), textRule);
        canvas.drawLine(Offset(centerX + spread * .16, y + 2), Offset(centerX + spread * .82, y), textRule);
      }
    }

    final binding = Paint()
      // WARNA: gambar ilustrasi burung hantu.
      ..color = const Color(0xFF8D7460).withValues(alpha: .45 * progress)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(centerX, top + 5), Offset(centerX, bottom - 6), binding);
    canvas.drawLine(Offset(centerX - 3, top + 8), Offset(centerX - 3, bottom - 8), pageEdge);
  }

  // Gambar ulang hanya ketika progress buka atau balik halaman berubah.
  @override
  bool shouldRepaint(covariant _OpenBookPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.turnProgress != turnProgress;
}
