import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';
import 'package:sensor_widgets/presentation/widgets/editor/widget_code_section.dart';

void main() {
  String? clipboardText;
  String? copied;

  setUp(() {
    clipboardText = null;
    copied = null;
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    String generatedCode = '{"type": "single_value"}',
    List<String> Function(String code)? onApply,
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        if (call.method == 'Clipboard.getData') {
          return clipboardText == null ? null : {'text': clipboardText};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: WidgetCodeSection(
              generatedCode: generatedCode,
              onApply: onApply ?? (_) => const [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const Key('widget_code_field')))
      .controller!
      .text;

  testWidgets('has no share button any more', (tester) async {
    await pumpSection(tester);

    expect(find.byKey(const Key('share_widget_prompt_button')), findsNothing);
    expect(find.byIcon(Icons.share_outlined), findsNothing);
  });

  testWidgets('copy code button puts the current code on the clipboard', (
    tester,
  ) async {
    await pumpSection(tester, generatedCode: '{"type": "gauge_bar"}');

    await tester.tap(find.byKey(const Key('copy_widget_code_button')));
    await tester.pump();

    expect(copied, '{"type": "gauge_bar"}');
    expect(find.text('Code kopiert.'), findsOneWidget);
  });

  testWidgets('paste button replaces the code with the clipboard and applies '
      'it', (tester) async {
    final applied = <String>[];
    await pumpSection(
      tester,
      onApply: (code) {
        applied.add(code);
        return const [];
      },
    );
    clipboardText = '{"type": "history_chart"}';

    await tester.tap(find.byKey(const Key('paste_widget_code_button')));
    await tester.pumpAndSettle();

    expect(fieldText(tester), '{"type": "history_chart"}');
    expect(applied, ['{"type": "history_chart"}']);
    expect(find.text('Code übernommen.'), findsOneWidget);
  });

  testWidgets('pasted code with errors stays in the field and shows them', (
    tester,
  ) async {
    await pumpSection(tester, onApply: (_) => const ['Syntaxfehler']);
    clipboardText = 'kaputt';

    await tester.tap(find.byKey(const Key('paste_widget_code_button')));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'kaputt');
    expect(find.byKey(const Key('widget_code_errors')), findsOneWidget);
    expect(find.text('Nicht übernommene Änderungen'), findsOneWidget);
  });

  testWidgets('an empty clipboard changes nothing and says so', (tester) async {
    final applied = <String>[];
    await pumpSection(
      tester,
      generatedCode: '{"a": 1}',
      onApply: (code) {
        applied.add(code);
        return const [];
      },
    );
    clipboardText = '   ';

    await tester.tap(find.byKey(const Key('paste_widget_code_button')));
    await tester.pumpAndSettle();

    expect(fieldText(tester), '{"a": 1}');
    expect(applied, isEmpty);
    expect(find.text('Die Zwischenablage ist leer.'), findsOneWidget);
  });

  testWidgets('prompt, copy and paste buttons fit in one row on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpSection(tester);

    final keys = [
      'copy_widget_prompt_button',
      'copy_widget_code_button',
      'paste_widget_code_button',
    ];
    final tops = {
      for (final k in keys) tester.getTopLeft(find.byKey(Key(k))).dy,
    };
    expect(tops, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
