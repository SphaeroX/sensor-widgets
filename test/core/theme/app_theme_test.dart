import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/app.dart';
import 'package:sensor_widgets/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('provides Material 3 light and dark themes', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
    });

    test('uses rounded cards and inputs', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final card = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(
          (card.borderRadius as BorderRadius).topLeft.x,
          greaterThanOrEqualTo(12),
        );
        final input = theme.inputDecorationTheme.border as OutlineInputBorder;
        expect(input.borderRadius.topLeft.x, greaterThanOrEqualTo(8));
      }
    });

    test('text and surface colors keep a readable contrast', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final scheme = theme.colorScheme;
        expect(
          _contrast(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('buttons meet the minimum touch target size', () {
      final style = AppTheme.light().filledButtonTheme.style!;
      final size = style.minimumSize!.resolve({})!;
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('SensorWidgetsApp', () {
    testWidgets('follows the system brightness (dark)', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(const SensorWidgetsApp(home: SizedBox()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SizedBox).first);
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('follows the system brightness (light)', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(const SensorWidgetsApp(home: SizedBox()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SizedBox).first);
      expect(Theme.of(context).brightness, Brightness.light);
    });
  });
}

/// WCAG contrast ratio of two colors.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
