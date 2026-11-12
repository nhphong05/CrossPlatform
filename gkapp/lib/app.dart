import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/lecturer_list_screen.dart';
import 'services/auth_api.dart';
import 'services/lecturer_api.dart';

const _brandNavy = Color(0xFF344D7D);
const _brandOrange = Color(0xFFF7941D);
const _brandRed = Color(0xFFD52B42);
const _brandBackground = Color(0xFFF8F8FA);

class LecturerAdminApp extends StatelessWidget {
  const LecturerAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý giảng viên',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: _brandNavy,
              surface: _brandBackground,
            ).copyWith(
              primary: _brandNavy,
              onPrimary: Colors.white,
              primaryContainer: const Color(0xFFE7ECF5),
              onPrimaryContainer: _brandNavy,
              secondary: _brandOrange,
              onSecondary: const Color(0xFF2C2418),
              secondaryContainer: const Color(0xFFFFE9CF),
              onSecondaryContainer: const Color(0xFF57340B),
              tertiary: _brandRed,
              onTertiary: Colors.white,
              tertiaryContainer: const Color(0xFFFFE3E7),
              onTertiaryContainer: const Color(0xFF641B28),
              error: _brandRed,
              errorContainer: const Color(0xFFFFE3E7),
              onErrorContainer: const Color(0xFF641B28),
              surface: _brandBackground,
            ),
        scaffoldBackgroundColor: _brandBackground,
        fontFamily: 'Roboto',
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _brandNavy,
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3E6EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3E6EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brandOrange, width: 1.5),
          ),
        ),
      ),
      home: const _AuthenticationGate(),
    );
  }
}

class _AuthenticationGate extends StatefulWidget {
  const _AuthenticationGate();

  @override
  State<_AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<_AuthenticationGate> {
  final _authApi = AuthApi();
  String? _token;

  Future<void> _login(String username, String password) async {
    final token = await _authApi.login(username, password);
    if (mounted) setState(() => _token = token);
  }

  void _logout() => setState(() => _token = null);

  @override
  Widget build(BuildContext context) {
    final token = _token;
    if (token == null) return LoginScreen(onLogin: _login);

    return LecturerListScreen(
      repository: LecturerApi(token: token),
      onLogout: _logout,
    );
  }
}
