import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'data/study_preferences_store.dart';
import 'home/home_shell.dart';
import 'theme/app_theme.dart';

class DrugReviewApp extends StatefulWidget {
  const DrugReviewApp({super.key});

  @override
  State<DrugReviewApp> createState() => _DrugReviewAppState();
}

class _DrugReviewAppState extends State<DrugReviewApp> {
  final StudyPreferencesStore _preferencesStore = StudyPreferencesStore();
  AppThemePreference _themePreference = AppThemePreference.system;

  void _handleThemePreferenceChanged(AppThemePreference preference) {
    if (_themePreference == preference) return;
    setState(() => _themePreference = preference);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '要学结构式',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themePreference.toThemeMode(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlayStyle = isDark
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: Color(0xFF161F2C),
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: Color(0xFFFFFFFF),
                systemNavigationBarIconBrightness: Brightness.dark,
              );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: HomeShell(
        preferencesStore: _preferencesStore,
        themePreference: _themePreference,
        onThemePreferenceChanged: _handleThemePreferenceChanged,
      ),
    );
  }
}
