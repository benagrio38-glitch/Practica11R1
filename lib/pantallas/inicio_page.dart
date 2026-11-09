import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import 'invitado_page.dart';
import 'login_page.dart';
import 'organizador_page.dart';
import 'proveedor_page.dart';

// Revisa el rol del usuario y muestra su dashboard.
class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AppScope.leer(context).actual!;
    switch (usuario.rol) {
      case Rol.organizador:
        return const DashboardOrganizador();
      case Rol.invitado:
        return const DashboardInvitado();
      case Rol.proveedor:
        return const DashboardProveedor();
    }
  }
}

// Estructura que comparten los tres dashboards: barra de arriba, barra de
// navegación abajo y un botón flotante opcional.
class DashboardBase extends StatefulWidget {
  const DashboardBase({
    super.key,
    required this.titulo,
    required this.destinos,
    required this.paginas,
    this.botonFlotante,
  });

  final String titulo;
  final List<NavigationDestination> destinos;
  final List<Widget> paginas;
  final Widget? Function(int indice)? botonFlotante;

  @override
  State<DashboardBase> createState() => _DashboardBaseState();
}

class _DashboardBaseState extends State<DashboardBase> {
  int _indice = 0;

  void _salir() {
    // Primero se navega y después se limpia la sesión.
    final estado = AppScope.leer(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (ruta) => false,
    );
    estado.cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AppScope.of(context).actual;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          if (usuario != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(usuario.nombre.split(' ').first),
              ),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _salir,
          ),
        ],
      ),
      // IndexedStack guarda todas las pestañas, así no pierden su estado.
      body: IndexedStack(index: _indice, children: widget.paginas),
      floatingActionButton: widget.botonFlotante?.call(_indice),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: widget.destinos,
      ),
    );
  }
}
