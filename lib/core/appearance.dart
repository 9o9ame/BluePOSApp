import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAppearance extends ChangeNotifier {
  String theme = 'system';
  String skin = 'classic';
  String font = 'skin-default';
  String primaryTheme = 'blue';
  String density = 'comfortable';
  String radius = 'medium';
  String shadow = 'soft';
  bool animations = true;
  bool _initialized = false;

  static const palette = <String, Color>{
    'indigo': Color(0xFF4F46E5),
    'blue': Color(0xFF0757D9),
    'emerald': Color(0xFF059669),
    'teal': Color(0xFF0F8C92),
    'purple': Color(0xFF7C3AED),
    'slate': Color(0xFF475569),
  };

  Color get accent => palette[primaryTheme] ?? palette['blue']!;
  double get corner => switch (radius) { 'small' => 9, 'large' => 25, _ => 17 };
  double get spacing => density == 'compact' ? 10 : 15;
  ThemeMode get mode => switch (theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  String? get fontFamily => switch (font) {
    'arial' => 'Arial',
    'tahoma' => 'Tahoma',
    'segoe-ui' => 'Segoe UI',
    _ => null,
  };

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'skin': skin,
        'font': font,
        'primaryTheme': primaryTheme,
        'density': density,
        'radius': radius,
        'shadow': shadow,
        'animations': animations,
      };

  Future<void> load() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    apply({
      'theme': prefs.getString('bp_theme'),
      'skin': prefs.getString('bp_skin'),
      'font': prefs.getString('bp_font'),
      'primaryTheme': prefs.getString('bp_primary'),
      'density': prefs.getString('bp_density'),
      'radius': prefs.getString('bp_radius'),
      'shadow': prefs.getString('bp_shadow'),
      'animations': prefs.getBool('bp_animations'),
    }, persist: false);
    _initialized = true;
  }

  void apply(Map<String, dynamic> values, {bool persist = true}) {
    String choose(String key, String current, List<String> valid) {
      final next = values[key];
      return next is String && valid.contains(next) ? next : current;
    }
    theme = choose('theme', theme, ['system', 'light', 'dark']);
    skin = choose('skin', skin, ['classic', 'hybrid', 'advanced']);
    font = choose('font', font,
        ['skin-default', 'inter', 'roboto-condensed', 'segoe-ui', 'tahoma', 'arial']);
    primaryTheme = choose('primaryTheme', primaryTheme,
        ['indigo', 'blue', 'emerald', 'teal', 'purple', 'slate']);
    density = choose('density', density, ['compact', 'comfortable']);
    radius = choose('radius', radius, ['small', 'medium', 'large']);
    shadow = choose('shadow', shadow, ['none', 'soft', 'normal', '3d']);
    if (values['animations'] is bool) animations = values['animations'] as bool;
    notifyListeners();
    if (persist) _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('bp_theme', theme),
      prefs.setString('bp_skin', skin),
      prefs.setString('bp_font', font),
      prefs.setString('bp_primary', primaryTheme),
      prefs.setString('bp_density', density),
      prefs.setString('bp_radius', radius),
      prefs.setString('bp_shadow', shadow),
      prefs.setBool('bp_animations', animations),
    ]);
  }

  ThemeData data(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness,
        surface: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F8FE));
    final r = BorderRadius.circular(corner);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: fontFamily,
      visualDensity: density == 'compact' ? VisualDensity.compact : VisualDensity.standard,
      appBarTheme: AppBarTheme(backgroundColor: colorScheme.surface, elevation: 0,
          centerTitle: false, titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
              color: colorScheme.onSurface)),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF18233A) : Colors.white,
        elevation: shadow == 'none' ? 0 : shadow == '3d' ? 6 : shadow == 'normal' ? 3 : 1,
        shadowColor: accent.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: r),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1C2943) : Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: density == 'compact' ? 11 : 16),
        border: OutlineInputBorder(borderRadius: r, borderSide: BorderSide(color: colorScheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: r,
            borderSide: BorderSide(color: colorScheme.outlineVariant)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: accent, foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: r),
      )),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: accent, foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: r),
      )),
    );
  }
}
