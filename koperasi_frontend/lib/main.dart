import 'dart:async';

import 'package:flutter/material.dart';
import 'screens/admin/home_admin.dart';
import 'screens/cashier/home_cashier.dart';
import 'screens/drawer/navbar.dart';
import 'screens/login.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _sessionTimer;
  Timer? _sessionCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleSessionTimeout();
    _sessionCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _redirectToLoginIfSessionExpired(),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _sessionCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _redirectToLoginIfSessionExpired();
      _scheduleSessionTimeout();
    }
  }

  Future<void> _scheduleSessionTimeout() async {
    _sessionTimer?.cancel();

    final expiresAt = await AuthService.getSessionExpiresAt();

    if (expiresAt == null) {
      return;
    }

    final remaining = expiresAt.difference(DateTime.now());

    if (remaining.isNegative || remaining == Duration.zero) {
      _redirectToLoginIfSessionExpired();
      return;
    }

    _sessionTimer = Timer(remaining, _redirectToLoginIfSessionExpired);
  }

  Future<void> _redirectToLoginIfSessionExpired() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    final valid = await AuthService.isSessionValid();

    if (valid) {
      return;
    }

    _sessionTimer?.cancel();
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Koperasi App',
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Widget _homeForRole(String? role) {
    if (role == 'member') {
      return const Navbar();
    }

    if (role == 'worker') {
      return const Navbar(isWorkerAccount: true);
    }

    if (role == 'cashier') {
      return const HomeCashier();
    }

    if (role == 'admin') {
      return const HomeAdmin();
    }

    return const Login();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.getValidRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _homeForRole(snapshot.data);
      },
    );
  }
}
