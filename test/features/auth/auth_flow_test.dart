import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/core/links/link_launcher.dart';
import 'package:topildi/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:topildi/core/session/session.dart';
import 'package:topildi/core/widgets/topildi_logo.dart';

Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  testWidgets('Splash → onboarding → sign in → Telegram → feed', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TopildiApp());
    expect(find.byType(TopildiWordmark), findsOneWidget);
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
    expect(find.text('Google orqali davom etish'), findsNothing);
    await tester.tap(find.text('Telegram orqali kirish'));
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('Telegram ochilmoqda…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 700));

    // The tiles have flown in and the bot was opened with the session link.
    final links = getIt<LinkLauncher>() as RecordingLinkLauncher;
    expect(links.opened.single.toString(), startsWith('https://t.me/'));

    // Back from Telegram before sharing the number: the tiles return.
    final binding = tester.binding;
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      binding.handleAppLifecycleStateChanged(s);
    }
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Telegram orqali kirish'), findsOneWidget);

    // The confirmation arrives a moment later and still signs in.
    await tester.pump(SignInCubit.every);
    await _settle(tester);

    // Named after the Telegram account: no profile step.
    expect(find.text('Oxirgi qadam'), findsNothing);
    expect(find.text('Hammasi'), findsOneWidget);
    final session = getIt<Session>();
    expect(session.signedIn, isTrue);
    expect(session.displayName, 'Malika');
  });
}
