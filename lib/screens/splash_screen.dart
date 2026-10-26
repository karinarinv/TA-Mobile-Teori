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
  late final Animation<Offset> _bigISlide;
  late final Animation<Offset> _smallISlide;
  late final Animation<Offset> _rSlide;
  late final Animation<double> _textFade;
  final List<Timer> _soundTimers = [];

  Animation<Offset> _slide(double start, double end, Offset from) =>
      Tween<Offset>(begin: from, end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _bigISlide = _slide(0, .24, const Offset(-1.2, 0));
    _smallISlide = _slide(.20, .43, const Offset(0, 1.1));
    _rSlide = _slide(.38, .64, const Offset(1.2, 0));
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.60, .84, curve: Curves.easeIn),
    );

    // Three soft 8-bit chimes accompany the pieces as they settle in place.
    for (final delay in const [520, 1060, 1640]) {
      _soundTimers.add(Timer(Duration(milliseconds: delay), () {
        if (mounted) unawaited(GameAudioService.playTing());
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

  Widget _movingLogoPiece({
    required String asset,
    required Animation<Offset> animation,
    required double travel,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          animation.value.dx * travel,
          animation.value.dy * travel,
        ),
        child: child,
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
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
      backgroundColor: const Color(0xFF302622),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(constraints.maxWidth, constraints.maxHeight * .8);
            final height = width * 1.25;

            return Center(
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _movingLogoPiece(
                      asset: 'assets/images/splash screen I besar.png',
                      animation: _bigISlide,
                      travel: width,
                    ),
                    _movingLogoPiece(
                      asset: 'assets/images/Splash screen i kecil .png',
                      animation: _smallISlide,
                      travel: height,
                    ),
                    _movingLogoPiece(
                      asset: 'assets/images/Splash screen R.png',
                      animation: _rSlide,
                      travel: width,
                    ),
                    FadeTransition(
                      opacity: _textFade,
                      child: Image.asset(
                        'assets/images/Splash screen teks.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
