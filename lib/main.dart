import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/app_colors.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/session_service.dart';
import 'screens/login_page.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService.init();

  final expired = await SessionService.isSessionExpired();
  if (expired) {
    await AuthService.logout();
  } else {
    SessionService.recordActivity();
  }

  final user = await AuthService.currentSession();
  runApp(MyApp(startLoggedIn: user != null));
}

class MyApp extends StatefulWidget {
  final bool startLoggedIn;
  const MyApp({super.key, required this.startLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SessionService.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SessionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionService.checkTimeout();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      SessionService.persistActivity();
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => SessionService.recordActivity(),
        onPointerMove: (_) => SessionService.recordActivity(),
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'RentBook',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              // WARNA: warna komponen.
              seedColor: AppColors.oxblood,
              // WARNA: warna utama tombol dan elemen aktif.
              primary: AppColors.oxblood,
              // WARNA: warna aksen aplikasi.
              secondary: AppColors.tobacco,
              // WARNA: latar kartu dan panel.
              surface: const Color(0xFFFAF7F2),
              // WARNA: latar kartu dan panel.
              surfaceContainer: const Color(0xFFFAF7F2),
              // WARNA: latar kartu dan panel.
              surfaceContainerLow: const Color(0xFFFAF7F2),
              // WARNA: latar kartu dan panel.
              surfaceContainerHigh: const Color(0xFFEDE2CF),
              // WARNA: latar kartu dan panel.
              surfaceTint: Colors.transparent,
            ),
            cardTheme: const CardThemeData(
              // WARNA: warna komponen.
              color: Color(0xFFFAF7F2),
              // WARNA: warna komponen.
              surfaceTintColor: Colors.transparent,
              elevation: 1.5,
            ),
            appBarTheme: AppBarTheme(
              // WARNA: latar AppBar.
              backgroundColor: AppColors.oxblood,
              // WARNA: teks/ikon tombol.
              foregroundColor: AppColors.parchment,
              elevation: 0,
              titleTextStyle: GoogleFonts.playfairDisplay(
                // WARNA: teks judul/isi pada bagian ini.
                color: AppColors.parchment,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            // WARNA: latar komponen.
            scaffoldBackgroundColor: AppColors.background,
            textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
              headlineLarge: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                // WARNA: teks judul/isi pada bagian ini.
                color: AppColors.walnut,
              ),
              headlineMedium: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                // WARNA: teks judul/isi pada bagian ini.
                color: AppColors.walnut,
              ),
              titleLarge: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                // WARNA: teks judul/isi pada bagian ini.
                color: AppColors.walnut,
              ),
              titleMedium: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                // WARNA: teks judul/isi pada bagian ini.
                color: AppColors.walnut,
              ),
            ),
            useMaterial3: true,
          ),
          home: SplashScreen(
            destination:
                widget.startLoggedIn ? const HomeShell() : const LoginPage(),
          ),
        ),
      );
}
