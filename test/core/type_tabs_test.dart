import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/theme/topildi_theme.dart';
import 'package:topildi/core/widgets/t_chip.dart';

void main() {
  Future<List<bool>> pump(WidgetTester tester, {bool initial = true}) async {
    final changes = <bool>[];
    var value = initial;
    await tester.pumpWidget(MaterialApp(
      theme: topildiLight,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setState) => TTypeTabs(
              isFound: value,
              onChanged: (v) {
                changes.add(v);
                setState(() => value = v);
              },
            ),
          ),
        ),
      ),
    ));
    return changes;
  }

  testWidgets('tap switches segment and the thumb slides', (tester) async {
    final changes = await pump(tester);
    Alignment thumb() => tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment as Alignment;
    expect(thumb(), Alignment.centerLeft);

    await tester.tap(find.text('Yoʻqolgan'));
    await tester.pumpAndSettle();
    expect(changes, [false]);
    expect(thumb(), Alignment.centerRight);
  });

  testWidgets('dragging across the track switches', (tester) async {
    final changes = await pump(tester);
    await tester.drag(find.text('Topilgan'), const Offset(250, 0));
    await tester.pumpAndSettle();
    expect(changes.last, isFalse);
  });

  testWidgets('both labels stay visible (not colour-only) and meet tap size', (tester) async {
    await pump(tester);
    expect(find.text('Topilgan'), findsOneWidget);
    expect(find.text('Yoʻqolgan'), findsOneWidget);
    expect(tester.getSize(find.byType(TTypeTabs)).height, greaterThanOrEqualTo(44));
  });
}
