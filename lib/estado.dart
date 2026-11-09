import 'package:flutter/material.dart';

import 'modelos.dart';

// Manejo de estado: una clase ChangeNotifier que guarda todos los datos de
// la app. Cuando algo cambia se llama notifyListeners() y las pantallas que
// dependen de AppScope se redibujan solas. Como el objeto vive arriba de
// todas las pantallas, el estado (rol, datos, listas) no se pierde al navegar.
class AppState extends ChangeNotifier {
  final List<Usuario> usuarios = [
    const Usuario(
      nombre: 'Ana Organizadora',
      correo: 'organizador@recuparty.com',
      clave: '123456',
      rol: Rol.organizador,
    ),
    const Usuario(
      nombre: 'Pepe Invitado',
      correo: 'invitado@recuparty.com',
      clave: '123456',
      rol: Rol.invitado,
    ),
    const Usuario(
      nombre: 'Luis Proveedor',
      correo: 'proveedor@recuparty.com',
      clave: '123456',
      rol: Rol.proveedor,
    ),
  ];

  Usuario? actual;

  final List<Party> parties = [
    Party(
      id: 1,
      nombre: 'Fiesta de recuperación',
      fecha: '14/11/2026',
      lugar: 'Salón La Terraza',
      invitados: 80,
      presupuesto: 12000,
      precioBoleto: 120,
      organizador: 'organizador@recuparty.com',
      organizadorNombre: 'Ana Organizadora',
      vendidos: 18,
    ),
    Party(
      id: 2,
      nombre: 'Pool party fin de cuatri',
      fecha: '22/11/2026',
      lugar: 'Alberca Sol',
      invitados: 50,
      presupuesto: 8000,
      precioBoleto: 150,
      organizador: 'organizador@recuparty.com',
      organizadorNombre: 'Ana Organizadora',
    ),
  ];

  final List<Servicio> servicios = [
    const Servicio(
      id: 1,
      nombre: 'Salón La Terraza',
      tipo: 'Salón',
      precio: 3500,
      descripcion: 'Para 80 personas, con pista de baile y estacionamiento.',
      proveedor: 'proveedor@recuparty.com',
      proveedorNombre: 'Luis Proveedor',
      imagen: 'assets/images/salon_terraza.jpg',
    ),
    const Servicio(
      id: 2,
      nombre: 'Alberca Sol',
      tipo: 'Alberca',
      precio: 2800,
      descripcion: 'Alberca con asadores y mesas para 50 personas.',
      proveedor: 'proveedor@recuparty.com',
      proveedorNombre: 'Luis Proveedor',
      imagen: 'assets/images/alberca_sol.jpg',
    ),
    const Servicio(
      id: 3,
      nombre: 'DJ Nova',
      tipo: 'DJ',
      precio: 2000,
      descripcion: 'Cuatro horas de música con luces y sonido.',
      proveedor: 'proveedor@recuparty.com',
      proveedorNombre: 'Luis Proveedor',
      imagen: 'assets/images/dj_nova.jpg',
    ),
  ];

  final List<Boleto> boletos = [];
  final List<Solicitud> solicitudes = [];

  int _siguienteId = 100;
  int get _nuevoId => _siguienteId++;

  // ---------- Sesión ----------

  // Regresa null si todo salió bien, o el texto del error.
  String? iniciarSesion(String correo, String clave) {
    final c = correo.trim().toLowerCase();
    for (final u in usuarios) {
      if (u.correo == c && u.clave == clave) {
        actual = u;
        notifyListeners();
        return null;
      }
    }
    return 'Correo o contraseña incorrectos';
  }

  String? registrar(String nombre, String correo, String clave, Rol rol) {
    final c = correo.trim().toLowerCase();
    if (usuarios.any((u) => u.correo == c)) {
      return 'Ese correo ya está registrado';
    }
    final nuevo =
        Usuario(nombre: nombre.trim(), correo: c, clave: clave, rol: rol);
    usuarios.add(nuevo);
    actual = nuevo;
    notifyListeners();
    return null;
  }

  // No avisa a los listeners a propósito: la pantalla se cierra justo después.
  void cerrarSesion() {
    actual = null;
  }

  // ---------- Organizador ----------

  List<Party> get partiesDelOrganizador =>
      parties.where((p) => p.organizador == actual!.correo).toList();

  List<Solicitud> get solicitudesDelOrganizador => solicitudes
      .where((s) => s.party.organizador == actual!.correo)
      .toList();

  void crearParty({
    required String nombre,
    required String fecha,
    required String lugar,
    required int invitados,
    required double presupuesto,
    required double precioBoleto,
  }) {
    parties.add(Party(
      id: _nuevoId,
      nombre: nombre,
      fecha: fecha,
      lugar: lugar,
      invitados: invitados,
      presupuesto: presupuesto,
      precioBoleto: precioBoleto,
      organizador: actual!.correo,
      organizadorNombre: actual!.nombre,
    ));
    notifyListeners();
  }

  bool yaSolicitado(Servicio s, Party p) =>
      solicitudes.any((x) => x.servicio.id == s.id && x.party.id == p.id);

  String solicitarServicio(Servicio s, Party p) {
    if (yaSolicitado(s, p)) {
      return 'Ya solicitaste ${s.nombre} para ${p.nombre}';
    }
    solicitudes.add(Solicitud(id: _nuevoId, servicio: s, party: p));
    notifyListeners();
    return 'Solicitud enviada a ${s.proveedorNombre}';
  }

  // ---------- Invitado ----------

  List<Boleto> get boletosDelUsuario =>
      boletos.where((b) => b.comprador == actual!.correo).toList();

  void comprarBoleto(Party p, int cantidad, String asistente) {
    p.vendidos += cantidad;
    boletos.add(Boleto(
      id: _nuevoId,
      party: p,
      cantidad: cantidad,
      asistente: asistente,
      comprador: actual!.correo,
    ));
    notifyListeners();
  }

  // ---------- Proveedor ----------

  List<Servicio> get serviciosDelProveedor =>
      servicios.where((s) => s.proveedor == actual!.correo).toList();

  List<Solicitud> get solicitudesDelProveedor => solicitudes
      .where((s) => s.servicio.proveedor == actual!.correo)
      .toList();

  void agregarServicio({
    required String nombre,
    required String tipo,
    required double precio,
    required String descripcion,
  }) {
    final imagen = tipo == 'Salón'
        ? 'assets/images/salon_luna.jpg'
        : tipo == 'Alberca'
            ? 'assets/images/alberca_oasis.jpg'
            : 'assets/images/dj_kora.jpg';
    servicios.add(Servicio(
      id: _nuevoId,
      nombre: nombre,
      tipo: tipo,
      precio: precio,
      descripcion: descripcion,
      proveedor: actual!.correo,
      proveedorNombre: actual!.nombre,
      imagen: imagen,
    ));
    notifyListeners();
  }

  void eliminarServicio(Servicio s) {
    servicios.remove(s);
    solicitudes.removeWhere((x) => x.servicio.id == s.id);
    notifyListeners();
  }

  void responderSolicitud(Solicitud s, String estado) {
    s.estado = estado;
    notifyListeners();
  }
}

// Reparte el AppState a todas las pantallas.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState estado,
    required super.child,
  }) : super(notifier: estado);

  // Con este se redibuja la pantalla cuando el estado cambia.
  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  }

  // Con este solo se lee el estado (para botones y eventos).
  static AppState leer(BuildContext context) {
    return context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
  }
}
