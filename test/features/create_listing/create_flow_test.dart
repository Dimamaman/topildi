import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';

/// Writes the hidden detail through its sheet.
Future<void> _hiddenDetail(WidgetTester tester, String text) async {
  await tester.tap(find.text('Yashirin belgi'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, text);
  await tester.tap(find.text('Saqlash').last);
  await tester.pumpAndSettle();
}

/// The design's 390×844 phone.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Create flow: type → details → location → review → posted → detail', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.bySemanticsLabel('Eʼlon berish'));
    await tester.pumpAndSettle();
    expect(find.text('Nima boʻldi?'), findsOneWidget);
    expect(find.text('EʼLONINGIZ SHUNDAY KOʻRINADI'), findsOneWidget);

    // Photo straight from the (fake) gallery.
    await tester.tap(find.text('Galereya'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 6'), findsOneWidget);
    expect(find.text('6 tagacha rasm'), findsNothing);

    // Something was entered: closing asks first.
    await tester.tap(find.byTooltip('Yopish'));
    await tester.pumpAndSettle();
    expect(find.text('Chiqasizmi?'), findsOneWidget);
    expect(find.text('Eʼlon saqlanmaydi.'), findsOneWidget);
    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    // Step 2 opens without errors; they show only after "Keyingi".
    expect(find.text('Kategoriyani tanlang'), findsNothing);
    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    expect(find.text('Kategoriyani tanlang'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Kumush uzuk');
    await tester.pump();
    // The preview card follows the title as it is typed.
    expect(find.text('Kumush uzuk'), findsNWidgets(2));
    await tester.tap(find.text('Telefonlar'));
    await tester.pumpAndSettle();
    expect(find.text('Kategoriyani tanlang'), findsNothing);
    await _hiddenDetail(tester, 'Ichki tomonida sana yozilgan');
    expect(find.text('✓ Qoʻshildi'), findsOneWidget);
    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    expect(find.text('Qayerda va qachon?'), findsOneWidget);
    expect(find.text('Qachon topdingiz?'), findsOneWidget);

    // The district is required.
    await tester.tap(find.text('Koʻrib chiqish'));
    await tester.pumpAndSettle();
    expect(find.text('Tumanni tanlang'), findsOneWidget);

    // "Aniqlash": the (fake) position is near Chilonzor.
    await tester.tap(find.text('Aniqlash'));
    await tester.pumpAndSettle();
    expect(find.text('Tumanni tanlang'), findsNothing);
    expect(find.text('Telefonlar · Chilonzor'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Metro yonida');

    await tester.tap(find.text('Koʻrib chiqish'));
    await tester.pumpAndSettle();
    // Hidden detail is masked until the eye toggle is pressed.
    expect(find.text('Ichki tomonida sana yozilgan'), findsNothing);
    await tester.tap(find.byTooltip('Koʻrsatish'));
    await tester.pump();
    expect(find.text('Ichki tomonida sana yozilgan'), findsOneWidget);

    await tester.tap(find.text('Eʼlon qilish'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Eʼlon joylandi!'), findsOneWidget);

    await tester.tap(find.text('Eʼlonni koʻrish'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    // Claims count loads after the listing.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Kumush uzuk'), findsOneWidget);
    // The landmark is on the listing page.
    expect(find.textContaining('Metro yonida'), findsWidgets);
    // Hidden detail never appears on the public detail page.
    expect(find.text('Ichki tomonida sana yozilgan'), findsNothing);
    // Author sees claims (none yet), not "Bu meniki".
    expect(find.text('Soʻrovlar yoʻq'), findsOneWidget);
    expect(find.text('Bu meniki'), findsNothing);
  });

  testWidgets('Steps slide in one screen; back returns a step, edit opens one step', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.create));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);

    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Kumush uzuk');

    // Back goes to step 1 within the same screen, not out of the flow.
    await tester.tap(find.byTooltip('Orqaga'));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Nima boʻldi?'), findsOneWidget);

    // Step 2 kept what was typed.
    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    expect(find.text('Kumush uzuk'), findsWidgets);

    await tester.tap(find.text('Hujjatlar'));
    await tester.pumpAndSettle();
    await _hiddenDetail(tester, 'Ichki tomonida sana yozilgan');
    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    await tester.tap(find.text('Bektemir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koʻrib chiqish'));
    await tester.pumpAndSettle();

    // "Oʻzgartirish" on the title row: only step 2, saved straight back to Review.
    await tester.tap(find.text('Oʻzgartirish').at(1));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Oltin uzuk');
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Oltin uzuk'), findsWidgets);
    expect(find.textContaining('Kumush uzuk'), findsNothing);
    expect(find.text('Eʼlon qilish'), findsOneWidget);
  });
}
