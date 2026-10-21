import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Create flow: type → details → location → review → posted → detail', (tester) async {
    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.home));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.bySemanticsLabel('Eʼlon berish'));
    await tester.pumpAndSettle();
    expect(find.text('Nima boʻldi?'), findsOneWidget);

    // Photo via the (fake) picker: camera/gallery sheet → tile added.
    await tester.tap(find.text('Qoʻshish').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galereya'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 6'), findsOneWidget);
    expect(find.text('Asosiy'), findsOneWidget);

    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();

    // Validation blocks an empty step 2.
    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    expect(find.text('Kategoriyani tanlang'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Kumush uzuk');
    await tester.tap(find.text('Tanlang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boshqa').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Ichki tomonida sana yozilgan');
    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    expect(find.text('Qayerda va qachon?'), findsOneWidget);

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
    // Hidden detail never appears on the public detail page.
    expect(find.text('Ichki tomonida sana yozilgan'), findsNothing);
    // Author sees claims (none yet), not "Bu meniki".
    expect(find.text('Soʻrovlar yoʻq'), findsOneWidget);
    expect(find.text('Bu meniki'), findsNothing);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
