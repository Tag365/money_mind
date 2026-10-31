import 'package:flutter/material.dart';
import 'package:money_mind/app/app_lock.dart';
import 'package:money_mind/app/tab_navigation.dart';
import 'package:money_mind/features/settings/app_settings.dart';

void main() {
  runApp(const MoneyMind());
}

class MoneyMind extends StatefulWidget {
  const MoneyMind({super.key});

  @override
  State<MoneyMind> createState() => _MoneyMindState();
}

class _MoneyMindState extends State<MoneyMind> {
  late final Stream<ThemeMode> _themeMode = watchThemeMode();

  static ThemeData _theme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: Colors.white10,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
      brightness: brightness,
    );
    // Filled fields without outline; a primary border marks focus.
    final inputs = InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return ThemeData(
      colorScheme: colors,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: inputs,
      // DropdownMenu ignores inputDecorationTheme.
      dropdownMenuTheme: DropdownMenuThemeData(inputDecorationTheme: inputs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _themeMode,
      builder: (context, snapshot) => MaterialApp(
        title: 'Money Mind',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: snapshot.data ?? ThemeMode.system,
        // Above the Navigator, so the lock also covers pushed pages.
        builder: (context, child) => AppLock(child: child!),
        home: TabNavigation(),
      ),
    );
  }
}
