import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';
import 'formulario_servicio.dart';
import 'inicio_page.dart';

// Dashboard del proveedor (salones, albercas y DJs).
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
          label: 'Resumen',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Mis servicios',
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: 'Solicitudes',
        ),
      ],
      paginas: const [
        ResumenProveedor(),
        MisServicios(),
        SolicitudesProveedor(),
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

class ResumenProveedor extends StatelessWidget {
  const ResumenProveedor({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final solicitudes = app.solicitudesDelProveedor;
    final pendientes = solicitudes.where((s) => s.estado == 'Pendiente').length;
    final aceptadas = solicitudes.where((s) => s.estado == 'Aceptada');
    final ingresos =
        aceptadas.fold<double>(0, (suma, s) => suma + s.servicio.precio);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Imagen('assets/images/quinta_pinos.jpg', alto: 150),
        const SizedBox(height: 12),
        Text('Hola, ${app.actual!.nombre}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Text('Administra tus servicios y tus solicitudes.'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Estadistica(
                icono: Icons.storefront,
                valor: '${app.serviciosDelProveedor.length}',
                etiqueta: 'Servicios',
              ),
            ),
            Expanded(
              child: Estadistica(
                icono: Icons.pending_actions,
                valor: '$pendientes',
                etiqueta: 'Pendientes',
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Estadistica(
                icono: Icons.check_circle,
                valor: '${aceptadas.length}',
                etiqueta: 'Aceptadas',
              ),
            ),
            Expanded(
              child: Estadistica(
                icono: Icons.attach_money,
                valor: dinero(ingresos),
                etiqueta: 'Ingresos',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Lista principal: los servicios que ofrece el proveedor.
class MisServicios extends StatelessWidget {
  const MisServicios({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lista = app.serviciosDelProveedor;

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
        for (final s in lista)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  s.imagen,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const SizedBox(
                    height: 120,
                    child: Center(child: Icon(Icons.celebration, size: 40)),
                  ),
                ),
                ListTile(
                  title: Text('${s.nombre} · ${s.tipo}'),
                  subtitle: Text('${s.descripcion}\n${dinero(s.precio)}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      app.eliminarServicio(s);
                      mostrarAviso(context, 'Servicio eliminado');
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Lista secundaria: solicitudes que mandan los organizadores.
class SolicitudesProveedor extends StatelessWidget {
  const SolicitudesProveedor({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lista = app.solicitudesDelProveedor;

    if (lista.isEmpty) {
      return const EstadoVacio(
        icono: Icons.inbox_outlined,
        titulo: 'No hay solicitudes',
        mensaje: 'Cuando un organizador te cotice, aparecerá aquí.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final Solicitud s in lista)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.servicio.nombre,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Chip(label: Text(s.estado)),
                    ],
                  ),
                  Text('Party: ${s.party.nombre} (${s.party.fecha})'),
                  Text('Organiza: ${s.party.organizadorNombre}'),
                  Text('Precio: ${dinero(s.servicio.precio)}'),
                  if (s.estado == 'Pendiente') ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              app.responderSolicitud(s, 'Rechazada'),
                          child: const Text('Rechazar'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () =>
                              app.responderSolicitud(s, 'Aceptada'),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
