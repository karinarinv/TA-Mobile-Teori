import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/login_page.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final user = await AuthService.currentSession();
  runApp(MyApp(startLoggedIn: user != null));
}

class MyApp extends StatelessWidget {
  final bool startLoggedIn;
  const MyApp({super.key, required this.startLoggedIn});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'RentBook',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: startLoggedIn ? const HomeShell() : const LoginPage(),
      );
}
