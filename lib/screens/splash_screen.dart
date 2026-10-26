import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/game_audio_service.dart';

class SplashScreen extends StatefulWidget {
  final Widget destination;

  const SplashScreen({super.key, required this.destination});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFFEDE2CF);
  static const _coverColor = Color(0xFF67343A);
  static const _logoColor = Color(0xFFEDE2CF);

  late final AnimationController _controller;
  late final Animation<double> _open;
  late final Animation<double> _zoom;
  late final Animation<double> _pageTurn;
  late final Animation<double> _whiteFade;
  Timer? _pageSound;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    );
    _open = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.08, .92, curve: Curves.easeInOutCubic),
    );
    _zoom = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: .84, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 62,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.02, end: 2.45)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 38,
      ),
    ]).animate(_controller);
    _pageTurn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.34, .86, curve: Curves.easeInOutCubic),
    );
    _whiteFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.78, 1, curve: Curves.easeIn),
    );
    _pageSound = Timer(const Duration(milliseconds: 250), () {
      if (mounted) unawaited(GameAudioService.playPageTurn());
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) _openApp();
    });
    _controller.forward();
  }

  void _openApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => widget.destination,
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _bookCover() {
    return Container(
      width: 204,
      height: 282,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF82464C), _coverColor, Color(0xFF4E252B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, .28, 1],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4BE9D), width: 1.5),
        boxShadow: const [
          BoxShadow(
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
    _pageSound?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final open = _open.value;
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
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = const Color(0xFFD4BE9D).withValues(alpha: .76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fineGold = Paint()
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
  final double progress;
  final double turnProgress;

  const _OpenBookPainter({required this.progress, required this.turnProgress});

  @override
  void paint(Canvas canvas, Size size) {
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

    canvas.drawShadow(leftPage, Colors.black.withValues(alpha: .2 * progress), 8, true);
    canvas.drawShadow(rightPage, Colors.black.withValues(alpha: .2 * progress), 8, true);
    canvas.drawPath(leftPage, Paint()..color = const Color(0xFFFFFCF3).withValues(alpha: progress));
    canvas.drawPath(rightPage, Paint()..color = const Color(0xFFFFFCF3).withValues(alpha: progress));

    final pageEdge = Paint()
      ..color = const Color(0xFFD4BE9D).withValues(alpha: .82 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Three quick page turns add movement while keeping the open-book shape visible.
    for (var page = 0; page < 3; page++) {
      final turn = (turnProgress * 3 - page).clamp(0.0, 1.0).toDouble();
      final angle = turn * 3.141592653589793;
      final direction = angle < 1.5707963267948966 ? 1.0 : -1.0;
      final pageWidth = spread * math.cos(angle).abs();
      final curl = 11 * progress * (1 - (2 * turn - 1).abs());
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
      canvas.drawShadow(sheet, Colors.black.withValues(alpha: .12 * progress), 5, true);
      canvas.drawPath(
        sheet,
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
      ..color = const Color(0xFF8D7460).withValues(alpha: .45 * progress)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(centerX, top + 5), Offset(centerX, bottom - 6), binding);
    canvas.drawLine(Offset(centerX - 3, top + 8), Offset(centerX - 3, bottom - 8), pageEdge);
  }

  @override
  bool shouldRepaint(covariant _OpenBookPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.turnProgress != turnProgress;
}
