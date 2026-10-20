import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/theme/topildi_theme.dart';
import 'package:topildi/core/widgets/t_bottom_nav.dart';

Widget _host(TargetPlatform platform, {required void Function(int) onSelect, required VoidCallback onAdd}) => MaterialApp(
      theme: topildiLight.copyWith(platform: platform),
      home: Scaffold(
        bottomNavigationBar: TBottomNav(currentIndex: 0, unreadChats: 2, onSelect: onSelect, onAdd: onAdd),
      ),
    );

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('${platform.name}: tabs, add action and badge', (tester) async {
      var selected = -1;
      var added = false;
      await tester.pumpWidget(_host(platform, onSelect: (i) => selected = i, onAdd: () => added = true));

      final isIos = platform == TargetPlatform.iOS;
      expect(find.byType(CupertinoButton), isIos ? findsNWidgets(5) : findsNothing);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text('Chatlar'));
      expect(selected, 3);
      await tester.tap(find.text('Qoʻshish'));
      expect(added, isTrue);
      expect(find.bySemanticsLabel('Chatlar, 2 ta yangi'), findsOneWidget);
    });
  }

  testWidgets('iOS bar is 50 pt tall plus the home-indicator inset', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
        child: _host(TargetPlatform.iOS, onSelect: (_) {}, onAdd: () {}),
      ),
    );
    final bar = tester.getSize(find.byType(TBottomNav));
    expect(bar.height, 84);
  });
}
