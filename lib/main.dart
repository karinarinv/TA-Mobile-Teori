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
  // Siapkan Flutter sebelum memanggil plugin atau membaca penyimpanan.
  WidgetsFlutterBinding.ensureInitialized();
  // Daftarkan format tanggal Bahasa Indonesia yang dipakai di aplikasi.
  await initializeDateFormatting('id_ID', null);
  // Siapkan notifikasi lokal sebelum halaman aplikasi ditampilkan.
  await NotificationService.init();

  // Hapus sesi yang sudah melewati batas tidak aktif; selain itu catat aktivitas.
  final expired = await SessionService.isSessionExpired();
  if (expired) {
    await AuthService.logout();
  } else {
    SessionService.recordActivity();
  }

  // Status login menentukan destination yang nanti diberikan ke SplashScreen.
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
              // WARNA: warna benih (seed) untuk menurunkan palet Material 3 global aplikasi.
              seedColor: AppColors.oxblood,
              // WARNA: warna primer global Material 3 (tombol FilledButton, ProgressIndicator, elemen aktif).
              primary: AppColors.oxblood,
              // WARNA: warna sekunder global Material 3 (elemen aksen dan sorotan pendukung).
              secondary: AppColors.tobacco,
              // WARNA: warna permukaan dasar global Material 3 (dialog, bottom sheet, dan panel default).
              surface: const Color(0xFFFAF7F2),
              // WARNA: warna latar container Material 3 standar.
              surfaceContainer: const Color(0xFFFAF7F2),
              // WARNA: warna latar container Material 3 elevasi rendah.
              surfaceContainerLow: const Color(0xFFFAF7F2),
              // WARNA: warna latar container Material 3 elevasi tinggi (misal chip/pil atau panel menonjol).
              surfaceContainerHigh: const Color(0xFFEDE2CF),
              // WARNA: tint permukaan global dibuat transparan agar warna kartu tidak berubah keunguan/kemerahan.
              surfaceTint: Colors.transparent,
            ),
            cardTheme: const CardThemeData(
              // WARNA: latar belakang default semua widget Card di aplikasi.
              color: Color(0xFFFAF7F2),
              // WARNA: tint elevasi default Card dibuat transparan agar warna tetap bersih.
              surfaceTintColor: Colors.transparent,
              elevation: 1.5,
            ),
            appBarTheme: AppBarTheme(
              // WARNA: latar belakang default AppBar di seluruh halaman yang tidak menimpanya.
              backgroundColor: AppColors.oxblood,
              // WARNA: warna default ikon kembali dan tombol aksi di AppBar.
              foregroundColor: AppColors.parchment,
              elevation: 0,
              titleTextStyle: GoogleFonts.playfairDisplay(
                // WARNA: warna teks judul default pada AppBar di seluruh halaman.
                color: AppColors.parchment,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            // WARNA: latar belakang default Scaffold (halaman) di seluruh aplikasi.
            scaffoldBackgroundColor: AppColors.background,
            textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
              headlineLarge: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                // WARNA: warna teks global gaya headlineLarge (judul utama halaman).
                color: AppColors.walnut,
              ),
              headlineMedium: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                // WARNA: warna teks global gaya headlineMedium (judul bagian besar).
                color: AppColors.walnut,
              ),
              titleLarge: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                // WARNA: warna teks global gaya titleLarge (judul dialog/kartu besar).
                color: AppColors.walnut,
              ),
              titleMedium: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                // WARNA: warna teks global gaya titleMedium (subjudul kartu).
                color: AppColors.walnut,
              ),
            ),
            useMaterial3: true,
          ),
          // SplashScreen mengatur animasi; pilihan halaman tujuan dibuat di sini.
          home: SplashScreen(
            destination:
                widget.startLoggedIn ? const HomeShell() : const LoginPage(),
          ),
        ),
      );
}
