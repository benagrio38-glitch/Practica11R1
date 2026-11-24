import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';
import 'inicio_page.dart';

// Perfil: editar nombre y correo (y datos de negocio del proveedor), cambiar
// contraseña, cerrar sesión y pedir la eliminación de la cuenta.
class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key, this.comoPestana = false});

  /// true cuando se muestra dentro de la barra de navegación (sin AppBar).
  final bool comoPestana;

  @override
  Widget build(BuildContext context) {
    final cuerpo = const _ContenidoPerfil();
    if (comoPestana) return cuerpo;
    return Scaffold(appBar: AppBar(title: const Text('Mi perfil')), body: cuerpo);
  }
}

class _ContenidoPerfil extends StatefulWidget {
  const _ContenidoPerfil();

  @override
  State<_ContenidoPerfil> createState() => _ContenidoPerfilState();
}

class _ContenidoPerfilState extends State<_ContenidoPerfil> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _correo;
  late final TextEditingController _negocio;
  late final TextEditingController _telefono;

  @override
  void initState() {
    super.initState();
    final u = AppScope.leer(context).yo;
    _nombre = TextEditingController(text: u.nombre);
    _correo = TextEditingController(text: u.correo);
    _negocio = TextEditingController(text: u.nombreNegocio ?? '');
    _telefono = TextEditingController(text: u.telefonoNegocio ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _negocio.dispose();
    _telefono.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final app = AppScope.leer(context);
    final error = app.hacer(() => app.cuentas.actualizarPerfil(app.yo,
        nombre: _nombre.text,
        correo: _correo.text,
        negocio: _negocio.text,
        telefono: _telefono.text));
    resultado(context, error, exito: 'Perfil actualizado');
  }

  Future<void> _cambiarClave() async {
    final actual = TextEditingController();
    final nueva = TextEditingController();
    final llave = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Form(
          key: llave,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: actual,
              obscureText: true,
              decoration: campo('Contraseña actual', Icons.lock_outline),
              validator: validarClave,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nueva,
              obscureText: true,
              decoration: campo('Contraseña nueva', Icons.lock),
              validator: validarClave,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Regresar')),
          FilledButton(
              onPressed: () {
                if (llave.currentState!.validate()) Navigator.of(c).pop(true);
              },
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final app = AppScope.leer(context);
    final error = app.hacer(
        () => app.cuentas.cambiarClave(app.yo, actual.text, nueva.text));
    if (mounted) resultado(context, error, exito: 'Contraseña cambiada');
  }

  Future<void> _eliminarCuenta() async {
    final clave = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar mi cuenta'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Tu cuenta se desactiva y ya no podrás entrar. Las fiestas, '
              'boletos y solicitudes que ya existen se conservan como '
              'historial para las otras personas (por ejemplo, los boletos '
              'que vendiste o las cotizaciones que mandaste), pero ya no se '
              'muestran tus datos de contacto.'),
          const SizedBox(height: 12),
          TextField(
            controller: clave,
            obscureText: true,
            decoration: campo('Escribe tu contraseña', Icons.lock),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Regresar')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(c).colorScheme.error),
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Eliminar cuenta')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final app = AppScope.leer(context);
    final error =
        app.hacer(() => app.cuentas.solicitarEliminacion(app.yo, clave.text));
    if (!mounted || !resultado(context, error)) return;
    cerrarSesionYSalir(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final u = app.yo;
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            child: Text(u.nombre.isEmpty ? '?' : u.nombre[0],
                style: tema.textTheme.headlineMedium),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text(u.rol.nombre, style: tema.textTheme.titleMedium)),
        Center(
            child: Text('Cuenta creada el ${fecha(u.fechaCreacion)}',
                style: tema.textTheme.bodySmall)),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombre,
                decoration: campo('Nombre', Icons.person),
                validator: (v) => obligatorio(v, 'tu nombre'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                decoration: campo('Correo', Icons.email),
                validator: validarCorreo,
              ),
              if (u.rol == Rol.proveedor) ...[
                const TituloSeccion('Datos del negocio'),
                TextFormField(
                  controller: _negocio,
                  decoration: campo('Nombre del negocio', Icons.storefront),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: campo('Teléfono de contacto', Icons.phone),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
        const TituloSeccion('Seguridad'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Cambiar contraseña'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _cambiarClave,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () => cerrarSesionYSalir(context),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: tema.colorScheme.error),
              title: Text('Eliminar mi cuenta',
                  style: TextStyle(color: tema.colorScheme.error)),
              subtitle: const Text('Pide confirmación con tu contraseña'),
              onTap: _eliminarCuenta,
            ),
          ]),
        ),
      ],
    );
  }
}
