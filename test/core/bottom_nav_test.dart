import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/theme/topildi_theme.dart';
import 'package:topildi/core/widgets/glass_surface.dart';
import 'package:topildi/core/widgets/t_bottom_nav.dart';

Widget _host(TargetPlatform platform, {required void Function(int) onSelect, required VoidCallback onAdd}) => MaterialApp(
      theme: topildiLight.copyWith(platform: platform),
      home: Scaffold(
        extendBody: true,
        bottomNavigationBar: TBottomNav(currentIndex: 0, unreadChats: 2, onSelect: onSelect, onAdd: onAdd),
      ),
    );

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('${platform.name}: four glass tabs, separate add button, badge', (tester) async {
      var selected = -1;
      var added = false;
      await tester.pumpWidget(_host(platform, onSelect: (i) => selected = i, onAdd: () => added = true));

      for (final label in ['Lenta', 'Xarita', 'Chatlar', 'Profil']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Qoʻshish'), findsNothing);
      // Tab bar capsule + "+" circle.
      expect(find.byType(GlassSurface), findsNWidgets(2));
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text('Chatlar'));
      expect(selected, 2);
      await tester.tap(find.bySemanticsLabel('Eʼlon berish'));
      expect(added, isTrue);
      expect(find.bySemanticsLabel('Chatlar, 2 ta yangi'), findsOneWidget);
    });
  }

  testWidgets('bar is 62 tall and floats 24 above the edge, clear of the home indicator', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
        child: _host(TargetPlatform.iOS, onSelect: (_) {}, onAdd: () {}),
      ),
    );
    expect(tester.getSize(find.byType(TBottomNav)).height, 62 + 24);
    expect(tester.getSize(find.bySemanticsLabel('Eʼlon berish')), const Size(62, 62));
  });
}
