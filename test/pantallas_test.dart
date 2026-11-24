import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recuparty/estado.dart';
import 'package:recuparty/modelos.dart';
import 'package:recuparty/pantallas/invitado_page.dart';
import 'package:recuparty/pantallas/login_page.dart';
import 'package:recuparty/pantallas/organizador_page.dart';
import 'package:recuparty/pantallas/perfil_page.dart';
import 'package:recuparty/pantallas/presupuesto_page.dart';
import 'package:recuparty/pantallas/solicitudes_pages.dart';

// Pruebas de las pantallas nuevas que pidió la revisión.
void main() {
  final hoy = DateTime(2026, 11, 24, 12);
  late AppState app;

  setUp(() => app = AppState(reloj: () => hoy));

  Future<void> abrir(WidgetTester tester, Widget pantalla, {String? como}) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (como != null) {
      app.actual = app.repo.usuarios.firstWhere((u) => u.correo == como);
    }
    await tester.pumpWidget(AppScope(
      estado: app,
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE91E63), brightness: Brightness.dark),
        ),
        home: pantalla,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('login lleva a "¿Olvidaste tu contraseña?"', (tester) async {
    await abrir(tester, const LoginPage());
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperar acceso'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first,
        'invitado@recuparty.com');
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tu código es'), findsOneWidget);
  });

  testWidgets('dashboard del organizador muestra boletos vs. esperados',
      (tester) async {
    await abrir(tester, const DashboardOrganizador(),
        como: 'organizador@recuparty.com');
    expect(find.text('Boletos vendidos vs. invitados esperados'), findsOneWidget);
    expect(find.text('Gastos vs. presupuesto'), findsOneWidget);
    expect(find.text('Presupuesto'), findsOneWidget); // pestaña
  });

  testWidgets('Mis fiestas filtra por estado', (tester) async {
    await abrir(tester, const Scaffold(body: MisFiestas()),
        como: 'organizador@recuparty.com');
    expect(find.text('Posada UTNG'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Publicada'));
    await tester.pumpAndSettle();
    expect(find.text('Posada UTNG'), findsNothing);
    expect(find.text('Fiesta de recuperación'), findsOneWidget);
  });

  testWidgets('compra con un boleto por asistente', (tester) async {
    await abrir(tester, const CompraBoletosPage(partyId: 2),
        como: 'invitado@recuparty.com');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Asistente 2'), 'Toño');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Últimos 4 dígitos de la tarjeta'),
        '4242');
    await tester.tap(find.text('Pagar \$300'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Pagar \$300')));
    await tester.pumpAndSettle();
    final p = app.party(2)!;
    expect(app.boletos.vendidos(p), 4);
  });

  testWidgets('el proveedor cotiza una solicitud pendiente', (tester) async {
    await abrir(tester, const ResponderSolicitudPage(solicitudId: 52),
        como: 'proveedor@recuparty.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Comentarios'), 'Incluye asadores');
    await tester.tap(find.text('Enviar cotización'));
    await tester.pumpAndSettle();
    expect(app.repo.solicitud(52)!.estado, EstadoSolicitud.cotizada);
  });

  testWidgets('presupuesto muestra servicios, otros gastos y recaudado',
      (tester) async {
    await abrir(tester, const PresupuestoPage(partyId: 1),
        como: 'organizador@recuparty.com');
    expect(find.text('Servicios aceptados'), findsOneWidget);
    expect(find.text('Otros gastos'), findsOneWidget);
    expect(find.text('Recaudado por boletos'), findsOneWidget);
    expect(find.text('\$2,160'), findsOneWidget); // 18 boletos × $120
  });

  testWidgets('perfil permite cambiar contraseña y eliminar cuenta',
      (tester) async {
    await abrir(tester, const PerfilPage(), como: 'proveedor@recuparty.com');
    expect(find.text('Datos del negocio'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Eliminar mi cuenta'), findsOneWidget);
  });
}
