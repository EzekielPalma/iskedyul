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
          primaryContainer: Color(0xFFE5E5E5),
          onPrimaryContainer: Colors.black,
          secondaryContainer: Color(0xFFE5E5E5),
          onSecondaryContainer: Colors.black,
          tertiary: Color(0xFF444444),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFE5E5E5),
          onTertiaryContainer: Colors.black,
          errorContainer: Color(0xFFE5E5E5),
          onErrorContainer: Colors.black,
          surfaceTint: Colors.transparent,
          outlineVariant: Color(0xFFDDDDDD),
          secondary: Color(0xFF444444),
          onSecondary: Colors.white,
          surface: Color(0xFFFAFAFA),
          onSurface: Colors.black,
          error: Color(0xFF333333),
          onError: Colors.white,
          surfaceContainerHighest: Color(0xFFEEEEEE),
          outline: Color(0xFF777777),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F7F7),
          centerTitle: false,
          toolbarHeight: 72,
          titleTextStyle: TextStyle(
            fontFamily: 'StudentSans',
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFDDDDDD)),
          ),
          contentPadding: EdgeInsets.all(18),
          filled: true,
          fillColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'StudentSans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            side: const BorderSide(color: Color(0xFFD5D5D5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'StudentSans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(
              fontFamily: 'StudentSans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          height: 72,
          indicatorColor: Colors.black,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 21,
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : const Color(0xFF777777),
            ),
          ),
          labelTextStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'StudentSans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFE6E6E6)),
        cardTheme: CardThemeData(
          margin: const EdgeInsets.symmetric(vertical: 5),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE3E3E3)),
          ),
        ),
      ),
      home: state.isReturning ? const DashboardScreen() : const WelcomeScreen(),
    ),
  );
}
