import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';
import 'formulario_party.dart';
import 'inicio_page.dart';

// Dashboard del organizador: resumen, sus parties y servicios para contratar.
class DashboardOrganizador extends StatelessWidget {
  const DashboardOrganizador({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardBase(
      titulo: 'Organizador',
      destinos: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Resumen',
        ),
        NavigationDestination(
          icon: Icon(Icons.celebration_outlined),
          selectedIcon: Icon(Icons.celebration),
          label: 'Mis parties',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Servicios',
        ),
      ],
      paginas: const [
        ResumenOrganizador(),
        PartiesOrganizador(),
        ServiciosParaOrganizador(),
      ],
      // El botón de nueva party solo aparece en la pestaña "Mis parties".
      botonFlotante: (indice) {
        if (indice != 1) return null;
        return FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FormularioParty()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nueva party'),
        );
      },
    );
  }
}

class ResumenOrganizador extends StatelessWidget {
  const ResumenOrganizador({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mis = app.partiesDelOrganizador;
    final vendidos = mis.fold<int>(0, (suma, p) => suma + p.vendidos);
    final ingresos =
        mis.fold<double>(0, (suma, p) => suma + p.vendidos * p.precioBoleto);
    final solicitudes = app.solicitudesDelOrganizador;
    final gasto = solicitudes
        .where((s) => s.estado == 'Aceptada')
        .fold<double>(0, (suma, s) => suma + s.servicio.precio);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Imagen('assets/images/equipo.jpg', alto: 150),
        const SizedBox(height: 12),
        Text('Hola, ${app.actual!.nombre}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Text('Así va la organización de tus fiestas.'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Estadistica(
                icono: Icons.celebration,
                valor: '${mis.length}',
                etiqueta: 'Parties',
              ),
            ),
            Expanded(
              child: Estadistica(
                icono: Icons.confirmation_number,
                valor: '$vendidos',
                etiqueta: 'Boletos vendidos',
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Estadistica(
                icono: Icons.attach_money,
                valor: dinero(ingresos),
                etiqueta: 'Ingresos por boletos',
              ),
            ),
            Expanded(
              child: Estadistica(
                icono: Icons.shopping_cart,
                valor: dinero(gasto),
                etiqueta: 'Servicios contratados',
              ),
            ),
          ],
        ),
        const TituloSeccion('Mis solicitudes'),
        if (solicitudes.isEmpty)
          const Text('Todavía no has pedido servicios. Ve a la pestaña '
              'Servicios para cotizar.')
        else
          for (final s in solicitudes)
            Card(
              child: ListTile(
                leading: const Icon(Icons.send),
                title: Text(s.servicio.nombre),
                subtitle: Text('Para: ${s.party.nombre}'),
                trailing: Chip(label: Text(s.estado)),
              ),
            ),
      ],
    );
  }
}

// Lista principal: las parties del organizador.
class PartiesOrganizador extends StatelessWidget {
  const PartiesOrganizador({super.key});

  @override
  Widget build(BuildContext context) {
    final mis = AppScope.of(context).partiesDelOrganizador;

    // Estado vacío cuando todavía no hay parties.
    if (mis.isEmpty) {
      return const EstadoVacio(
        icono: Icons.celebration_outlined,
        titulo: 'No hay parties',
        mensaje: 'Todavía no creas ninguna. Toca "Nueva party" para empezar.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        for (final p in mis)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nombre,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.event, size: 18),
                    const SizedBox(width: 6),
                    Text(p.fecha),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.place, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(p.lugar)),
                  ]),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: p.vendidos / p.invitados),
                  const SizedBox(height: 6),
                  Text('${p.vendidos} de ${p.invitados} boletos vendidos'),
                  const SizedBox(height: 4),
                  Text(
                    'Boleto: ${dinero(p.precioBoleto)} · '
                    'Presupuesto: ${dinero(p.presupuesto)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Lista secundaria: servicios que ofrecen los proveedores.
class ServiciosParaOrganizador extends StatefulWidget {
  const ServiciosParaOrganizador({super.key});

  @override
  State<ServiciosParaOrganizador> createState() =>
      _ServiciosParaOrganizadorState();
}

class _ServiciosParaOrganizadorState extends State<ServiciosParaOrganizador> {
  String _filtro = 'Todos';

  Future<void> _solicitar(Servicio servicio) async {
    final app = AppScope.leer(context);
    final mis = app.partiesDelOrganizador;
    if (mis.isEmpty) {
      mostrarAviso(context, 'Primero crea una party para poder cotizar');
      return;
    }
    // Se elige para cuál party es el servicio.
    final party = await showModalBottomSheet<Party>(
      context: context,
      builder: (contextoHoja) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('¿Para qué party?',
                  style: Theme.of(contextoHoja).textTheme.titleLarge),
            ),
            for (final p in mis)
              ListTile(
                leading: const Icon(Icons.celebration),
                title: Text(p.nombre),
                subtitle: Text(p.fecha),
                onTap: () => Navigator.of(contextoHoja).pop(p),
              ),
          ],
        ),
      ),
    );
    if (party == null || !mounted) return;
    mostrarAviso(context, app.solicitarServicio(servicio, party));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lista = app.servicios
        .where((s) => _filtro == 'Todos' || s.tipo == _filtro)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final f in const ['Todos', 'Salón', 'Alberca', 'DJ'])
              ChoiceChip(
                label: Text(f),
                selected: _filtro == f,
                onSelected: (_) => setState(() => _filtro = f),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (lista.isEmpty)
          const SizedBox(
            height: 300,
            child: EstadoVacio(
              icono: Icons.search_off,
              titulo: 'No hay servicios',
              mensaje: 'No hay servicios de este tipo por ahora.',
            ),
          ),
        for (final s in lista)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  s.imagen,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const SizedBox(
                    height: 140,
                    child: Center(child: Icon(Icons.celebration, size: 40)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${s.nombre} · ${s.tipo}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(s.descripcion),
                      const SizedBox(height: 4),
                      Text('Proveedor: ${s.proveedorNombre}',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(dinero(s.precio),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              )),
                          const Spacer(),
                          FilledButton.tonal(
                            onPressed: () => _solicitar(s),
                            child: const Text('Cotizar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
