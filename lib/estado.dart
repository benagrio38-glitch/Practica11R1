import 'package:flutter/material.dart';

import 'modelos.dart';
import 'repositorio.dart';
import 'seguridad.dart';
import 'servicios_app.dart';

// Manejo de estado: una clase ChangeNotifier que reúne el repositorio y los
// servicios de aplicación. Cuando algo cambia se llama notifyListeners() y las
// pantallas que dependen de AppScope se redibujan solas. Como el objeto vive
// arriba de todas las pantallas, la sesión y los datos no se pierden al navegar.
class AppState extends ChangeNotifier {
  AppState({Reloj? reloj, Seguridad? seguridad, bool conEjemplo = true})
      : reloj = reloj ?? DateTime.now,
        seguridad = seguridad ?? Seguridad(),
        repo = Repositorio() {
    cuentas = ServicioCuentas(repo, this.seguridad, this.reloj);
    fiestas = ServicioFiestas(repo, this.reloj);
    boletos = ServicioBoletos(repo, this.seguridad, this.reloj);
    catalogo = ServicioCatalogo(repo);
    solicitudes = ServicioSolicitudes(repo, this.reloj);
    presupuesto = ServicioPresupuesto(repo, boletos, this.reloj);
    if (conEjemplo) repo.cargarEjemplo(this.seguridad, this.reloj());
  }

  final Reloj reloj;
  final Seguridad seguridad;
  final Repositorio repo;
  late final ServicioCuentas cuentas;
  late final ServicioFiestas fiestas;
  late final ServicioBoletos boletos;
  late final ServicioCatalogo catalogo;
  late final ServicioSolicitudes solicitudes;
  late final ServicioPresupuesto presupuesto;

  // Sesión activa (el splash la revisa para saber a dónde mandar).
  Usuario? actual;

  /// Ejecuta una operación de los servicios. Si una regla no se cumple
  /// regresa el mensaje de error; si todo sale bien redibuja y regresa null.
  String? hacer(void Function() operacion) {
    try {
      operacion();
    } on ErrorRegla catch (e) {
      return e.mensaje;
    }
    notifyListeners();
    return null;
  }

  // ---------- Sesión ----------

  String? iniciarSesion(String correo, String clave) =>
      hacer(() => actual = cuentas.iniciarSesion(correo, clave));

  String? registrar(String nombre, String correo, String clave, Rol rol) =>
      hacer(() => actual = cuentas.registrar(
          nombre: nombre, correo: correo, clave: clave, rol: rol));

  // No avisa a los listeners a propósito: la pantalla se cierra justo después.
  void cerrarSesion() {
    actual = null;
  }

  // ---------- Consultas que usan varias pantallas ----------

  Usuario get yo => actual!;

  Party? party(int id) => repo.party(id);
  Servicio? servicio(int id) => repo.servicio(id);
  Usuario? usuario(int id) => repo.usuario(id);

  List<Boleto> get misBoletos =>
      repo.boletos.where((b) => b.compradorId == yo.idUsuario).toList();
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
