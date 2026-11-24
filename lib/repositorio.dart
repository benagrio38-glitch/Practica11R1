import 'modelos.dart';
import 'seguridad.dart';

// Repositorio en memoria: guarda las listas de entidades. Los datos se
// reinician al cerrar la app (no hay servidor ni base de datos todavía).
class Repositorio {
  final List<Usuario> usuarios = [];
  final List<Party> parties = [];
  final List<Servicio> servicios = [];
  final List<Compra> compras = [];
  final List<Pago> pagos = [];
  final List<Boleto> boletos = [];
  final List<Solicitud> solicitudes = [];
  final List<Gasto> gastos = [];
  // Códigos para recuperar acceso: correo -> (código, vence).
  final Map<String, (String, DateTime)> codigosRecuperacion = {};
  final Set<String> codigosUsados = {};

  int _siguienteId = 100;
  int nuevoId() => _siguienteId++;

  Usuario? usuario(int id) => _buscar(usuarios, (u) => u.idUsuario == id);
  Party? party(int id) => _buscar(parties, (p) => p.idParty == id);
  Servicio? servicio(int id) => _buscar(servicios, (s) => s.idServicio == id);
  Compra? compra(int id) => _buscar(compras, (c) => c.idCompra == id);
  Solicitud? solicitud(int id) =>
      _buscar(solicitudes, (s) => s.idSolicitud == id);

  static T? _buscar<T>(List<T> lista, bool Function(T) f) {
    for (final x in lista) {
      if (f(x)) return x;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Datos de ejemplo para la demostración.
  // ---------------------------------------------------------------------
  void cargarEjemplo(Seguridad seg, DateTime ahora) {
    Usuario u(int id, String nombre, String correo, Rol rol,
        {String? negocio}) {
      final sal = seg.nuevaSal();
      return Usuario(
        idUsuario: id,
        nombre: nombre,
        correo: correo,
        passwordHash: seg.hashDe('123456', sal),
        salt: sal,
        rol: rol,
        fechaCreacion: ahora.subtract(const Duration(days: 30)),
        nombreNegocio: negocio,
      );
    }

    usuarios.addAll([
      u(1, 'Ana Organizadora', 'organizador@recuparty.com', Rol.organizador),
      u(2, 'Pepe Invitado', 'invitado@recuparty.com', Rol.invitado),
      u(3, 'Luis Proveedor', 'proveedor@recuparty.com', Rol.proveedor,
          negocio: 'Eventos Luis'),
      u(4, 'Carla Invitada', 'carla@recuparty.com', Rol.invitado),
    ]);

    DateTime dia(int dias, int hora) =>
        DateTime(ahora.year, ahora.month, ahora.day + dias, hora);

    parties.addAll([
      Party(
        idParty: 1,
        organizadorId: 1,
        nombre: 'Fiesta de recuperación',
        descripcion: 'Para celebrar que pasamos las recuperaciones.',
        fechaHoraInicio: dia(10, 20),
        fechaHoraFin: dia(11, 2),
        lugar: const Lugar(
          nombre: 'Salón La Terraza',
          direccion: 'Av. Insurgentes 120, Centro',
          ciudad: 'Dolores Hidalgo',
          latitud: 21.157,
          longitud: -100.934,
        ),
        invitadosEsperados: 70,
        aforoMaximo: 80,
        presupuesto: const Dinero(1200000),
        precioBoleto: const Dinero(12000),
        estado: EstadoParty.publicada,
      ),
      Party(
        idParty: 2,
        organizadorId: 1,
        nombre: 'Pool party fin de cuatri',
        descripcion: 'Alberca, música y asadores.',
        fechaHoraInicio: dia(20, 14),
        fechaHoraFin: dia(20, 21),
        lugar: const Lugar(
          nombre: 'Alberca Sol',
          direccion: 'Camino a la Presa km 3',
          ciudad: 'Dolores Hidalgo',
        ),
        invitadosEsperados: 45,
        aforoMaximo: 50,
        presupuesto: const Dinero(800000),
        precioBoleto: const Dinero(15000),
        estado: EstadoParty.publicada,
      ),
      Party(
        idParty: 3,
        organizadorId: 1,
        nombre: 'Posada UTNG',
        descripcion: 'Posada del grupo con intercambio.',
        fechaHoraInicio: dia(28, 19),
        fechaHoraFin: dia(28, 23),
        lugar: const Lugar(
          nombre: 'Quinta Los Pinos',
          direccion: 'Carretera a San Miguel km 5',
          ciudad: 'Dolores Hidalgo',
        ),
        invitadosEsperados: 30,
        aforoMaximo: 40,
        presupuesto: const Dinero(500000),
        precioBoleto: const Dinero(10000),
      ),
    ]);

    Servicio s(int id, String nombre, TipoServicio tipo, int pesos,
            UnidadPrecio unidad, String desc, String img) =>
        Servicio(
          idServicio: id,
          proveedorId: 3,
          nombre: nombre,
          tipo: tipo,
          precio: Dinero(pesos * 100),
          unidadPrecio: unidad,
          descripcion: desc,
          imagen: img,
          zona: 'Dolores Hidalgo',
        );

    servicios.addAll([
      s(1, 'Salón La Terraza', TipoServicio.salon, 3500, UnidadPrecio.porEvento,
          'Para 80 personas, con pista de baile y estacionamiento.',
          'assets/images/salon_terraza.jpg'),
      s(2, 'Alberca Sol', TipoServicio.alberca, 2800, UnidadPrecio.porEvento,
          'Alberca con asadores y mesas para 50 personas.',
          'assets/images/alberca_sol.jpg'),
      s(3, 'DJ Nova', TipoServicio.dj, 500, UnidadPrecio.porHora,
          'Música con luces y sonido, mínimo 4 horas.',
          'assets/images/dj_nova.jpg'),
      s(4, 'Taquizas Chuy', TipoServicio.banquete, 85, UnidadPrecio.porPersona,
          'Taquiza de 5 guisados con tortillas hechas a mano.',
          'assets/images/dj_chuy.jpg'),
    ]);

    // Ventas de ejemplo: 18 boletos de la fiesta 1 y 2 de la fiesta 2.
    void vender(int compradorId, int partyId, List<String> asistentes,
        int diasAtras) {
      final p = party(partyId)!;
      final idCompra = nuevoId();
      final fecha = ahora.subtract(Duration(days: diasAtras));
      final total = p.precioBoleto.por(asistentes.length);
      compras.add(Compra(
        idCompra: idCompra,
        partyId: partyId,
        compradorId: compradorId,
        fechaCompra: fecha,
        total: total,
        estado: EstadoCompra.pagada,
      ));
      pagos.add(Pago(
        idPago: nuevoId(),
        compraId: idCompra,
        monto: total,
        metodo: 'Tarjeta terminación 4242',
        referencia: 'PAGO-$idCompra',
        fecha: fecha,
      ));
      for (final a in asistentes) {
        var codigo = seg.codigoBoleto();
        while (codigosUsados.contains(codigo)) {
          codigo = seg.codigoBoleto();
        }
        codigosUsados.add(codigo);
        boletos.add(Boleto(
          idBoleto: nuevoId(),
          partyId: partyId,
          compraId: idCompra,
          compradorId: compradorId,
          asistente: a,
          precioUnitario: p.precioBoleto,
          fechaCompra: fecha,
          codigoAcceso: codigo,
        ));
      }
    }

    vender(2, 1, ['Pepe Invitado', 'Lupita Ramírez'], 3);
    vender(4, 1, [for (var i = 1; i <= 16; i++) 'Asistente $i'], 5);
    vender(4, 2, ['Carla Invitada', 'Mario López'], 2);

    // Solicitudes de ejemplo en distintos estados.
    Solicitud sol(int id, int partyId, int servicioId, String msg,
        EstadoSolicitud estado) {
      final p = party(partyId)!;
      final x = Solicitud(
        idSolicitud: id,
        partyId: partyId,
        servicioId: servicioId,
        organizadorId: 1,
        proveedorId: 3,
        mensaje: msg,
        fechaRequerida: p.fechaHoraInicio,
        fechaCreacion: ahora.subtract(const Duration(days: 4)),
        estado: estado,
      );
      solicitudes.add(x);
      return x;
    }

    final aceptada = sol(50, 1, 1, 'Necesitamos el salón de 8 pm a 2 am.',
        EstadoSolicitud.aceptada);
    aceptada.cotizaciones.add(Cotizacion(
      version: 1,
      precio: const Dinero(350000),
      comentarios: 'Incluye mesas, sillas y limpieza.',
      fecha: ahora.subtract(const Duration(days: 3)),
      vigenciaHasta: ahora.add(const Duration(days: 7)),
      respuesta: RespuestaCotizacion.aceptada,
    ));
    final cotizada = sol(51, 1, 3, '¿Pueden traer luces de colores?',
        EstadoSolicitud.cotizada);
    cotizada.cotizaciones.add(Cotizacion(
      version: 1,
      precio: const Dinero(240000),
      comentarios: '6 horas con luces y máquina de humo.',
      fecha: ahora.subtract(const Duration(days: 1)),
      vigenciaHasta: ahora.add(const Duration(days: 5)),
    ));
    sol(52, 2, 2, 'Para 50 personas, de 2 a 9 pm.', EstadoSolicitud.pendiente);

    gastos.add(Gasto(
      idGasto: nuevoId(),
      partyId: 1,
      concepto: 'Salón La Terraza (servicio aceptado)',
      monto: const Dinero(350000),
      fecha: ahora.subtract(const Duration(days: 3)),
      solicitudId: 50,
    ));
    gastos.add(Gasto(
      idGasto: nuevoId(),
      partyId: 1,
      concepto: 'Decoración y globos',
      monto: const Dinero(80000),
      fecha: ahora.subtract(const Duration(days: 2)),
    ));
  }
}
