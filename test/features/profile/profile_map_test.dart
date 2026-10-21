import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/features/listing/presentation/pages/detail_page.dart';

Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Map: type toggles, preview card opens detail', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.map));
    await _settle(tester);

    expect(find.text('Topilgan · 6'), findsOneWidget);
    expect(find.textContaining('Yoʻqolgan · '), findsOneWidget);
    expect(find.text('Batafsil'), findsOneWidget);

    await tester.tap(find.text('Batafsil'));
    await _settle(tester);
    expect(find.byType(DetailPage), findsOneWidget);
  });

  testWidgets('Profile: stats, my listings, theme menu, sign out', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.profile));
    await _settle(tester);

    // Own profile shows the first name only.
    expect(find.text('Dilshod'), findsOneWidget);
    expect(find.text('Dilshod A.'), findsNothing);
    expect(find.text('Mening eʼlonlarim'), findsOneWidget);
    expect(find.text('Qaytarilgan'), findsOneWidget);

    // "Hammasi" opens the full list with the Faol / Qaytarilgan filter.
    await tester.tap(find.text('Hammasi'));
    await _settle(tester);
    await tester.tap(find.textContaining('Qaytarilgan · '));
    await tester.pumpAndSettle();
    expect(find.text('Kalitlar toʻplami'), findsOneWidget);
    await tester.tap(find.byTooltip('Orqaga'));
    await _settle(tester);

    await tester.tap(find.text('Mavzu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qorongʻi'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Mavzu'))).brightness, Brightness.dark);
    await tester.tap(find.text('Mavzu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tizim').last);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Mavzu'))).brightness, Brightness.light);

    // Scroll to the end so Chiqish sits above the floating tab bar.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chiqish'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Chiqish'));
    await _settle(tester);
    expect(find.text('Xush kelibsiz!'), findsOneWidget);
  });
}
