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
  late final AnimationController _controller;
  final List<Timer> _soundTimers = [];

  static const _background = Color(0xFF302622);
  static const _logoTint = Color(0xFFEDE2CF);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Gentle page-turn sounds accompany the falling books.
    for (final delay in const [450, 1350]) {
      _soundTimers.add(Timer(Duration(milliseconds: delay), () {
        if (mounted) unawaited(GameAudioService.playPageTurn());
      }));
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) _openApp();
    });
    _controller.forward();
  }

  void _openApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => widget.destination,
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    for (final timer in _soundTimers) {
      timer.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoWidth = math.min(270.0, constraints.maxWidth * .76);
            final logoHeight = logoWidth * (204 / 326);

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = _controller.value;
                final fade =
                    (1 - ((progress - .80) / .17).clamp(0.0, 1.0)).toDouble();

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: _background),
                    Center(
                      child: SizedBox(
                        width: logoWidth,
                        height: logoHeight,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            _logoTint,
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
                    // Draw the falling books last so they cross in front of the logo.
                    Positioned.fill(
                      child: Opacity(
                        opacity: fade,
                        child: CustomPaint(
                          painter: _FallingBooksPainter(progress: progress),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FallingBook {
  final double x;
  final double delay;
  final double width;
  final double height;
  final double angle;
  final double phase;
  final Color cover;
  final String title;

  const _FallingBook({
    required this.x,
    required this.delay,
    required this.width,
    required this.height,
    required this.angle,
    required this.phase,
    required this.cover,
    required this.title,
  });
}

class _FallingBooksPainter extends CustomPainter {
  final double progress;

  static const _books = [
    _FallingBook(x: .08, delay: .00, width: 46, height: 66, angle: -.28, phase: .2, cover: Color(0xFF8B4448), title: 'CERITA'),
    _FallingBook(x: .28, delay: .12, width: 54, height: 76, angle: .22, phase: 1.3, cover: Color(0xFFAD7447), title: 'PUSTAKA'),
    _FallingBook(x: .51, delay: .04, width: 42, height: 61, angle: -.42, phase: 2.4, cover: Color(0xFF435A4D), title: 'KISAH'),
    _FallingBook(x: .76, delay: .20, width: 52, height: 72, angle: .34, phase: 3.1, cover: Color(0xFF665078), title: 'DUNIA'),
    _FallingBook(x: .93, delay: .08, width: 43, height: 64, angle: -.16, phase: 4.3, cover: Color(0xFFB15F3C), title: 'BACA'),
    _FallingBook(x: .17, delay: .31, width: 56, height: 78, angle: .39, phase: 5.1, cover: Color(0xFF40566B), title: 'PETUALANGAN'),
    _FallingBook(x: .40, delay: .25, width: 45, height: 65, angle: -.31, phase: .8, cover: Color(0xFF9A653D), title: 'RAHASIA'),
    _FallingBook(x: .64, delay: .35, width: 58, height: 80, angle: .14, phase: 2.8, cover: Color(0xFF754348), title: 'KENANGAN'),
    _FallingBook(x: .85, delay: .29, width: 48, height: 68, angle: -.37, phase: 3.7, cover: Color(0xFF596748), title: 'IMAJINASI'),
    _FallingBook(x: .03, delay: .46, width: 50, height: 72, angle: .25, phase: 4.9, cover: Color(0xFF725542), title: 'SAJAK'),
    _FallingBook(x: .34, delay: .48, width: 44, height: 63, angle: -.19, phase: 1.7, cover: Color(0xFF93594D), title: 'BINTANG'),
    _FallingBook(x: .57, delay: .43, width: 52, height: 74, angle: .43, phase: 5.8, cover: Color(0xFF4E536A), title: 'RAK EMAS'),
    _FallingBook(x: .79, delay: .52, width: 45, height: 65, angle: -.26, phase: 2.1, cover: Color(0xFFAA7B3E), title: 'MIMPI'),
    _FallingBook(x: .98, delay: .41, width: 55, height: 77, angle: .18, phase: .5, cover: Color(0xFF50665D), title: 'PETUALANGAN'),
  ];

  const _FallingBooksPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final book in _books) {
      final local = ((progress - book.delay) / (1 - book.delay))
          .clamp(0.0, 1.0)
          .toDouble();
      if (local <= 0 || progress >= .98) continue;

      final fall = Curves.easeIn.transform(local);
      final sway = math.sin(local * math.pi * 3 + book.phase) * size.width * .035;
      final x = size.width * book.x + sway;
      final y = -book.height * 1.4 + fall * (size.height + book.height * 2.8);
      final rotation = book.angle + math.sin(local * math.pi * 4 + book.phase) * .14;
      final alpha = ((1 - ((progress - .80) / .17).clamp(0.0, 1.0)) * 255).round();

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      _drawBook(canvas, book, alpha);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawBook(Canvas canvas, _FallingBook book, int alpha) {
    final w = book.width;
    final h = book.height;
    final rect = Rect.fromLTWH(-w / 2, -h / 2, w, h);
    final shadow = Path()
      ..addRRect(RRect.fromRectAndRadius(rect.shift(const Offset(3, 4)), const Radius.circular(3)));
    canvas.drawShadow(shadow, Colors.black.withAlpha(alpha), 5, true);

    final pages = Paint()..color = const Color(0xFFF3E7D1).withAlpha(alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(Offset(w * .11, h * .055)), const Radius.circular(3)),
      pages,
    );

    final edge = Paint()..color = _shade(book.cover, .65).withAlpha(alpha);
    final pageEdge = Path()
      ..moveTo(rect.right, rect.top + 5)
      ..lineTo(rect.right + w * .1, rect.top + 9)
      ..lineTo(rect.right + w * .1, rect.bottom - 2)
      ..lineTo(rect.right, rect.bottom - 5)
      ..close();
    canvas.drawPath(pageEdge, edge);

    final cover = Paint()..color = book.cover.withAlpha(alpha);
    final coverRect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(coverRect, cover);

    final spine = Paint()..color = _shade(book.cover, .72).withAlpha(alpha);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(rect.left, rect.top, w * .16, h),
        topLeft: const Radius.circular(3),
        bottomLeft: const Radius.circular(3),
      ),
      spine,
    );

    final foil = Paint()
      ..color = const Color(0xFFE7C98F).withAlpha((alpha * .88).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(2)),
      foil,
    );
    canvas.drawLine(
      Offset(rect.left + w * .16, rect.top + 5),
      Offset(rect.left + w * .16, rect.bottom - 5),
      foil,
    );

    final medallion = Paint()..color = const Color(0xFFE7C98F).withAlpha(alpha);
    canvas.drawCircle(Offset(0, -h * .18), math.min(w, h) * .095, medallion);
    final symbol = Paint()
      ..color = book.cover.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final badge = Path()
      ..moveTo(-w * .055, -h * .20)
      ..lineTo(0, -h * .16)
      ..lineTo(w * .055, -h * .20)
      ..lineTo(w * .055, -h * .14)
      ..lineTo(0, -h * .17)
      ..lineTo(-w * .055, -h * .14)
      ..close();
    canvas.drawPath(badge, symbol);

    final title = TextPainter(
      text: TextSpan(
        text: book.title,
        style: TextStyle(
          color: const Color(0xFFFFF4DD).withAlpha(alpha),
          fontSize: book.width * .13,
          fontWeight: FontWeight.w800,
          letterSpacing: .15,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: w * .68);
    title.paint(canvas, Offset(-title.width / 2 + w * .07, -h * .02));

    final bottomRule = Paint()
      ..color = const Color(0xFFE7C98F).withAlpha((alpha * .75).round())
      ..strokeWidth = 1.1;
    canvas.drawLine(Offset(-w * .12, h * .27), Offset(w * .19, h * .27), bottomRule);
  }

  Color _shade(Color color, double amount) => Color.fromARGB(
        color.alpha,
        (color.red * amount).round(),
        (color.green * amount).round(),
        (color.blue * amount).round(),
      );

  @override
  bool shouldRepaint(covariant _FallingBooksPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
