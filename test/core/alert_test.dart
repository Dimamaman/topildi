import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/theme/topildi_theme.dart';
import 'package:topildi/core/widgets/t_feedback.dart';

Future<Future<bool> Function()> _host(WidgetTester tester, {double scale = 1, double width = 390}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(theme: topildiLight, home: Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox.expand();
        },
      )));
  return () async => TFeedback.confirm(
    ctx,
    title: 'Hisobdan chiqasizmi?',
    body: 'Eʼlonlaringiz va chatlaringiz saqlanib qoladi.',
    confirmLabel: 'Chiqish',
    cancelLabel: 'Bekor qilish',
    destructive: true,
  );
}

void main() {
  testWidgets('confirm, cancel and tap-outside results; buttons side by side', (tester) async {
    final open = await _host(tester);

    var result = open();
    await tester.pumpAndSettle();
    final cancel = tester.getRect(find.text('Bekor qilish'));
    final ok = tester.getRect(find.text('Chiqish'));
    expect(cancel.center.dy, closeTo(ok.center.dy, 1)); // one row
    expect(cancel.left, lessThan(ok.left)); // cancel on the left
    await tester.tap(find.text('Chiqish'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);

    result = open();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);

    result = open();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('large text stacks the buttons and fits 360', (tester) async {
    final open = await _host(tester, scale: 1.3, width: 360);
    open();
    await tester.pumpAndSettle();
    final cancel = tester.getRect(find.text('Bekor qilish'));
    final ok = tester.getRect(find.text('Chiqish'));
    expect(ok.top, lessThan(cancel.top)); // confirm above cancel
  });
}
