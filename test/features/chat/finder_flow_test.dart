import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/features/listing/presentation/widgets/returned_strip.dart';

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
    expect(find.text('Egasi'), findsOneWidget);
    expect(find.text('Faol chat'), findsOneWidget);
    expect(find.text('Javob yashirin belgiga mos keldi · Chat ochildi'), findsOneWidget);
    // The safety tip is no longer shown in the chat.
    expect(find.textContaining('Gavjum joyda'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Soat 18:00 da metro yonida');
    await tester.tap(find.bySemanticsLabel('Yuborish'));
    await _settle(tester);
    expect(find.textContaining('Soat 18:00 da metro yonida'), findsOneWidget);

    // Marking it returned lives in the "…" menu.
    await tester.tap(find.bySemanticsLabel('Koʻproq'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buyum qaytarildi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ha, qaytarildi'));
    await _settle(tester);

    expect(find.text('Buyum egasiga'), findsOneWidget);
    expect(find.text('qaytdi!'), findsOneWidget);
    expect(find.text('Mehribon qoʻshni'), findsNothing);
    expect(find.text('Siz endi 5 ta buyumni egasiga qaytardingiz', findRichText: true), findsOneWidget);
    expect(find.bySemanticsLabel('Doʻstlarga ulashish'), findsOneWidget);
    expect(find.text('Malika K. yozdi'), findsOneWidget);

    await tester.ensureVisible(find.text('Lentaga qaytish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lentaga qaytish'));
    await _settle(tester);
    // Back on the feed. The returned listing has left the grid and now
    // appears once more, in the proof strip above it.
    expect(find.text('Kalitlar toʻplami, 3 dona'), findsOneWidget);
    expect(find.text('Qora charm hamyon'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ReturnedStrip), matching: find.text('Qora charm hamyon')),
      findsOneWidget,
    );
  });
}
