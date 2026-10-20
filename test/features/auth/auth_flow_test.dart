import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/core/session/session.dart';

Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Splash → onboarding → sign in → SMS → profile → feed', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TopildiApp());
    expect(find.text('Topildi'), findsOneWidget);
    await _settle(tester);

    expect(find.text('Nimadir topdingizmi?'), findsOneWidget);
    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    expect(find.text('Nimadir yoʻqotdingizmi?'), findsOneWidget);
    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boshlash'));
    await tester.pumpAndSettle();

    expect(find.text('Xush kelibsiz!'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '90123');
    await tester.tap(find.text('Kodni olish'));
    await tester.pump();
    expect(find.textContaining('Raqam toʻliq emas'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '901234567');
    expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, '90 123 45 67');
    await tester.tap(find.text('Kodni olish'));
    await _settle(tester);

    expect(find.textContaining('+998 90 *** ** 67', findRichText: true), findsOneWidget);
    expect(find.textContaining('Kodni qayta yuborish', findRichText: true), findsOneWidget);
    await tester.enterText(find.byType(TextField), '000000');
    await _settle(tester);
    expect(find.text('Kod notoʻgʻri. Qayta tekshiring'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '482713');
    await _settle(tester);

    expect(find.text('Tanishib olaylik'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Malika');
    await tester.enterText(find.byType(TextField).at(1), 'Karimova');
    await tester.pump();
    expect(find.text('Boshqalar faqat bosh harfni koʻradi: Malika K.'), findsOneWidget);
    await tester.tap(find.text('Tayyor'));
    await _settle(tester);

    expect(find.text('Lenta'), findsOneWidget);
    final session = getIt<Session>();
    expect(session.signedIn, isTrue);
    expect(session.displayName, 'Malika K.');
  });
}
