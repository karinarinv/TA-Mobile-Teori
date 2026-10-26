import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/app_colors.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/login_page.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService.init();
  final user = await AuthService.currentSession();
  runApp(MyApp(startLoggedIn: user != null));
}

class MyApp extends StatelessWidget {
  final bool startLoggedIn;
  const MyApp({super.key, required this.startLoggedIn});
  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'RentBook',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.oxblood,
            primary: AppColors.oxblood,
            secondary: AppColors.tobacco,
            surface: const Color(0xFFFAF7F2),
            surfaceContainer: const Color(0xFFFAF7F2),
            surfaceContainerLow: const Color(0xFFFAF7F2),
            surfaceContainerHigh: const Color(0xFFEDE2CF),
            surfaceTint: Colors.transparent,
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFFFAF7F2),
            surfaceTintColor: Colors.transparent,
            elevation: 1.5,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.oxblood,
            foregroundColor: AppColors.parchment,
            elevation: 0,
            titleTextStyle: GoogleFonts.playfairDisplay(
              color: AppColors.parchment,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
            headlineLarge: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: AppColors.walnut,
            ),
            headlineMedium: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: AppColors.walnut,
            ),
            titleLarge: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: AppColors.walnut,
            ),
            titleMedium: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: AppColors.walnut,
            ),
          ),
          useMaterial3: true,
        ),
        home: SplashScreen(
          destination: startLoggedIn ? const HomeShell() : const LoginPage(),
        ),
      );
}
