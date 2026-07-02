import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'features/welcome/welcome_screen.dart';
import 'core/navigation/main_navigation.dart';
import 'core/session/user_session.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const SmartFarmApp());
}

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Petani AI",
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Widget _page = const Scaffold(
    body: Center(child: CircularProgressIndicator(color: Colors.green)),
  );

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final user = await UserSession.getUser();

    // Delay sedikit untuk efek splash screen
    await Future.delayed(const Duration(milliseconds: 800));

    if (user != null) {
      if (!mounted) return;
      setState(() {
        _page = MainNavigation(user: user);
      });
    } else {
      if (!mounted) return;
      setState(() {
        _page = const WelcomeScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) => _page;
}