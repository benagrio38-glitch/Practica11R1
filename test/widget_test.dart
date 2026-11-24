import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recuparty/main.dart';

void main() {
  testWidgets('Prueba 1: el splash muestra el nombre de la app',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RecuPartyApp());

    expect(find.text('RecuParty R1'), findsOneWidget);
    expect(find.text('Organiza tu fiesta'), findsOneWidget);

    // Deja avanzar el temporizador del splash para cerrar la prueba limpia.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Prueba 2: el splash pasa al login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RecuPartyApp());

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Inicia sesión para entrar'), findsOneWidget);
  });

  testWidgets('Prueba 3: el login tiene correo y contraseña',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RecuPartyApp());

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
