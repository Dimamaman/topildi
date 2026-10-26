import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/features/auth/presentation/cubit/telegram_wait_cubit.dart';
import 'package:topildi/core/session/session.dart';

Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Splash → onboarding → sign in → Telegram → profile → feed', (tester) async {
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
    await tester.tap(find.text('Telegram orqali kirish'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Waits while the number is shared in Telegram; the mock confirms on the second check.
    expect(find.text('Telegramda tasdiqlang'), findsOneWidget);
    expect(find.text('Tasdiqlash kutilmoqda'), findsOneWidget);
    await tester.pump(TelegramWaitCubit.every);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Telegramda tasdiqlang'), findsOneWidget);
    await tester.pump(TelegramWaitCubit.every);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Tasdiqlandi!'), findsOneWidget);
    await _settle(tester);

    expect(find.text('Oxirgi qadam'), findsOneWidget);
    expect(find.text('Salom,'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Malika');
    await tester.pump();
    expect(find.text('M'), findsOneWidget); // avatar letter follows the name
    // No surname step: others see the name alone.
    expect(find.text('Familiya qoʻshish'), findsNothing);
    expect(find.textContaining('Malika boʻlib', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Tayyor'));
    await _settle(tester);

    expect(find.text('Hammasi'), findsOneWidget);
    final session = getIt<Session>();
    expect(session.signedIn, isTrue);
    expect(session.displayName, 'Malika');
  });
}
