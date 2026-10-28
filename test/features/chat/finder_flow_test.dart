import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';

/// Lets route transitions finish, then the mock latency elapse.
Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Finder: claims → accept → chat → returned → success', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    await _settle(tester);

    await tester.tap(find.text('Qora charm hamyon'));
    await _settle(tester);
    expect(find.text('Mening eʼlonim'), findsOneWidget);
    expect(find.text('2 ta yangi soʻrov'), findsOneWidget);
    expect(find.text('Ikki kishi bu buyum ularniki ekanini aytmoqda.'), findsOneWidget);
    await tester.tap(find.text('Soʻrovlarni koʻrish · 2'));
    await _settle(tester);

    // Two requests page sideways; Malika's (newest) first.
    expect(find.text('Soʻrovlar · 1 / 2'), findsOneWidget);
    expect(find.text('SIZ YOZGAN BELGI'), findsWidgets);
    expect(find.text('Ichida koʻk rangli bank kartasi va 2 ta suratli chipta bor'), findsWidgets);
    expect(find.text('MALIKA K. JAVOBI'), findsOneWidget);

    // "Mos emas" for Anvar: no dialog, sent after the 5 s undo window.
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Soʻrovlar · 2 / 2'), findsOneWidget);
    expect(find.text('ANVAR T. JAVOBI'), findsOneWidget);
    await tester.tap(find.text('Mos emas'));
    await tester.pump();
    expect(find.text('Rad etildi'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await _settle(tester);
    expect(find.text('Rad etildi'), findsOneWidget);

    // Accept Malika → confirm → chat opens.
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qabul qilish'));
    await tester.pumpAndSettle();
    expect(find.text('Malika K.ni qabul qilasizmi?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Qabul qilish').last);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _settle(tester);
    expect(find.text('Egaligi tasdiqlangan'), findsOneWidget);
    expect(find.text('Javob yashirin belgiga mos keldi. Chat ochildi.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Soat 18:00 da metro yonida');
    await tester.tap(find.byTooltip('Yuborish'));
    await _settle(tester);
    expect(find.text('Soat 18:00 da metro yonida'), findsOneWidget);

    await tester.tap(find.text('Qaytarildi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ha, qaytarildi'));
    await _settle(tester);

    expect(find.text('Buyum egasiga qaytdi!'), findsOneWidget);
    expect(find.text('Mehribon qoʻshni'), findsOneWidget);
    expect(find.text('Siz 5 ta buyumni egasiga qaytardingiz'), findsOneWidget);
    expect(find.text('Malika K. yozdi'), findsOneWidget);

    await tester.ensureVisible(find.text('Lentaga qaytish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lentaga qaytish'));
    await _settle(tester);
    // Back on the feed, and the returned listing has left it.
    expect(find.text('Kalitlar toʻplami, 3 dona'), findsOneWidget);
    expect(find.text('Qora charm hamyon'), findsNothing);
  });
}
