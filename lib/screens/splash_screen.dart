import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget destination;

  const SplashScreen({super.key, required this.destination});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Animation<Offset> _slide(double start, double end, Offset from) =>
      Tween<Offset>(begin: from, end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  late final Animation<Offset> _iSlide;
  late final Animation<Offset> _stemSlide;
  late final Animation<Offset> _rSlide;
  late final Animation<double> _wordFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _iSlide = _slide(0, .24, const Offset(-1.2, 0));
    _stemSlide = _slide(.20, .43, const Offset(0, 1.1));
    _rSlide = _slide(.38, .64, const Offset(1.2, 0));
    _wordFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.60, .86, curve: Curves.easeIn),
    );
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

  Widget _logoSlice({
    required double left,
    required double top,
    required double width,
    required double height,
    required Animation<Offset> animation,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.translate(
            offset: Offset(animation.value.dx * 115, animation.value.dy * 115),
            child: child,
          ),
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 320,
            maxWidth: 320,
            minHeight: 200,
            maxHeight: 200,
            child: Transform.translate(
              offset: Offset(-left, -top),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFFD4BE9D),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/rentbook_logo.png',
                  width: 320,
                  height: 200,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF302622),
      body: Center(
        child: SizedBox(
          width: 320,
          height: 200,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Initial I mark enters from the left.
              _logoSlice(
                left: 25,
                top: 38,
                width: 43,
                height: 129,
                animation: _iSlide,
              ),
              // Short lower stroke rises into place.
              _logoSlice(
                left: 67,
                top: 99,
                width: 47,
                height: 68,
                animation: _stemSlide,
              ),
              // R mark arrives from the right.
              _logoSlice(
                left: 103,
                top: 38,
                width: 77,
                height: 129,
                animation: _rSlide,
              ),
              // RENTBOOK lettering fades in after the symbol is assembled.
              Positioned(
                left: 178,
                top: 38,
                width: 126,
                height: 129,
                child: FadeTransition(
                  opacity: _wordFade,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: 320,
                      maxWidth: 320,
                      minHeight: 200,
                      maxHeight: 200,
                      child: Transform.translate(
                        offset: const Offset(-178, -38),
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFD4BE9D),
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/images/rentbook_logo.png',
                            width: 320,
                            height: 200,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
