import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart' show Environment;
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';
import 'package:topildi/core/l10n/app_language.dart';
import 'package:topildi/core/l10n/language_cubit.dart';

Future<void> _settle(WidgetTester t) async {
  await t.pumpAndSettle();
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));
  tearDown(() => getIt<LanguageCubit>().set(AppLanguage.uzLatn));

  testWidgets('Til menu switches the whole app in place', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TopildiApp(initialLocation: Routes.profile));
    await _settle(tester);
    await tester.scrollUntilVisible(find.text('Oʻzbekcha'), 200, scrollable: find.byType(Scrollable).first);

    await tester.tap(find.text('Oʻzbekcha'));
    await tester.pumpAndSettle();
    // Each language is named in itself.
    expect(find.text('Ўзбекча'), findsOneWidget);
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    expect(getIt<LanguageCubit>().state, AppLanguage.ru);
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget); // tab bar
    expect(find.text('Русский'), findsOneWidget); // the row's value

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ўзбекча'));
    await tester.pumpAndSettle();
    expect(find.text('Созламалар'), findsOneWidget);
    expect(find.text('Лента'), findsOneWidget);
  });
}
