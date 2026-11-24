import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';
import 'boletos_vendidos_page.dart';
import 'detalle_fiesta_page.dart';
import 'formulario_party.dart';
import 'inicio_page.dart';
import 'presupuesto_page.dart';
import 'servicios_pages.dart';
import 'solicitudes_pages.dart';

// Dashboard del organizador. Navegación mínima del documento:
// Inicio, Mis fiestas, Boletos, Servicios y solicitudes, Presupuesto
// (el perfil está en el botón con su nombre, arriba a la derecha).
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
            label: 'Inicio'),
        NavigationDestination(
            icon: Icon(Icons.celebration_outlined),
            selectedIcon: Icon(Icons.celebration),
            label: 'Mis fiestas'),
        NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Boletos'),
        NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Servicios'),
        NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Presupuesto'),
      ],
      paginas: const [
        ResumenOrganizador(),
        MisFiestas(),
        BoletosOrganizador(),
        ServiciosOrganizador(),
        PresupuestoOrganizador(),
      ],
      botonFlotante: (indice) {
        if (indice != 1) return null;
        return FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FormularioParty()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nueva fiesta'),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Inicio: fiestas, boletos vendidos contra invitados esperados, presupuesto
// contra gastos, solicitudes pendientes e ingresos.
// ---------------------------------------------------------------------------
class ResumenOrganizador extends StatelessWidget {
  const ResumenOrganizador({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mis = app.fiestas.delOrganizador(app.yo);
    final activas =
        mis.where((p) => p.estado != EstadoParty.cancelada).toList();
    final vendidos =
        activas.fold<int>(0, (s, p) => s + app.boletos.vendidos(p));
    final esperados =
        activas.fold<int>(0, (s, p) => s + p.invitadosEsperados);
    var presupuesto = Dinero.cero, gastado = Dinero.cero, ingresos = Dinero.cero;
    for (final p in activas) {
      final r = app.presupuesto.resumen(p);
      presupuesto += r.presupuesto;
      gastado += r.gastado;
      ingresos += r.recaudado;
    }
    final solicitudes = app.solicitudes.delOrganizador(app.yo);
    final abiertas = solicitudes.where((s) => s.estado.abierta).length;
    final porResponder =
        solicitudes.where((s) => s.estado == EstadoSolicitud.cotizada).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Imagen('assets/images/equipo.jpg', alto: 130),
        const SizedBox(height: 12),
        Text('Hola, ${app.yo.nombre}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Text('Así va la organización de tus fiestas.'),
        const SizedBox(height: 12),
        ParEstadisticas(
          Estadistica(
              icono: Icons.celebration,
              valor: '${activas.length}',
              etiqueta: 'Fiestas activas'),
          Estadistica(
              icono: Icons.pending_actions,
              valor: '$abiertas',
              etiqueta: 'Solicitudes abiertas'),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Boletos vendidos vs. invitados esperados'),
                const SizedBox(height: 8),
                Progreso(
                    valor: vendidos,
                    total: esperados,
                    texto: '$vendidos de $esperados invitados esperados'),
                const SizedBox(height: 16),
                const Text('Gastos vs. presupuesto'),
                const SizedBox(height: 8),
                Progreso(
                    valor: gastado.centavos,
                    total: presupuesto.centavos,
                    texto:
                        '${dinero(gastado)} de ${dinero(presupuesto)} usados'),
              ],
            ),
          ),
        ),
        ParEstadisticas(
          Estadistica(
              icono: Icons.attach_money,
              valor: dinero(ingresos),
              etiqueta: 'Ingresos por boletos'),
          Estadistica(
              icono: Icons.shopping_cart,
              valor: dinero(gastado),
              etiqueta: 'Gastado'),
        ),
        TituloSeccion('Cotizaciones por responder (${porResponder.length})'),
        if (porResponder.isEmpty)
          const Text('No tienes cotizaciones pendientes de respuesta.')
        else
          for (final s in porResponder) TarjetaSolicitud(solicitud: s),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de mis fiestas con filtros por fecha y estado.
// ---------------------------------------------------------------------------
class MisFiestas extends StatefulWidget {
  const MisFiestas({super.key});

  @override
  State<MisFiestas> createState() => _MisFiestasState();
}

enum _Cuando { todas, proximas, pasadas }

class _MisFiestasState extends State<MisFiestas> {
  EstadoParty? _estado;
  _Cuando _cuando = _Cuando.todas;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final ahora = app.reloj();
    final todas = app.fiestas.delOrganizador(app.yo);
    final lista = todas.where((p) {
      if (_estado != null && p.estado != _estado) return false;
      if (_cuando == _Cuando.proximas && p.fechaHoraInicio.isBefore(ahora)) {
        return false;
      }
      if (_cuando == _Cuando.pasadas && !p.fechaHoraInicio.isBefore(ahora)) {
        return false;
      }
      return true;
    }).toList();

    if (todas.isEmpty) {
      return const EstadoVacio(
        icono: Icons.celebration_outlined,
        titulo: 'No hay fiestas',
        mensaje: 'Todavía no creas ninguna. Toca "Nueva fiesta" para empezar.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final e in [null, ...EstadoParty.values])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e?.nombre ?? 'Todas'),
                  selected: _estado == e,
                  onSelected: (_) => setState(() => _estado = e),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        SegmentedButton<_Cuando>(
          segments: const [
            ButtonSegment(value: _Cuando.todas, label: Text('Todas')),
            ButtonSegment(value: _Cuando.proximas, label: Text('Próximas')),
            ButtonSegment(value: _Cuando.pasadas, label: Text('Pasadas')),
          ],
          selected: {_cuando},
          onSelectionChanged: (s) => setState(() => _cuando = s.first),
        ),
        const SizedBox(height: 12),
        if (lista.isEmpty)
          const SizedBox(
            height: 260,
            child: EstadoVacio(
                icono: Icons.filter_alt_off,
                titulo: 'Sin resultados',
                mensaje: 'No hay fiestas con esos filtros.'),
          ),
        for (final p in lista) TarjetaFiestaOrganizador(party: p),
      ],
    );
  }
}

class TarjetaFiestaOrganizador extends StatelessWidget {
  const TarjetaFiestaOrganizador({super.key, required this.party, this.destino});

  final Party party;
  final Widget Function(Party)? destino;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = party;
    final vendidos = app.boletos.vendidos(p);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                destino?.call(p) ?? DetalleFiestaPage(partyId: p.idParty))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(p.nombre,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                ChipEstado.party(p.estado),
              ]),
              const SizedBox(height: 8),
              Dato(Icons.event, horario(p.fechaHoraInicio, p.fechaHoraFin)),
              Dato(Icons.place, p.lugar.publico),
              const SizedBox(height: 8),
              Progreso(
                  valor: vendidos,
                  total: p.aforoMaximo,
                  texto: '$vendidos de ${p.aforoMaximo} boletos vendidos'),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Boletos: el organizador elige una fiesta para ver sus boletos vendidos.
// ---------------------------------------------------------------------------
class BoletosOrganizador extends StatelessWidget {
  const BoletosOrganizador({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mis = app.fiestas
        .delOrganizador(app.yo)
        .where((p) => p.estado != EstadoParty.borrador)
        .toList();
    if (mis.isEmpty) {
      return const EstadoVacio(
          icono: Icons.confirmation_number_outlined,
          titulo: 'Sin boletos',
          mensaje: 'Publica una fiesta para empezar a vender boletos.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Elige una fiesta para ver a sus asistentes y validar la '
            'entrada.'),
        const SizedBox(height: 8),
        for (final p in mis)
          TarjetaFiestaOrganizador(
              party: p,
              destino: (p) => BoletosVendidosPage(partyId: p.idParty)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Servicios y solicitudes: catálogo y "Mis solicitudes".
// ---------------------------------------------------------------------------
class ServiciosOrganizador extends StatefulWidget {
  const ServiciosOrganizador({super.key});

  @override
  State<ServiciosOrganizador> createState() => _ServiciosOrganizadorState();
}

class _ServiciosOrganizadorState extends State<ServiciosOrganizador> {
  int _vista = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.storefront),
                  label: Text('Catálogo')),
              ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.send),
                  label: Text('Mis solicitudes')),
            ],
            selected: {_vista},
            onSelectionChanged: (s) => setState(() => _vista = s.first),
          ),
        ),
        Expanded(
          child: _vista == 0
              ? const CatalogoServicios()
              : const ListaSolicitudes(comoProveedor: false),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Presupuesto: resumen por fiesta.
// ---------------------------------------------------------------------------
class PresupuestoOrganizador extends StatelessWidget {
  const PresupuestoOrganizador({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mis = app.fiestas
        .delOrganizador(app.yo)
        .where((p) => p.estado != EstadoParty.cancelada)
        .toList();
    if (mis.isEmpty) {
      return const EstadoVacio(
          icono: Icons.savings_outlined,
          titulo: 'Sin presupuestos',
          mensaje: 'Crea una fiesta para llevar su presupuesto.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final p in mis)
          Builder(builder: (context) {
            final r = app.presupuesto.resumen(p);
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(child: Icon(Icons.savings)),
                title: Text(p.nombre),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Progreso(
                      valor: r.gastado.centavos,
                      total: r.presupuesto.centavos,
                      texto: 'Gastado ${dinero(r.gastado)} de '
                          '${dinero(r.presupuesto)} · Recaudado '
                          '${dinero(r.recaudado)}'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PresupuestoPage(partyId: p.idParty))),
              ),
            );
          }),
      ],
    );
  }
}
