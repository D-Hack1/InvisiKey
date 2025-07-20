import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const SecurePayApp());
}

class SecurePayApp extends StatelessWidget {
  const SecurePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Pay',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      home: LoginScreen(),
    );
  }
}
