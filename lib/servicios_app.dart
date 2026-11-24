import 'modelos.dart';
import 'repositorio.dart';
import 'seguridad.dart';

// Servicios de aplicación: aquí están las operaciones (iniciar sesión,
// comprar boletos, cotizar...) que antes estaban mezcladas en las entidades.
// Cada operación revisa permisos y reglas, y lanza ErrorRegla si algo no se
// puede hacer.

class ErrorRegla implements Exception {
  const ErrorRegla(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

typedef Reloj = DateTime Function();

// ---------------------------------------------------------------------------
// Cuentas: registro, sesión, recuperación y perfil.
// ---------------------------------------------------------------------------
class ServicioCuentas {
  ServicioCuentas(this._repo, this._seg, this._reloj);
  final Repositorio _repo;
  final Seguridad _seg;
  final Reloj _reloj;

  Usuario? _buscarPorCorreo(String correo) {
    final c = correo.trim().toLowerCase();
    for (final u in _repo.usuarios) {
      if (u.correo == c) return u;
    }
    return null;
  }

  Usuario registrar({
    required String nombre,
    required String correo,
    required String clave,
    required Rol rol,
  }) {
    final c = correo.trim().toLowerCase();
    if (_buscarPorCorreo(c) != null) {
      throw const ErrorRegla('Ese correo ya está registrado');
    }
    final sal = _seg.nuevaSal();
    final u = Usuario(
      idUsuario: _repo.nuevoId(),
      nombre: nombre.trim(),
      correo: c,
      passwordHash: _seg.hashDe(clave, sal),
      salt: sal,
      rol: rol,
      fechaCreacion: _reloj(),
    );
    _repo.usuarios.add(u);
    return u;
  }

  Usuario iniciarSesion(String correo, String clave) {
    final u = _buscarPorCorreo(correo);
    if (u == null || !_seg.coincide(clave, u.salt, u.passwordHash)) {
      throw const ErrorRegla('Correo o contraseña incorrectos');
    }
    if (u.estado == EstadoCuenta.eliminacionSolicitada) {
      throw const ErrorRegla('Esta cuenta pidió ser eliminada');
    }
    return u;
  }

  /// Simula el envío del código por correo (no hay servidor de correo).
  /// Regresa el código para mostrarlo en la demostración.
  String solicitarRecuperacion(String correo) {
    final u = _buscarPorCorreo(correo);
    if (u == null) throw const ErrorRegla('No hay una cuenta con ese correo');
    final codigo = _seg.codigoRecuperacion();
    _repo.codigosRecuperacion[u.correo] =
        (codigo, _reloj().add(const Duration(minutes: 15)));
    return codigo;
  }

  void restablecerClave(String correo, String codigo, String nueva) {
    final c = correo.trim().toLowerCase();
    final guardado = _repo.codigosRecuperacion[c];
    if (guardado == null ||
        guardado.$1 != codigo.trim() ||
        _reloj().isAfter(guardado.$2)) {
      throw const ErrorRegla('El código no es válido o ya venció');
    }
    final u = _buscarPorCorreo(c)!;
    _ponerClave(u, nueva);
    _repo.codigosRecuperacion.remove(c);
  }

  void _ponerClave(Usuario u, String clave) {
    u.salt = _seg.nuevaSal();
    u.passwordHash = _seg.hashDe(clave, u.salt);
    u.actualizadoEn = _reloj();
  }

  void actualizarPerfil(Usuario u,
      {required String nombre,
      required String correo,
      String? negocio,
      String? telefono}) {
    final c = correo.trim().toLowerCase();
    final otro = _buscarPorCorreo(c);
    if (otro != null && otro.idUsuario != u.idUsuario) {
      throw const ErrorRegla('Ese correo ya lo usa otra cuenta');
    }
    u
      ..nombre = nombre.trim()
      ..correo = c
      ..nombreNegocio = negocio?.trim().isEmpty ?? true ? null : negocio!.trim()
      ..telefonoNegocio =
          telefono?.trim().isEmpty ?? true ? null : telefono!.trim()
      ..actualizadoEn = _reloj();
  }

  void cambiarClave(Usuario u, String actual, String nueva) {
    if (!_seg.coincide(actual, u.salt, u.passwordHash)) {
      throw const ErrorRegla('La contraseña actual no es correcta');
    }
    _ponerClave(u, nueva);
  }

  /// La cuenta queda marcada; las fiestas, boletos y solicitudes se conservan
  /// para el historial de las otras personas.
  void solicitarEliminacion(Usuario u, String clave) {
    if (!_seg.coincide(clave, u.salt, u.passwordHash)) {
      throw const ErrorRegla('La contraseña no es correcta');
    }
    u
      ..estado = EstadoCuenta.eliminacionSolicitada
      ..actualizadoEn = _reloj();
  }
}

// ---------------------------------------------------------------------------
// Fiestas.
// ---------------------------------------------------------------------------
class DatosParty {
  const DatosParty({
    required this.nombre,
    required this.descripcion,
    required this.inicio,
    required this.fin,
    required this.lugar,
    required this.invitadosEsperados,
    required this.aforoMaximo,
    required this.presupuesto,
    required this.precioBoleto,
    required this.edadMinima,
  });

  final String nombre;
  final String descripcion;
  final DateTime inicio;
  final DateTime fin;
  final Lugar lugar;
  final int invitadosEsperados;
  final int aforoMaximo;
  final Dinero presupuesto;
  final Dinero precioBoleto;
  final int edadMinima;
}

class ServicioFiestas {
  ServicioFiestas(this._repo, this._reloj);
  final Repositorio _repo;
  final Reloj _reloj;

  void _validar(DatosParty d) {
    if (!d.fin.isAfter(d.inicio)) {
      throw const ErrorRegla('La hora de fin debe ser después del inicio');
    }
    if (d.aforoMaximo < d.invitadosEsperados) {
      throw const ErrorRegla(
          'El aforo máximo no puede ser menor que los invitados esperados');
    }
    if (d.edadMinima < 18) {
      throw const ErrorRegla('La app es solo para mayores de 18 años');
    }
  }

  void _soloDueno(Usuario u, Party p) {
    if (p.organizadorId != u.idUsuario) {
      throw const ErrorRegla('Solo puedes cambiar tus propias fiestas');
    }
  }

  Party crear(Usuario organizador, DatosParty d) {
    if (organizador.rol != Rol.organizador) {
      throw const ErrorRegla('Solo un organizador puede crear fiestas');
    }
    _validar(d);
    final p = Party(
      idParty: _repo.nuevoId(),
      organizadorId: organizador.idUsuario,
      nombre: d.nombre.trim(),
      descripcion: d.descripcion.trim(),
      fechaHoraInicio: d.inicio,
      fechaHoraFin: d.fin,
      lugar: d.lugar,
      invitadosEsperados: d.invitadosEsperados,
      aforoMaximo: d.aforoMaximo,
      presupuesto: d.presupuesto,
      precioBoleto: d.precioBoleto,
      edadMinima: d.edadMinima,
    );
    _repo.parties.add(p);
    return p;
  }

  void editar(Usuario u, Party p, DatosParty d, int boletosValidos) {
    _soloDueno(u, p);
    if (!p.sePuedeEditar) {
      throw const ErrorRegla('Una fiesta cancelada o finalizada no se edita');
    }
    _validar(d);
    if (d.aforoMaximo < boletosValidos) {
      throw ErrorRegla(
          'Ya vendiste $boletosValidos boletos; el aforo no puede ser menor');
    }
    if (boletosValidos > 0 && d.precioBoleto != p.precioBoleto) {
      throw const ErrorRegla(
          'No se cambia el precio cuando ya hay boletos vendidos');
    }
    p
      ..nombre = d.nombre.trim()
      ..descripcion = d.descripcion.trim()
      ..fechaHoraInicio = d.inicio
      ..fechaHoraFin = d.fin
      ..lugar = d.lugar
      ..invitadosEsperados = d.invitadosEsperados
      ..aforoMaximo = d.aforoMaximo
      ..presupuesto = d.presupuesto
      ..precioBoleto = d.precioBoleto
      ..edadMinima = d.edadMinima;
  }

  void publicar(Usuario u, Party p) {
    _soloDueno(u, p);
    if (!p.sePuedePublicar) {
      throw const ErrorRegla('Solo se publica una fiesta en borrador');
    }
    if (p.fechaHoraInicio.isBefore(_reloj())) {
      throw const ErrorRegla('La fecha de la fiesta ya pasó');
    }
    p.estado = EstadoParty.publicada;
  }

  /// Cancela la fiesta: los boletos válidos se cancelan y sus pagos se
  /// reembolsan completos (política de reembolso de la app).
  void cancelar(Usuario u, Party p) {
    _soloDueno(u, p);
    if (!p.sePuedeCancelar) {
      throw const ErrorRegla('Esta fiesta ya no se puede cancelar');
    }
    p.estado = EstadoParty.cancelada;
    for (final b in _repo.boletos.where((b) => b.partyId == p.idParty)) {
      if (b.estado == EstadoBoleto.valido) b.estado = EstadoBoleto.cancelado;
    }
    for (final c in _repo.compras.where((c) => c.partyId == p.idParty)) {
      c.estado = EstadoCompra.cancelada;
      for (final pago in _repo.pagos.where((x) => x.compraId == c.idCompra)) {
        pago.estado = EstadoPago.reembolsado;
      }
    }
    for (final s in _repo.solicitudes.where((s) => s.partyId == p.idParty)) {
      if (s.estado.abierta) s.estado = EstadoSolicitud.cancelada;
    }
  }

  List<Party> delOrganizador(Usuario u) =>
      _repo.parties.where((p) => p.organizadorId == u.idUsuario).toList()
        ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));

  /// Fiestas públicas: publicadas y que todavía no empiezan.
  List<Party> publicas({String texto = '', DateTime? desde, Dinero? maxPrecio}) {
    final t = texto.trim().toLowerCase();
    return _repo.parties.where((p) {
      if (p.estado != EstadoParty.publicada) return false;
      if (p.fechaHoraInicio.isBefore(_reloj())) return false;
      if (t.isNotEmpty &&
          !p.nombre.toLowerCase().contains(t) &&
          !p.lugar.publico.toLowerCase().contains(t)) {
        return false;
      }
      if (desde != null && p.fechaHoraInicio.isBefore(desde)) return false;
      if (maxPrecio != null && p.precioBoleto > maxPrecio) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));
  }
}

extension on Dinero {
  bool operator >(Dinero o) => centavos > o.centavos;
}

// ---------------------------------------------------------------------------
// Boletos: compra con pago simulado, consulta, cancelación y acceso.
// ---------------------------------------------------------------------------
class ServicioBoletos {
  ServicioBoletos(this._repo, this._seg, this._reloj);
  final Repositorio _repo;
  final Seguridad _seg;
  final Reloj _reloj;

  /// Vendidos = boletos válidos o usados (se calcula, no se guarda).
  int vendidos(Party p) => _repo.boletos
      .where((b) => b.partyId == p.idParty && b.estado != EstadoBoleto.cancelado)
      .length;

  int disponibles(Party p) => p.aforoMaximo - vendidos(p);

  Dinero recaudado(Party p) => _repo.boletos
      .where((b) => b.partyId == p.idParty && b.estado != EstadoBoleto.cancelado)
      .fold(Dinero.cero, (s, b) => s + b.precioUnitario);

  /// Compra un boleto por asistente. El pago es simulado: solo se guarda
  /// la terminación de la tarjeta, nunca el número completo ni el CVV.
  Compra comprar(Usuario comprador, Party p, List<String> asistentes,
      {required String terminacionTarjeta}) {
    if (comprador.rol != Rol.invitado) {
      throw const ErrorRegla('Solo los invitados compran boletos');
    }
    if (!p.vendeBoletos) {
      throw const ErrorRegla('Esta fiesta no está a la venta');
    }
    final nombres = asistentes.map((a) => a.trim()).toList();
    if (nombres.isEmpty || nombres.any((a) => a.isEmpty)) {
      throw const ErrorRegla('Escribe el nombre de cada asistente');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(terminacionTarjeta)) {
      throw const ErrorRegla('Escribe los últimos 4 dígitos de la tarjeta');
    }
    // Control de aforo: no se vende más que el aforo permitido. Como todo
    // pasa en un solo hilo, esta revisión y el alta de los boletos ocurren
    // juntas y no puede haber sobreventa.
    if (nombres.length > disponibles(p)) {
      throw ErrorRegla('Solo quedan ${disponibles(p)} boletos');
    }
    final ahora = _reloj();
    final total = p.precioBoleto.por(nombres.length);
    final compra = Compra(
      idCompra: _repo.nuevoId(),
      partyId: p.idParty,
      compradorId: comprador.idUsuario,
      fechaCompra: ahora,
      total: total,
    );
    _repo.compras.add(compra);
    _repo.pagos.add(Pago(
      idPago: _repo.nuevoId(),
      compraId: compra.idCompra,
      monto: total,
      metodo: 'Tarjeta terminación $terminacionTarjeta',
      referencia: 'PAGO-${compra.idCompra}',
      fecha: ahora,
    ));
    compra.estado = EstadoCompra.pagada;
    for (final a in nombres) {
      _repo.boletos.add(Boleto(
        idBoleto: _repo.nuevoId(),
        partyId: p.idParty,
        compraId: compra.idCompra,
        compradorId: comprador.idUsuario,
        asistente: a,
        precioUnitario: p.precioBoleto,
        fechaCompra: ahora,
        codigoAcceso: _codigoUnico(),
      ));
    }
    return compra;
  }

  String _codigoUnico() {
    var c = _seg.codigoBoleto();
    while (_repo.codigosUsados.contains(c)) {
      c = _seg.codigoBoleto();
    }
    _repo.codigosUsados.add(c);
    return c;
  }

  List<Compra> comprasDe(Usuario u) =>
      _repo.compras.where((c) => c.compradorId == u.idUsuario).toList()
        ..sort((a, b) => b.fechaCompra.compareTo(a.fechaCompra));

  List<Boleto> boletosDeCompra(Compra c) =>
      _repo.boletos.where((b) => b.compraId == c.idCompra).toList();

  bool tieneBoleto(Usuario u, Party p) => _repo.boletos.any((b) =>
      b.compradorId == u.idUsuario &&
      b.partyId == p.idParty &&
      b.estado != EstadoBoleto.cancelado);

  /// Cancelación de un boleto según la política de la fiesta (hasta 48 h
  /// antes). Se reembolsa el precio del boleto.
  void cancelarBoleto(Usuario u, Boleto b) {
    if (b.compradorId != u.idUsuario) {
      throw const ErrorRegla('Ese boleto no es tuyo');
    }
    final p = _repo.party(b.partyId)!;
    if (b.estado != EstadoBoleto.valido) {
      throw const ErrorRegla('El boleto ya no está activo');
    }
    if (!p.permiteCancelarBoleto(_reloj())) {
      throw const ErrorRegla(
          'Solo se cancela hasta 48 horas antes de la fiesta');
    }
    b.estado = EstadoBoleto.cancelado;
  }

  /// Boletos vendidos de una fiesta: solo los ve su organizador.
  List<Boleto> vendidosDe(Usuario u, Party p) {
    if (p.organizadorId != u.idUsuario) {
      throw const ErrorRegla('Solo el organizador ve a los asistentes');
    }
    return _repo.boletos.where((b) => b.partyId == p.idParty).toList();
  }

  /// Validación en la entrada: el mismo boleto no entra dos veces.
  Boleto validarEntrada(Usuario u, Party p, String codigo) {
    if (p.organizadorId != u.idUsuario) {
      throw const ErrorRegla('Solo el organizador valida la entrada');
    }
    final c = codigo.trim().toUpperCase();
    for (final b in _repo.boletos) {
      if (b.partyId == p.idParty && b.codigoAcceso == c) {
        if (b.estado == EstadoBoleto.usado) {
          throw const ErrorRegla('Ese boleto ya se usó');
        }
        if (b.estado == EstadoBoleto.cancelado) {
          throw const ErrorRegla('Ese boleto está cancelado');
        }
        b
          ..estado = EstadoBoleto.usado
          ..usadoEn = _reloj();
        return b;
      }
    }
    throw const ErrorRegla('El código no pertenece a esta fiesta');
  }
}

// ---------------------------------------------------------------------------
// Catálogo de servicios.
// ---------------------------------------------------------------------------
class DatosServicio {
  const DatosServicio({
    required this.nombre,
    required this.tipo,
    required this.precio,
    required this.unidad,
    required this.descripcion,
    required this.zona,
    required this.disponible,
  });

  final String nombre;
  final TipoServicio tipo;
  final Dinero precio;
  final UnidadPrecio unidad;
  final String descripcion;
  final String zona;
  final bool disponible;
}

class ServicioCatalogo {
  ServicioCatalogo(this._repo);
  final Repositorio _repo;

  List<Servicio> catalogo(
      {String texto = '', TipoServicio? tipo, Dinero? maxPrecio}) {
    final t = texto.trim().toLowerCase();
    return _repo.servicios.where((s) {
      if (!s.visibleEnCatalogo) return false;
      if (tipo != null && s.tipo != tipo) return false;
      if (maxPrecio != null && s.precio.centavos > maxPrecio.centavos) {
        return false;
      }
      if (t.isNotEmpty &&
          !s.nombre.toLowerCase().contains(t) &&
          !s.descripcion.toLowerCase().contains(t)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Servicio> delProveedor(Usuario u) =>
      _repo.servicios.where((s) => s.proveedorId == u.idUsuario).toList();

  Servicio publicar(Usuario proveedor, DatosServicio d) {
    if (proveedor.rol != Rol.proveedor) {
      throw const ErrorRegla('Solo un proveedor publica servicios');
    }
    final s = Servicio(
      idServicio: _repo.nuevoId(),
      proveedorId: proveedor.idUsuario,
      nombre: d.nombre.trim(),
      tipo: d.tipo,
      precio: d.precio,
      unidadPrecio: d.unidad,
      descripcion: d.descripcion.trim(),
      imagen: d.tipo.imagen,
      zona: d.zona.trim(),
      disponible: d.disponible,
      // Moderación: en la demo se aprueba al momento; con servidor quedaría
      // en revisión hasta que un administrador lo apruebe.
      aprobado: true,
    );
    _repo.servicios.add(s);
    return s;
  }

  void editar(Usuario u, Servicio s, DatosServicio d) {
    if (s.proveedorId != u.idUsuario) {
      throw const ErrorRegla('Solo puedes editar tus servicios');
    }
    s
      ..nombre = d.nombre.trim()
      ..tipo = d.tipo
      ..precio = d.precio
      ..unidadPrecio = d.unidad
      ..descripcion = d.descripcion.trim()
      ..zona = d.zona.trim()
      ..disponible = d.disponible;
  }

  /// Baja lógica: nunca se borra un servicio porque puede tener solicitudes
  /// históricas.
  void cambiarActivo(Usuario u, Servicio s, bool activo) {
    if (s.proveedorId != u.idUsuario) {
      throw const ErrorRegla('Solo puedes cambiar tus servicios');
    }
    s.activo = activo;
  }
}

// ---------------------------------------------------------------------------
// Solicitudes y cotizaciones.
// ---------------------------------------------------------------------------
class ServicioSolicitudes {
  ServicioSolicitudes(this._repo, this._reloj);
  final Repositorio _repo;
  final Reloj _reloj;

  Solicitud solicitar(Usuario org, Party p, Servicio s,
      {required String mensaje, required DateTime fechaRequerida}) {
    if (p.organizadorId != org.idUsuario) {
      throw const ErrorRegla('Solo puedes pedir servicios para tus fiestas');
    }
    if (!p.sePuedeEditar) {
      throw const ErrorRegla('Esa fiesta ya no acepta servicios');
    }
    if (!s.visibleEnCatalogo || !s.disponible) {
      throw const ErrorRegla('Ese servicio no está disponible');
    }
    final repetida = _repo.solicitudes.any((x) =>
        x.partyId == p.idParty &&
        x.servicioId == s.idServicio &&
        x.estado.abierta);
    if (repetida) {
      throw ErrorRegla('Ya hay una solicitud abierta de ${s.nombre} '
          'para ${p.nombre}');
    }
    final sol = Solicitud(
      idSolicitud: _repo.nuevoId(),
      partyId: p.idParty,
      servicioId: s.idServicio,
      organizadorId: org.idUsuario,
      proveedorId: s.proveedorId,
      mensaje: mensaje.trim(),
      fechaRequerida: fechaRequerida,
      fechaCreacion: _reloj(),
    );
    _repo.solicitudes.add(sol);
    return sol;
  }

  List<Solicitud> delOrganizador(Usuario u) => _repo.solicitudes
      .where((s) => s.organizadorId == u.idUsuario)
      .toList()
    ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

  List<Solicitud> delProveedor(Usuario u) => _repo.solicitudes
      .where((s) => s.proveedorId == u.idUsuario)
      .toList()
    ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

  void _esProveedor(Usuario u, Solicitud s) {
    if (s.proveedorId != u.idUsuario) {
      throw const ErrorRegla('Esa solicitud no es para ti');
    }
  }

  void _esOrganizador(Usuario u, Solicitud s) {
    if (s.organizadorId != u.idUsuario) {
      throw const ErrorRegla('Esa solicitud no es tuya');
    }
  }

  /// El proveedor manda (o actualiza) su cotización. Cada cambio guarda una
  /// versión nueva; las anteriores quedan en el historial.
  void cotizar(Usuario prov, Solicitud s, Dinero precio, String comentarios,
      {int diasVigencia = 7}) {
    _esProveedor(prov, s);
    if (!s.estado.abierta) {
      throw const ErrorRegla('La solicitud ya está cerrada');
    }
    if (!precio.esPositivo) throw const ErrorRegla('El precio debe ser mayor a 0');
    final ahora = _reloj();
    s.cotizaciones.add(Cotizacion(
      version: s.cotizaciones.length + 1,
      precio: precio,
      comentarios: comentarios.trim(),
      fecha: ahora,
      vigenciaHasta: ahora.add(Duration(days: diasVigencia)),
    ));
    s.estado = EstadoSolicitud.cotizada;
  }

  void rechazarComoProveedor(Usuario prov, Solicitud s, String motivo) {
    _esProveedor(prov, s);
    if (!s.estado.abierta) {
      throw const ErrorRegla('La solicitud ya está cerrada');
    }
    s
      ..estado = EstadoSolicitud.rechazada
      ..motivoRechazo = motivo.trim().isEmpty ? null : motivo.trim();
  }

  /// El organizador confirma la cotización: se registra como gasto de la
  /// fiesta para el presupuesto.
  void aceptarCotizacion(Usuario org, Solicitud s) {
    _esOrganizador(org, s);
    final c = s.cotizacionVigente;
    if (s.estado != EstadoSolicitud.cotizada || c == null) {
      throw const ErrorRegla('Todavía no hay cotización para aceptar');
    }
    if (_reloj().isAfter(c.vigenciaHasta)) {
      throw const ErrorRegla('La cotización ya venció; pide una nueva');
    }
    c.respuesta = RespuestaCotizacion.aceptada;
    s.estado = EstadoSolicitud.aceptada;
    final serv = _repo.servicio(s.servicioId)!;
    _repo.gastos.add(Gasto(
      idGasto: _repo.nuevoId(),
      partyId: s.partyId,
      concepto: '${serv.nombre} (servicio aceptado)',
      monto: c.precio,
      fecha: _reloj(),
      solicitudId: s.idSolicitud,
    ));
  }

  void rechazarCotizacion(Usuario org, Solicitud s) {
    _esOrganizador(org, s);
    final c = s.cotizacionVigente;
    if (s.estado != EstadoSolicitud.cotizada || c == null) {
      throw const ErrorRegla('Todavía no hay cotización para rechazar');
    }
    c.respuesta = RespuestaCotizacion.rechazada;
    s.estado = EstadoSolicitud.rechazada;
  }

  void cancelar(Usuario org, Solicitud s) {
    _esOrganizador(org, s);
    if (!s.estado.abierta) {
      throw const ErrorRegla('Solo se cancela una solicitud abierta');
    }
    s.estado = EstadoSolicitud.cancelada;
  }
}

// ---------------------------------------------------------------------------
// Presupuesto.
// ---------------------------------------------------------------------------
class ResumenPresupuesto {
  const ResumenPresupuesto({
    required this.presupuesto,
    required this.servicios,
    required this.otrosGastos,
    required this.recaudado,
  });

  final Dinero presupuesto;
  final Dinero servicios;
  final Dinero otrosGastos;
  final Dinero recaudado;

  Dinero get gastado => servicios + otrosGastos;
  Dinero get restante => presupuesto - gastado;
  Dinero get balance => recaudado - gastado;
}

class ServicioPresupuesto {
  ServicioPresupuesto(this._repo, this._boletos, this._reloj);
  final Repositorio _repo;
  final ServicioBoletos _boletos;
  final Reloj _reloj;

  List<Gasto> gastosDe(Party p) =>
      _repo.gastos.where((g) => g.partyId == p.idParty).toList();

  ResumenPresupuesto resumen(Party p) {
    final gastos = gastosDe(p);
    final servicios = gastos
        .where((g) => g.solicitudId != null)
        .fold(Dinero.cero, (s, g) => s + g.monto);
    final otros = gastos
        .where((g) => g.solicitudId == null)
        .fold(Dinero.cero, (s, g) => s + g.monto);
    return ResumenPresupuesto(
      presupuesto: p.presupuesto,
      servicios: servicios,
      otrosGastos: otros,
      recaudado: _boletos.recaudado(p),
    );
  }

  void agregarGasto(Usuario u, Party p, String concepto, Dinero monto) {
    if (p.organizadorId != u.idUsuario) {
      throw const ErrorRegla('Solo el organizador registra gastos');
    }
    if (!monto.esPositivo) throw const ErrorRegla('El monto debe ser mayor a 0');
    _repo.gastos.add(Gasto(
      idGasto: _repo.nuevoId(),
      partyId: p.idParty,
      concepto: concepto.trim(),
      monto: monto,
      fecha: _reloj(),
    ));
  }
}
