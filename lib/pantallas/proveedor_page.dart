import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';
import 'formulario_servicio.dart';
import 'inicio_page.dart';
import 'perfil_page.dart';
import 'servicios_pages.dart';
import 'solicitudes_pages.dart';

// Dashboard del proveedor. Navegación mínima del documento:
// Inicio, Mis servicios, Solicitudes y cotizaciones, Perfil.
class DashboardProveedor extends StatelessWidget {
  const DashboardProveedor({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardBase(
      titulo: 'Proveedor',
      destinos: const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio'),
        NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Mis servicios'),
        NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Solicitudes'),
        NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil'),
      ],
      paginas: const [
        ResumenProveedor(),
        MisServicios(),
        ListaSolicitudes(comoProveedor: true),
        PerfilPage(comoPestana: true),
      ],
      botonFlotante: (indice) {
        if (indice != 1) return null;
        return FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FormularioServicio()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo servicio'),
        );
      },
    );
  }
}

// Inicio: solicitudes nuevas, cotizaciones pendientes, servicios publicados y
// cotizaciones aceptadas.
class ResumenProveedor extends StatelessWidget {
  const ResumenProveedor({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final solicitudes = app.solicitudes.delProveedor(app.yo);
    final nuevas =
        solicitudes.where((s) => s.estado == EstadoSolicitud.pendiente).toList();
    final cotizadas =
        solicitudes.where((s) => s.estado == EstadoSolicitud.cotizada).length;
    final aceptadas =
        solicitudes.where((s) => s.estado == EstadoSolicitud.aceptada).toList();
    final ingresos = aceptadas.fold(
        Dinero.cero, (s, x) => s + (x.cotizacionVigente?.precio ?? Dinero.cero));
    final publicados =
        app.catalogo.delProveedor(app.yo).where((s) => s.activo).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Imagen('assets/images/quinta_pinos.jpg', alto: 130),
        const SizedBox(height: 12),
        Text('Hola, ${app.yo.nombreNegocio ?? app.yo.nombre}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Text('Administra tus servicios y tus cotizaciones.'),
        const SizedBox(height: 12),
        ParEstadisticas(
          Estadistica(
              icono: Icons.mark_email_unread,
              valor: '${nuevas.length}',
              etiqueta: 'Solicitudes nuevas'),
          Estadistica(
              icono: Icons.request_quote,
              valor: '$cotizadas',
              etiqueta: 'Cotizaciones sin respuesta'),
        ),
        ParEstadisticas(
          Estadistica(
              icono: Icons.storefront,
              valor: '$publicados',
              etiqueta: 'Servicios publicados'),
          Estadistica(
              icono: Icons.check_circle,
              valor: '${aceptadas.length}',
              etiqueta: 'Cotizaciones aceptadas'),
        ),
        Estadistica(
            icono: Icons.attach_money,
            valor: dinero(ingresos),
            etiqueta: 'Ingresos por cotizaciones aceptadas'),
        TituloSeccion('Por responder (${nuevas.length})'),
        if (nuevas.isEmpty)
          const Text('No tienes solicitudes nuevas.')
        else
          for (final s in nuevas) TarjetaSolicitud(solicitud: s),
      ],
    );
  }
}

// Mis servicios: editar, marcar disponibilidad y desactivar (baja lógica).
class MisServicios extends StatelessWidget {
  const MisServicios({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lista = app.catalogo.delProveedor(app.yo);

    if (lista.isEmpty) {
      return const EstadoVacio(
        icono: Icons.storefront_outlined,
        titulo: 'No hay servicios',
        mensaje: 'Todavía no publicas ninguno. Toca "Nuevo servicio".',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        const Text('Los servicios no se borran: se desactivan para conservar '
            'el historial de solicitudes.'),
        const SizedBox(height: 8),
        for (final s in lista)
          TarjetaServicio(
            servicio: s,
            acciones: Row(children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FormularioServicio(servicio: s))),
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
              ),
              const Spacer(),
              Text(s.activo ? 'Activo' : 'Desactivado'),
              Switch(
                value: s.activo,
                onChanged: (v) => resultado(
                    context,
                    app.hacer(() => app.catalogo.cambiarActivo(app.yo, s, v)),
                    exito: v ? 'Servicio activado' : 'Servicio desactivado'),
              ),
            ]),
          ),
      ],
    );
  }
}
