import 'package:bluepos_app/core/appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first launch defaults to approved light reference', () {
    final appearance = AppAppearance();
    expect(appearance.theme, 'light');
    expect(appearance.mode, ThemeMode.light);
  });

  test('legacy server system default does not darken reference screens', () {
    final appearance = AppAppearance();
    appearance.apply({'theme': 'system'}, persist: false, fromServer: true);
    expect(appearance.mode, ThemeMode.light);
  });

  test('explicitly selected dark and system settings are preserved', () {
    final appearance = AppAppearance();
    appearance.explicitThemeChoice = true;
    appearance.apply({'theme': 'dark'}, persist: false, fromServer: true);
    expect(appearance.mode, ThemeMode.dark);
    appearance.apply({'theme': 'system'}, persist: false, fromServer: true);
    expect(appearance.mode, ThemeMode.system);
    appearance.apply({'theme': 'light'}, persist: false, fromServer: true);
    expect(appearance.mode, ThemeMode.light);
  });
}
