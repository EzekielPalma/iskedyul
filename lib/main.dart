import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'data/storage.dart';
import 'screens/screens.dart';

void main() => runApp(ISkedyulApp(state: AppState(storage: createStorage())));

class ISkedyulApp extends StatelessWidget {
  const ISkedyulApp({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: MaterialApp(
      title: 'iSkedyul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'StudentSans',
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Color(0xFF444444),
          onSecondary: Colors.white,
          surface: Color(0xFFFAFAFA),
          onSurface: Colors.black,
          error: Color(0xFF333333),
          onError: Colors.white,
          surfaceContainerHighest: Color(0xFFEEEEEE),
          outline: Color(0xFF777777),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFD0D0D0)),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    ),
  );
}
