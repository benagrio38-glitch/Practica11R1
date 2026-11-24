import 'package:flutter_test/flutter_test.dart';
import 'package:recuparty/estado.dart';
import 'package:recuparty/modelos.dart';
import 'package:recuparty/servicios_app.dart';

// Pruebas de las correcciones al modelo y de las reglas de los servicios.
void main() {
  final hoy = DateTime(2026, 11, 24, 12);
  late AppState app;
  late Usuario org, inv, prov;

  setUp(() {
    app = AppState(reloj: () => hoy);
    Usuario usuario(String correo) =>
        app.repo.usuarios.firstWhere((u) => u.correo == correo);
    org = usuario('organizador@recuparty.com');
    inv = usuario('invitado@recuparty.com');
    prov = usuario('proveedor@recuparty.com');
  });

  group('Dinero exacto', () {
    test('convierte texto a centavos sin errores de redondeo', () {
      expect(Dinero.deTexto('0.1')!.centavos, 10);
      expect(Dinero.deTexto('1250.5')!.centavos, 125050);
      expect(Dinero.deTexto('abc'), isNull);
      expect(Dinero.deTexto('1.999'), isNull);
      expect((const Dinero(10) + const Dinero(20)).centavos, 30);
      expect(const Dinero(125050).texto, '\$1,250.50');
    });
  });

  group('Cuentas', () {
    test('la contraseña se guarda como hash, nunca legible', () {
      final u = app.cuentas.registrar(
          nombre: 'Nuevo', correo: 'nuevo@x.com', clave: 'secreta1', rol: Rol.invitado);
      expect(u.passwordHash, isNot(contains('secreta1')));
      expect(u.salt, isNotEmpty);
      expect(app.cuentas.iniciarSesion('nuevo@x.com', 'secreta1').idUsuario,
          u.idUsuario);
      expect(() => app.cuentas.iniciarSesion('nuevo@x.com', 'otra123'),
          throwsA(isA<ErrorRegla>()));
    });

    test('recuperar acceso con código cambia la contraseña', () {
      final codigo = app.cuentas.solicitarRecuperacion('invitado@recuparty.com');
      app.cuentas.restablecerClave('invitado@recuparty.com', codigo, 'nueva123');
      expect(app.cuentas.iniciarSesion('invitado@recuparty.com', 'nueva123'),
          isNotNull);
      expect(
          () => app.cuentas
              .restablecerClave('invitado@recuparty.com', codigo, 'otra123'),
          throwsA(isA<ErrorRegla>()));
    });

    test('una cuenta con eliminación solicitada ya no entra', () {
      app.cuentas.solicitarEliminacion(inv, '123456');
      expect(() => app.cuentas.iniciarSesion('invitado@recuparty.com', '123456'),
          throwsA(isA<ErrorRegla>()));
      // Sus boletos se conservan como historial.
      expect(app.repo.boletos.where((b) => b.compradorId == inv.idUsuario),
          isNotEmpty);
    });
  });

  group('Fiestas y boletos', () {
    test('los vendidos se calculan desde los boletos válidos', () {
      final p = app.party(1)!;
      expect(app.boletos.vendidos(p), 18);
      expect(app.boletos.disponibles(p), p.aforoMaximo - 18);
      expect(app.boletos.recaudado(p), const Dinero(18 * 12000));
    });

    test('un boleto por asistente, con código único', () {
      final p = app.party(2)!;
      final c = app.boletos.comprar(inv, p, ['Pepe', 'Toño', 'Luz'],
          terminacionTarjeta: '4242');
      final bs = app.boletos.boletosDeCompra(c);
      expect(bs.length, 3);
      expect(bs.map((b) => b.codigoAcceso).toSet().length, 3);
      expect(c.total, p.precioBoleto.por(3));
      // El pago solo guarda la terminación.
      final pago = app.repo.pagos.firstWhere((x) => x.compraId == c.idCompra);
      expect(pago.metodo, 'Tarjeta terminación 4242');
    });

    test('no se vende más que el aforo', () {
      final p = app.party(2)!;
      final quedan = app.boletos.disponibles(p);
      expect(
          () => app.boletos.comprar(
              inv, p, List.filled(quedan + 1, 'X'), terminacionTarjeta: '1111'),
          throwsA(isA<ErrorRegla>()));
    });

    test('solo el dueño edita su fiesta y el aforo no baja de lo vendido', () {
      final p = app.party(1)!;
      final datos = DatosParty(
        nombre: p.nombre,
        descripcion: p.descripcion,
        inicio: p.fechaHoraInicio,
        fin: p.fechaHoraFin,
        lugar: p.lugar,
        invitadosEsperados: 10,
        aforoMaximo: 10,
        presupuesto: p.presupuesto,
        precioBoleto: p.precioBoleto,
        edadMinima: 18,
      );
      expect(() => app.fiestas.editar(inv, p, datos, 18),
          throwsA(isA<ErrorRegla>()));
      expect(() => app.fiestas.editar(org, p, datos, 18),
          throwsA(isA<ErrorRegla>()));
    });

    test('una fiesta nueva queda en borrador y se publica', () {
      final p = app.fiestas.crear(
          org,
          DatosParty(
            nombre: 'Prueba',
            descripcion: '',
            inicio: hoy.add(const Duration(days: 5)),
            fin: hoy.add(const Duration(days: 5, hours: 4)),
            lugar: const Lugar(nombre: 'Casa', direccion: 'Calle 1', ciudad: 'DH'),
            invitadosEsperados: 20,
            aforoMaximo: 25,
            presupuesto: const Dinero(100000),
            precioBoleto: const Dinero(5000),
            edadMinima: 18,
          ));
      expect(p.estado, EstadoParty.borrador);
      expect(app.fiestas.publicas().contains(p), isFalse);
      app.fiestas.publicar(org, p);
      expect(app.fiestas.publicas().contains(p), isTrue);
    });

    test('cancelar la fiesta cancela boletos y reembolsa pagos', () {
      final p = app.party(1)!;
      app.fiestas.cancelar(org, p);
      expect(app.boletos.vendidos(p), 0);
      final pagos = app.repo.pagos.where((x) =>
          app.repo.compra(x.compraId)!.partyId == p.idParty);
      expect(pagos.every((x) => x.estado == EstadoPago.reembolsado), isTrue);
    });

    test('el mismo boleto no entra dos veces', () {
      final b = app.repo.boletos.firstWhere((b) => b.partyId == 1);
      final p = app.party(1)!;
      app.boletos.validarEntrada(org, p, b.codigoAcceso);
      expect(() => app.boletos.validarEntrada(org, p, b.codigoAcceso),
          throwsA(isA<ErrorRegla>()));
    });
  });

  group('Servicios y cotizaciones', () {
    test('desactivar es baja lógica y lo quita del catálogo', () {
      final s = app.servicio(1)!;
      app.catalogo.cambiarActivo(prov, s, false);
      expect(app.repo.servicios.contains(s), isTrue);
      expect(app.catalogo.catalogo().contains(s), isFalse);
    });

    test('flujo pendiente -> cotizada -> aceptada y se suma al presupuesto', () {
      final p = app.party(2)!;
      final s = app.servicio(3)!;
      final sol = app.solicitudes.solicitar(org, p, s,
          mensaje: '4 horas', fechaRequerida: p.fechaHoraInicio);
      expect(sol.estado, EstadoSolicitud.pendiente);
      app.solicitudes.cotizar(prov, sol, const Dinero(200000), 'v1');
      app.solicitudes.cotizar(prov, sol, const Dinero(180000), 'v2 con descuento');
      expect(sol.cotizaciones.length, 2);
      expect(sol.estado, EstadoSolicitud.cotizada);
      final antes = app.presupuesto.resumen(p).servicios;
      app.solicitudes.aceptarCotizacion(org, sol);
      expect(sol.estado, EstadoSolicitud.aceptada);
      expect(app.presupuesto.resumen(p).servicios,
          antes + const Dinero(180000));
    });

    test('otro proveedor no puede cotizar una solicitud ajena', () {
      final sol = app.repo.solicitud(52)!;
      expect(() => app.solicitudes.cotizar(org, sol, const Dinero(100), 'x'),
          throwsA(isA<ErrorRegla>()));
    });
  });
}
