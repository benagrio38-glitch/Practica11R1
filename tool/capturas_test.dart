// Genera las capturas del README con las fuentes reales de Material.
//   flutter test tool/capturas_test.dart --update-goldens
// Las imágenes quedan en tool/capturas/ y después se copian a screenshots/.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recuparty/estado.dart';
import 'package:recuparty/pantallas/boletos_vendidos_page.dart';
import 'package:recuparty/pantallas/detalle_fiesta_page.dart';
import 'package:recuparty/pantallas/formulario_party.dart';
import 'package:recuparty/pantallas/formulario_servicio.dart';
import 'package:recuparty/pantallas/invitado_page.dart';
import 'package:recuparty/pantallas/organizador_page.dart';
import 'package:recuparty/pantallas/perfil_page.dart';
import 'package:recuparty/pantallas/presupuesto_page.dart';
import 'package:recuparty/pantallas/proveedor_page.dart';
import 'package:recuparty/pantallas/recuperar_page.dart';
import 'package:recuparty/pantallas/registro_page.dart';
import 'package:recuparty/pantallas/servicios_pages.dart';
import 'package:recuparty/pantallas/solicitudes_pages.dart';
import 'package:recuparty/pantallas/splash_page.dart';

Future<void> _cargarFuentes() async {
  final raiz = Platform.environment['FLUTTER_ROOT'] ??
      r'C:\Users\Usuario\development\flutter';
  final dir = '$raiz/bin/cache/artifacts/material_fonts';
  ByteData leer(String f) =>
      ByteData.view(File('$dir/$f').readAsBytesSync().buffer);
  final roboto = FontLoader('Roboto');
  for (final f in [
    'roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf',
    'roboto-light.ttf', 'roboto-italic.ttf',
  ]) {
    roboto.addFont(Future.value(leer(f)));
  }
  await roboto.load();
  final iconos = FontLoader('MaterialIcons')
    ..addFont(Future.value(leer('materialicons-regular.otf')));
  await iconos.load();
}

void main() {
  final hoy = DateTime(2026, 11, 24, 12);
  setUpAll(_cargarFuentes);

  Future<void> captura(
    WidgetTester tester,
    String nombre,
    Widget pantalla, {
    String? como,
    Future<void> Function(WidgetTester t, AppState app)? antes,
  }) async {
    tester.view.physicalSize = const Size(824, 1830);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final app = AppState(reloj: () => hoy);
    if (como != null) {
      app.actual = app.repo.usuarios.firstWhere((u) => u.correo == como);
    }
    await tester.pumpWidget(AppScope(
      estado: app,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE91E63), brightness: Brightness.dark),
        ),
        home: pantalla,
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
    if (antes != null) await antes(tester, app);
    // Carga las fotos de assets para que salgan en la captura.
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        final img = e.widget as Image;
        await precacheImage(img.image, e);
      }
    });
    await tester.pump(const Duration(seconds: 2));
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('capturas/$nombre.png'));
  }

  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pump();
    await t.tap(f);
    await t.pump(const Duration(seconds: 1));
  }

  const org = 'organizador@recuparty.com';
  const inv = 'invitado@recuparty.com';
  const prov = 'proveedor@recuparty.com';

  testWidgets('01 splash', (t) => captura(t, '01-splash', const SplashPage()));
  testWidgets('03 registro',
      (t) => captura(t, '03-registro', const RegistroPage()));
  testWidgets('18 recuperar', (t) => captura(t, '18-recuperar-acceso',
          const RecuperarPage(), antes: (t, app) async {
        await t.enterText(find.byType(TextFormField).first, inv);
        await tocar(t, find.text('Enviar código'));
      }));
  testWidgets('19 dash org', (t) => captura(
      t, '19-dashboard-organizador', const DashboardOrganizador(),
      como: org));
  testWidgets('20 mis fiestas', (t) => captura(
          t, '20-mis-fiestas', const DashboardOrganizador(), como: org,
          antes: (t, app) async {
        await tocar(t, find.text('Mis fiestas'));
      }));
  testWidgets('21 form fiesta', (t) async {
    await captura(t, '21-formulario-fiesta', const _Diferido(_Pantalla.formParty),
        como: org);
  });
  testWidgets('22 detalle fiesta', (t) => captura(
      t, '22-detalle-fiesta', const DetalleFiestaPage(partyId: 1),
      como: org));
  testWidgets('23 boletos vendidos', (t) => captura(
      t, '23-boletos-vendidos', const BoletosVendidosPage(partyId: 1),
      como: org));
  testWidgets('24 catalogo', (t) => captura(t, '24-catalogo-servicios',
      const Scaffold(body: SafeArea(child: CatalogoServicios())), como: org));
  testWidgets('25 detalle servicio', (t) => captura(
      t, '25-detalle-servicio', const DetalleServicioPage(servicioId: 3),
      como: org));
  testWidgets('26 solicitar', (t) => captura(t, '26-solicitar-servicio',
          const SolicitarServicioPage(servicioId: 4), como: org,
          antes: (t, app) async {
        await tocar(t, find.text('¿Para qué fiesta?'));
        await t.pump(const Duration(seconds: 1));
        final opcion = find.text('Fiesta de recuperación');
        if (opcion.evaluate().isNotEmpty) {
          await t.tap(opcion.last);
          await t.pump(const Duration(seconds: 1));
        }
        await t.enterText(find.widgetWithText(TextFormField, 'Mensaje y detalles'),
            'Taquiza para 70 personas a las 10 pm.');
        await t.pump();
      }));
  testWidgets('27 mis solicitudes', (t) => captura(t, '27-mis-solicitudes',
      const Scaffold(body: SafeArea(child: ListaSolicitudes(comoProveedor: false))),
      como: org));
  testWidgets('28 detalle solicitud', (t) => captura(t,
      '28-detalle-solicitud-cotizada', const DetalleSolicitudPage(solicitudId: 51),
      como: org));
  testWidgets('29 presupuesto', (t) => captura(
      t, '29-presupuesto', const PresupuestoPage(partyId: 1), como: org));
  testWidgets('30 perfil', (t) =>
      captura(t, '30-perfil', const PerfilPage(), como: prov));
  testWidgets('31 dash invitado', (t) => captura(
      t, '31-dashboard-invitado', const DashboardInvitado(), como: inv));
  testWidgets('32 detalle publico', (t) => captura(t,
      '32-detalle-fiesta-publica', const DetalleFiestaPublica(partyId: 2),
      como: inv));
  testWidgets('33 compra', (t) => captura(t, '33-compra-boletos',
          const CompraBoletosPage(partyId: 2), como: inv,
          antes: (t, app) async {
        await tocar(t, find.byIcon(Icons.add));
        await t.enterText(
            find.widgetWithText(TextFormField, 'Asistente 2'), 'Toño Ruiz');
        await t.enterText(
            find.widgetWithText(TextFormField, 'Últimos 4 dígitos de la tarjeta'),
            '4242');
        await t.pump();
      }));
  testWidgets('34 mis boletos', (t) => captura(
          t, '34-mis-boletos', const DashboardInvitado(), como: inv,
          antes: (t, app) async {
        await tocar(t, find.text('Mis boletos').last);
        await tocar(t, find.byType(ExpansionTile).first);
      }));
  testWidgets('35 detalle boleto', (t) async {
    await captura(t, '35-detalle-boleto', const _Diferido(_Pantalla.boleto),
        como: inv);
  });
  testWidgets('36 dash proveedor', (t) => captura(
      t, '36-dashboard-proveedor', const DashboardProveedor(), como: prov));
  testWidgets('37 bandeja', (t) => captura(t, '37-bandeja-proveedor',
          const DashboardProveedor(), como: prov, antes: (t, app) async {
        await tocar(t, find.text('Solicitudes'));
      }));
  testWidgets('38 cotizar', (t) => captura(t, '38-responder-cotizar',
          const ResponderSolicitudPage(solicitudId: 52), como: prov,
          antes: (t, app) async {
        await t.enterText(find.widgetWithText(TextFormField, 'Comentarios'),
            'Incluye asadores, mesas y salvavidas.');
        await t.pump();
      }));
  testWidgets('39 mis servicios', (t) => captura(t, '39-mis-servicios',
          const DashboardProveedor(), como: prov, antes: (t, app) async {
        await tocar(t, find.text('Mis servicios'));
      }));
  testWidgets('40 form servicio', (t) async {
    await captura(t, '40-formulario-servicio',
        const _Diferido(_Pantalla.formServicio),
        como: prov);
  });
}

// Pantallas que necesitan un objeto del estado (fiesta, boleto, servicio).
enum _Pantalla { formParty, boleto, formServicio }

class _Diferido extends StatelessWidget {
  const _Diferido(this.cual);
  final _Pantalla cual;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.leer(context);
    return switch (cual) {
      _Pantalla.formParty => FormularioParty(party: app.party(1)),
      _Pantalla.boleto => DetalleBoletoPage(boleto: app.misBoletos.first),
      _Pantalla.formServicio => FormularioServicio(servicio: app.servicio(3)),
    };
  }
}
