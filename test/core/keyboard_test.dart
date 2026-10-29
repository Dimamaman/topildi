import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart';
import 'package:topildi/app/app.dart';
import 'package:topildi/app/routes.dart';
import 'package:topildi/core/di/injection.dart';

void main() {
  setUpAll(() => configureDependencies(environment: Environment.test));

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TopildiApp(initialLocation: Routes.chat('c_sardor')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  bool focused(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

  testWidgets('a tap outside the field closes the keyboard', (tester) async {
    await open(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focused(tester), isTrue);

    await tester.tap(find.text('Kecha'));
    await tester.pump();
    expect(focused(tester), isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('dragging the messages closes the keyboard', (tester) async {
    await open(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focused(tester), isTrue);

    // iOS: the list bounces, so it drags even when the chat is short.
    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pump();
    expect(focused(tester), isFalse);
    await tester.pumpAndSettle();
  },variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
