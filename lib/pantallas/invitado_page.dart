import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';
import 'inicio_page.dart';

// Dashboard del invitado: inicio, explorar parties y sus boletos.
class DashboardInvitado extends StatelessWidget {
  const DashboardInvitado({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardBase(
      titulo: 'Invitado',
      destinos: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Explorar',
        ),
        NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          selectedIcon: Icon(Icons.confirmation_number),
          label: 'Mis boletos',
        ),
      ],
      paginas: [
        InicioInvitado(),
        ExplorarParties(),
        MisBoletos(),
      ],
    );
  }
}

class InicioInvitado extends StatelessWidget {
  const InicioInvitado({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final boletos = app.boletosDelUsuario;
    final cantidad = boletos.fold<int>(0, (suma, b) => suma + b.cantidad);
    final gastado = boletos.fold<double>(0, (suma, b) => suma + b.total);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Imagen('assets/images/party.jpg', alto: 150),
        const SizedBox(height: 12),
        Text('Hola, ${app.actual!.nombre}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Text('Encuentra tu próxima fiesta.'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Estadistica(
                icono: Icons.celebration,
                valor: '${app.parties.length}',
                etiqueta: 'Parties disponibles',
              ),
            ),
            Expanded(
              child: Estadistica(
                icono: Icons.confirmation_number,
                valor: '$cantidad',
                etiqueta: 'Mis boletos',
              ),
            ),
          ],
        ),
        Estadistica(
          icono: Icons.attach_money,
          valor: dinero(gastado),
          etiqueta: 'Total gastado en boletos',
        ),
      ],
    );
  }
}

// Lista principal del invitado: todas las parties con boletos a la venta.
class ExplorarParties extends StatelessWidget {
  const ExplorarParties({super.key});

  @override
  Widget build(BuildContext context) {
    final parties = AppScope.of(context).parties;

    if (parties.isEmpty) {
      return const EstadoVacio(
        icono: Icons.celebration_outlined,
        titulo: 'No hay parties',
        mensaje: 'Todavía no hay fiestas publicadas. Vuelve más tarde.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final p in parties)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(child: Icon(Icons.celebration)),
              title: Text(p.nombre),
              subtitle: Text(
                '${p.fecha} · ${p.lugar}\n'
                'Boleto ${dinero(p.precioBoleto)} · '
                '${p.disponibles} disponibles',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetalleParty(party: p)),
              ),
            ),
          ),
      ],
    );
  }
}

// Detalle de la party con el formulario para comprar boletos.
class DetalleParty extends StatefulWidget {
  const DetalleParty({super.key, required this.party});

  final Party party;

  @override
  State<DetalleParty> createState() => _DetallePartyState();
}

class _DetallePartyState extends State<DetalleParty> {
  final _formKey = GlobalKey<FormState>();
  final _asistente = TextEditingController();
  int _cantidad = 1;

  @override
  void dispose() {
    _asistente.dispose();
    super.dispose();
  }

  void _comprar() {
    if (!_formKey.currentState!.validate()) return;
    final p = widget.party;
    if (_cantidad > p.disponibles) {
      mostrarAviso(context, 'Solo quedan ${p.disponibles} boletos');
      return;
    }
    AppScope.leer(context).comprarBoleto(p, _cantidad, _asistente.text.trim());
    mostrarAviso(context, 'Compra lista: $_cantidad boleto(s)');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.party;
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(p.nombre)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Imagen('assets/images/terraza_splash.jpg', alto: 180),
              const SizedBox(height: 12),
              Text(p.nombre,
                  style: tema.textTheme.headlineSmall
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
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 6),
                Text('Organiza: ${p.organizadorNombre}'),
              ]),
              const SizedBox(height: 4),
              Text('Quedan ${p.disponibles} de ${p.invitados} boletos'),
              const TituloSeccion('Comprar boletos'),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _asistente,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del asistente',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => obligatorio(v, 'el nombre'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Cantidad'),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: _cantidad > 1
                              ? () => setState(() => _cantidad--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$_cantidad',
                              style: tema.textTheme.titleLarge),
                        ),
                        IconButton.filledTonal(
                          onPressed: _cantidad < p.disponibles
                              ? () => setState(() => _cantidad++)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Total: ${dinero(_cantidad * p.precioBoleto)}',
                        style: tema.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: p.disponibles > 0 ? _comprar : null,
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(p.disponibles > 0
                          ? 'Comprar boletos'
                          : 'Boletos agotados'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Lista secundaria: los boletos que compró el invitado.
class MisBoletos extends StatelessWidget {
  const MisBoletos({super.key});

  @override
  Widget build(BuildContext context) {
    final boletos = AppScope.of(context).boletosDelUsuario;

    if (boletos.isEmpty) {
      return const EstadoVacio(
        icono: Icons.confirmation_number_outlined,
        titulo: 'No hay boletos',
        mensaje: 'Todavía no compras ninguno. Ve a Explorar para elegir una '
            'fiesta.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final b in boletos)
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.confirmation_number),
              ),
              title: Text(b.party.nombre),
              subtitle: Text(
                '${b.cantidad} boleto(s) a nombre de ${b.asistente}\n'
                '${b.party.fecha} · ${b.party.lugar}',
              ),
              isThreeLine: true,
              trailing: Text(dinero(b.total),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}
