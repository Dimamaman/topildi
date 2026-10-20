import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/theme/no_ripple.dart';
import 'package:topildi/core/theme/topildi_theme.dart';
import 'package:topildi/core/widgets/t_button.dart';
import 'package:topildi/core/widgets/t_chip.dart';

void main() {
  for (final (name, theme) in [('light', topildiLight), ('dark', topildiDark)]) {
    testWidgets('$name: taps leave no ripple and no pressed tint', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme.withoutRipples(),
        home: Scaffold(
          body: Column(
            children: [
              TButton.primary(label: 'Davom etish', onPressed: () {}),
              TChip(label: 'Kalitlar', selected: false, onTap: () {}),
              ListTile(title: const Text('Til'), onTap: () {}),
              TButton.secondary(label: 'Xaritada', onPressed: () {}),
              TButton.danger(label: 'Rad etish', onPressed: () {}),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(overlayColor: Colors.transparent, foregroundColor: Colors.red),
                child: const Text('Shikoyat'),
              ),
              IconButton(tooltip: 'Ulashish', onPressed: () {}, icon: const Icon(Icons.share)),
            ],
          ),
        ),
      ));

      final targets = {
        for (final t in ['Davom etish', 'Kalitlar', 'Til', 'Xaritada', 'Rad etish', 'Shikoyat']) t: find.text(t),
        'Ulashish': find.byTooltip('Ulashish'),
      };
      for (final MapEntry(key: label, value: finder) in targets.entries) {
        final gesture = await tester.startGesture(tester.getCenter(finder));
        await tester.pump(const Duration(milliseconds: 100));
        // Material's ink layer is private; read its debug list dynamically.
        final ink = tester.allRenderObjects
            .where((r) => r.runtimeType.toString() == '_RenderInkFeatures')
            .expand((r) => ((r as dynamic).debugInkFeatures as List<InkFeature>?) ?? const <InkFeature>[]);
        expect(ink.whereType<InkSplash>(), isEmpty, reason: label);
        expect(ink.whereType<InkRipple>(), isEmpty, reason: label);
        expect(ink.whereType<InkSparkle>(), isEmpty, reason: label);
        // Pressed state layer: any highlight must be fully transparent.
        expect(ink.whereType<InkHighlight>().where((h) => h.color.a > 0), isEmpty, reason: '$label pressed tint');
        await gesture.up();
        await tester.pumpAndSettle();
      }
    });
  }
}
