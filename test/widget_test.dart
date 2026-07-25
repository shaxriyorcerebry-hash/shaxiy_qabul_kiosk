// Basic smoke test for the Shaxsiy qabul kiosk content screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shaxiy_qabul_kiosk/src/data.dart';
import 'package:shaxiy_qabul_kiosk/src/l10n.dart';
import 'package:shaxiy_qabul_kiosk/src/screens/shaxsiy_screen.dart';

void main() {
  testWidgets('Shaxsiy schedule renders the first official', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ShaxsiyScreen(lang: Lang.uz)),
    ));
    await tester.pumpAndSettle();

    expect(find.text(AppData.shaxsiyQabul.first.name[Lang.uz]!), findsOneWidget);
  });
}
