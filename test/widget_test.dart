import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recuparty/main.dart';

void main() {
  testWidgets('El splash pasa al login', (WidgetTester tester) async {
    await tester.pumpWidget(const RecuPartyApp());

    // Primero se ve el splash.
    expect(find.text('RecuParty R1'), findsOneWidget);
    expect(find.text('Organiza tu fiesta'), findsOneWidget);

    // Pasan los 3 segundos del splash y aparece el login.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Iniciar sesión'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
