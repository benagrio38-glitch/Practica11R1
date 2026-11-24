import 'package:flutter/material.dart';

// Modelo de dominio de RecuParty corregido con la revisión del docente.
// Aquí solo viven los datos y las reglas propias de cada entidad. Las
// operaciones de la app (iniciar sesión, comprar, cotizar...) están en
// servicios_app.dart, como pide la corrección "Operaciones en clases de entidad".

// ---------------------------------------------------------------------------
// Dinero: en centavos enteros para no tener errores de redondeo con double.
// ---------------------------------------------------------------------------
class Dinero implements Comparable<Dinero> {
  const Dinero(this.centavos, {this.moneda = 'MXN'});

  /// Convierte lo que escribe el usuario ("1250.50") a centavos exactos.
  /// Regresa null si el texto no es un monto válido (máximo 2 decimales).
  static Dinero? deTexto(String texto) {
    final limpio = texto.trim().replaceAll(',', '');
    final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(limpio);
    if (m == null) return null;
    final pesos = int.parse(m.group(1)!);
    final dec = (m.group(2) ?? '').padRight(2, '0');
    return Dinero(pesos * 100 + int.parse(dec));
  }

  static const cero = Dinero(0);

  final int centavos;
  final String moneda;

  Dinero operator +(Dinero o) => Dinero(centavos + o.centavos, moneda: moneda);
  Dinero operator -(Dinero o) => Dinero(centavos - o.centavos, moneda: moneda);
  Dinero por(int n) => Dinero(centavos * n, moneda: moneda);
  bool get esPositivo => centavos > 0;

  @override
  int compareTo(Dinero o) => centavos.compareTo(o.centavos);

  @override
  bool operator ==(Object other) =>
      other is Dinero && other.centavos == centavos && other.moneda == moneda;

  @override
  int get hashCode => Object.hash(centavos, moneda);

  /// Formato "$1,250.50 MXN" (los centavos solo si hay).
  String get texto {
    final negativo = centavos < 0;
    final abs = centavos.abs();
    final pesos = abs ~/ 100;
    final cent = abs % 100;
    final miles = pesos.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    final dec = cent == 0 ? '' : '.${cent.toString().padLeft(2, '0')}';
    return '${negativo ? '-' : ''}\$$miles$dec';
  }

  @override
  String toString() => '$texto $moneda';
}

// ---------------------------------------------------------------------------
// Usuarios. Decisión: cada cuenta tiene UN solo rol. Si una persona quiere
// organizar y también ser proveedor, crea otra cuenta (perfiles separados).
// ---------------------------------------------------------------------------
enum Rol { organizador, invitado, proveedor }

extension RolTexto on Rol {
  String get nombre => switch (this) {
        Rol.organizador => 'Organizador',
        Rol.invitado => 'Invitado',
        Rol.proveedor => 'Proveedor',
      };

  String get descripcion => switch (this) {
        Rol.organizador =>
          'Crea parties, contrata salones, albercas y DJs y vende boletos.',
        Rol.invitado => 'Busca parties y compra tus boletos.',
        Rol.proveedor => 'Ofrece tus servicios y responde las solicitudes.',
      };

  IconData get icono => switch (this) {
        Rol.organizador => Icons.celebration,
        Rol.invitado => Icons.confirmation_number,
        Rol.proveedor => Icons.storefront,
      };
}

enum EstadoCuenta { activa, eliminacionSolicitada }

class Usuario {
  Usuario({
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.passwordHash,
    required this.salt,
    required this.rol,
    required this.fechaCreacion,
    this.estado = EstadoCuenta.activa,
    this.nombreNegocio,
    this.telefonoNegocio,
  });

  final int idUsuario;
  String nombre;
  String correo;
  // Nunca se guarda la contraseña legible, solo su hash con sal.
  String passwordHash;
  String salt;
  final Rol rol;
  EstadoCuenta estado;
  final DateTime fechaCreacion;
  DateTime? actualizadoEn;
  // Datos de negocio (solo proveedor).
  String? nombreNegocio;
  String? telefonoNegocio;
}

// ---------------------------------------------------------------------------
// Lugar estructurado (antes era texto libre).
// ---------------------------------------------------------------------------
class Lugar {
  const Lugar({
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    this.latitud,
    this.longitud,
  });

  final String nombre;
  final String direccion;
  final String ciudad;
  final double? latitud;
  final double? longitud;

  /// Lo que se ve públicamente antes de comprar boleto: nombre y ciudad.
  String get publico => '$nombre, $ciudad';

  /// La dirección completa solo la ven el organizador y quien tiene boleto.
  String get completo => '$nombre · $direccion, $ciudad';
}

// ---------------------------------------------------------------------------
// Fiesta (Party).
// ---------------------------------------------------------------------------
enum EstadoParty { borrador, publicada, cancelada, finalizada }

extension EstadoPartyTexto on EstadoParty {
  String get nombre => switch (this) {
        EstadoParty.borrador => 'Borrador',
        EstadoParty.publicada => 'Publicada',
        EstadoParty.cancelada => 'Cancelada',
        EstadoParty.finalizada => 'Finalizada',
      };
}

class Party {
  Party({
    required this.idParty,
    required this.organizadorId,
    required this.nombre,
    required this.descripcion,
    required this.fechaHoraInicio,
    required this.fechaHoraFin,
    required this.lugar,
    required this.invitadosEsperados,
    required this.aforoMaximo,
    required this.presupuesto,
    required this.precioBoleto,
    this.edadMinima = 18,
    this.estado = EstadoParty.borrador,
    this.zonaHoraria = 'America/Mexico_City',
  });

  final int idParty;
  final int organizadorId;
  String nombre;
  String descripcion;
  DateTime fechaHoraInicio;
  DateTime fechaHoraFin;
  final String zonaHoraria;
  Lugar lugar;
  int invitadosEsperados;
  int aforoMaximo;
  Dinero presupuesto;
  Dinero precioBoleto;
  int edadMinima;
  EstadoParty estado;

  // Reglas propias de la fiesta.
  bool get sePuedeEditar =>
      estado == EstadoParty.borrador || estado == EstadoParty.publicada;
  bool get sePuedePublicar => estado == EstadoParty.borrador;
  bool get sePuedeCancelar =>
      estado == EstadoParty.borrador || estado == EstadoParty.publicada;
  bool get vendeBoletos => estado == EstadoParty.publicada;

  /// Política de cancelación de boletos: hasta 48 horas antes del inicio.
  bool permiteCancelarBoleto(DateTime ahora) =>
      vendeBoletos &&
      fechaHoraInicio.difference(ahora) >= const Duration(hours: 48);
}

// ---------------------------------------------------------------------------
// Compra, pago y boletos (un boleto por asistente).
// ---------------------------------------------------------------------------
enum EstadoCompra { pendiente, pagada, cancelada }

enum EstadoPago { aprobado, rechazado, reembolsado }

enum EstadoBoleto { valido, usado, cancelado }

extension EstadoBoletoTexto on EstadoBoleto {
  String get nombre => switch (this) {
        EstadoBoleto.valido => 'Válido',
        EstadoBoleto.usado => 'Usado',
        EstadoBoleto.cancelado => 'Cancelado',
      };
}

class Compra {
  Compra({
    required this.idCompra,
    required this.partyId,
    required this.compradorId,
    required this.fechaCompra,
    required this.total,
    this.estado = EstadoCompra.pendiente,
  });

  final int idCompra;
  final int partyId;
  final int compradorId;
  final DateTime fechaCompra;
  final Dinero total;
  EstadoCompra estado;
}

class Pago {
  Pago({
    required this.idPago,
    required this.compraId,
    required this.monto,
    required this.metodo,
    required this.referencia,
    required this.fecha,
    this.estado = EstadoPago.aprobado,
  });

  final int idPago;
  final int compraId;
  final Dinero monto;
  // Solo el tipo de método ("Tarjeta terminación 4242"); nunca el número
  // completo ni el código de seguridad.
  final String metodo;
  final String referencia;
  final DateTime fecha;
  EstadoPago estado;
}

class Boleto {
  Boleto({
    required this.idBoleto,
    required this.partyId,
    required this.compraId,
    required this.compradorId,
    required this.asistente,
    required this.precioUnitario,
    required this.fechaCompra,
    required this.codigoAcceso,
    this.estado = EstadoBoleto.valido,
  });

  final int idBoleto;
  final int partyId;
  final int compraId;
  final int compradorId;
  final String asistente;
  final Dinero precioUnitario;
  final DateTime fechaCompra;
  // Identificador único de acceso; no se reutiliza.
  final String codigoAcceso;
  EstadoBoleto estado;
  DateTime? usadoEn;
}

// ---------------------------------------------------------------------------
// Servicios de proveedores.
// ---------------------------------------------------------------------------
enum TipoServicio { salon, alberca, dj, banquete, decoracion }

extension TipoServicioTexto on TipoServicio {
  String get nombre => switch (this) {
        TipoServicio.salon => 'Salón',
        TipoServicio.alberca => 'Alberca',
        TipoServicio.dj => 'DJ',
        TipoServicio.banquete => 'Banquete',
        TipoServicio.decoracion => 'Decoración',
      };

  String get imagen => switch (this) {
        TipoServicio.salon => 'assets/images/salon_luna.jpg',
        TipoServicio.alberca => 'assets/images/alberca_oasis.jpg',
        TipoServicio.dj => 'assets/images/dj_kora.jpg',
        TipoServicio.banquete => 'assets/images/quinta_pinos.jpg',
        TipoServicio.decoracion => 'assets/images/party.jpg',
      };
}

enum UnidadPrecio { porEvento, porHora, porPersona }

extension UnidadPrecioTexto on UnidadPrecio {
  String get nombre => switch (this) {
        UnidadPrecio.porEvento => 'por evento',
        UnidadPrecio.porHora => 'por hora',
        UnidadPrecio.porPersona => 'por persona',
      };
}

class Servicio {
  Servicio({
    required this.idServicio,
    required this.proveedorId,
    required this.nombre,
    required this.tipo,
    required this.precio,
    required this.unidadPrecio,
    required this.descripcion,
    required this.imagen,
    required this.zona,
    this.disponible = true,
    this.activo = true,
    this.aprobado = true,
  });

  final int idServicio;
  final int proveedorId;
  String nombre;
  TipoServicio tipo;
  Dinero precio;
  UnidadPrecio unidadPrecio;
  String descripcion;
  String imagen;
  String zona; // ciudad o zona donde da servicio
  bool disponible;
  // Baja lógica: un servicio con solicitudes no se borra, se desactiva.
  bool activo;
  // Moderación: los servicios nuevos pasan por revisión antes de mostrarse.
  bool aprobado;

  bool get visibleEnCatalogo => activo && aprobado;
}

// ---------------------------------------------------------------------------
// Solicitudes de servicio y sus cotizaciones (con historial de versiones).
// ---------------------------------------------------------------------------
enum EstadoSolicitud { pendiente, cotizada, aceptada, rechazada, cancelada }

extension EstadoSolicitudTexto on EstadoSolicitud {
  String get nombre => switch (this) {
        EstadoSolicitud.pendiente => 'Pendiente',
        EstadoSolicitud.cotizada => 'Cotizada',
        EstadoSolicitud.aceptada => 'Aceptada',
        EstadoSolicitud.rechazada => 'Rechazada',
        EstadoSolicitud.cancelada => 'Cancelada',
      };

  bool get abierta =>
      this == EstadoSolicitud.pendiente || this == EstadoSolicitud.cotizada;
}

enum RespuestaCotizacion { sinRespuesta, aceptada, rechazada }

class Cotizacion {
  Cotizacion({
    required this.version,
    required this.precio,
    required this.comentarios,
    required this.fecha,
    required this.vigenciaHasta,
    this.respuesta = RespuestaCotizacion.sinRespuesta,
  });

  final int version;
  final Dinero precio;
  final String comentarios;
  final DateTime fecha;
  final DateTime vigenciaHasta;
  RespuestaCotizacion respuesta;
}

class Solicitud {
  Solicitud({
    required this.idSolicitud,
    required this.partyId,
    required this.servicioId,
    required this.organizadorId,
    required this.proveedorId,
    required this.mensaje,
    required this.fechaRequerida,
    required this.fechaCreacion,
    this.estado = EstadoSolicitud.pendiente,
  });

  final int idSolicitud;
  final int partyId;
  final int servicioId;
  final int organizadorId;
  final int proveedorId;
  final String mensaje;
  final DateTime fechaRequerida;
  final DateTime fechaCreacion;
  EstadoSolicitud estado;
  String? motivoRechazo;
  final List<Cotizacion> cotizaciones = [];

  Cotizacion? get cotizacionVigente =>
      cotizaciones.isEmpty ? null : cotizaciones.last;
}

// ---------------------------------------------------------------------------
// Presupuesto: otros gastos de la fiesta (además de servicios aceptados).
// ---------------------------------------------------------------------------
class Gasto {
  Gasto({
    required this.idGasto,
    required this.partyId,
    required this.concepto,
    required this.monto,
    required this.fecha,
    this.solicitudId,
  });

  final int idGasto;
  final int partyId;
  final String concepto;
  final Dinero monto;
  final DateTime fecha;
  final int? solicitudId; // si el gasto viene de un servicio contratado
}
