import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart' show Environment;
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/core/session/session.dart';

Future<void> _open(WidgetTester tester, {Size size = const Size(390, 844), double scale = 1}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(const TopildiApp(initialLocation: Routes.profileSetup));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('empty state, live letter and public name, colour dot, emoji, saved', (tester) async {
    await _open(tester);
    expect(find.text('Ismingiz'), findsOneWidget); // placeholder
    expect(find.text('Familiya qoʻshish'), findsNothing);
    for (final l in ['Suratga olish', 'Galereyadan tanlash', 'Emoji tanlash']) {
      expect(find.bySemanticsLabel(l), findsOneWidget, reason: l);
    }

    await tester.enterText(find.byType(TextField), 'sarbinaz');
    await tester.pump();
    expect(find.text('S'), findsOneWidget);
    expect(find.textContaining('sarbinaz boʻlib', findRichText: true), findsOneWidget);

    // Colour dot toggles the avatar tone; tapping it again goes back to blue.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Avatar rangi: Yashil'));
    await tester.pump();
    expect(tester.getSemantics(find.bySemanticsLabel('Avatar rangi: Yashil')).flagsCollection.isSelected, Tristate.isTrue);

    // Emoji replaces the letter.
    await tester.tap(find.bySemanticsLabel('Emoji tanlash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🦊'));
    await tester.pumpAndSettle();
    expect(find.text('🦊'), findsOneWidget);
    expect(find.text('S'), findsNothing);

    await tester.tap(find.text('Tayyor'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    final session = getIt<Session>();
    expect(session.avatarEmoji, '🦊');
    expect(session.avatarTone, 1);
  });

  for (final (size, scale) in [(const Size(360, 780), 1.0), (const Size(375, 667), 1.0), (const Size(390, 844), 1.3)]) {
    testWidgets('lays out at ${size.width.toInt()}×${size.height.toInt()}, text ×$scale', (tester) async {
      await _open(tester, size: size, scale: scale);
      await tester.enterText(find.byType(TextField), 'Abdurahmonjon');
      await tester.pump();
      // Any RenderFlex overflow would have failed the test by now.
      expect(find.text('Tayyor'), findsOneWidget);
    });
  }
}
