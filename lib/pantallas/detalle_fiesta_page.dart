import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';
import 'boletos_vendidos_page.dart';
import 'formulario_party.dart';
import 'presupuesto_page.dart';
import 'solicitudes_pages.dart';

// Detalle de una fiesta para su organizador: boletos vendidos y disponibles,
// servicios solicitados, total recaudado y acciones según el estado.
class DetalleFiestaPage extends StatelessWidget {
  const DetalleFiestaPage({super.key, required this.partyId});

  final int partyId;

  Future<void> _publicar(BuildContext context, Party p) async {
    final ok = await confirmar(context,
        titulo: 'Publicar fiesta',
        mensaje: 'La fiesta se verá en Explorar y empezará la venta de '
            'boletos. El precio ya no podrá cambiar cuando haya ventas.',
        accion: 'Publicar');
    if (!ok || !context.mounted) return;
    final app = AppScope.leer(context);
    resultado(context, app.hacer(() => app.fiestas.publicar(app.yo, p)),
        exito: 'Fiesta publicada');
  }

  Future<void> _cancelar(BuildContext context, Party p, int vendidos) async {
    final ok = await confirmar(context,
        titulo: 'Cancelar fiesta',
        mensaje: 'Política de reembolso: si cancelas, los $vendidos boletos '
            'vendidos se cancelan y a cada comprador se le reembolsa el 100% '
            'de lo que pagó. Las solicitudes de servicio abiertas también se '
            'cancelan. Esto no se puede deshacer.',
        accion: 'Cancelar fiesta',
        peligro: true);
    if (!ok || !context.mounted) return;
    final app = AppScope.leer(context);
    resultado(context, app.hacer(() => app.fiestas.cancelar(app.yo, p)),
        exito: 'Fiesta cancelada y boletos reembolsados');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.party(partyId)!;
    final vendidos = app.boletos.vendidos(p);
    final disponibles = app.boletos.disponibles(p);
    final recaudado = app.boletos.recaudado(p);
    final solicitudes = app.solicitudes
        .delOrganizador(app.yo)
        .where((s) => s.partyId == p.idParty)
        .toList();
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(p.nombre), actions: [
        if (p.sePuedeEditar)
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FormularioParty(party: p))),
          ),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
              child: Text(p.nombre,
                  style: tema.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            ChipEstado.party(p.estado),
          ]),
          if (p.descripcion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(p.descripcion),
          ],
          const SizedBox(height: 8),
          Dato(Icons.event, horario(p.fechaHoraInicio, p.fechaHoraFin)),
          Dato(Icons.place, p.lugar.completo),
          Dato(Icons.no_drinks, 'Edad mínima: ${p.edadMinima} años'),
          Dato(Icons.confirmation_number,
              'Boleto: ${dinero(p.precioBoleto)} · Presupuesto: '
              '${dinero(p.presupuesto)}'),
          const SizedBox(height: 8),
          ParEstadisticas(
            Estadistica(
                icono: Icons.confirmation_number,
                valor: '$vendidos',
                etiqueta: 'Vendidos'),
            Estadistica(
                icono: Icons.event_seat,
                valor: '$disponibles',
                etiqueta: 'Disponibles (aforo ${p.aforoMaximo})'),
          ),
          ParEstadisticas(
            Estadistica(
                icono: Icons.attach_money,
                valor: dinero(recaudado),
                etiqueta: 'Total recaudado'),
            Estadistica(
                icono: Icons.groups,
                valor: '${p.invitadosEsperados}',
                etiqueta: 'Invitados esperados'),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (p.sePuedePublicar)
              FilledButton.icon(
                onPressed: () => _publicar(context, p),
                icon: const Icon(Icons.public),
                label: const Text('Publicar'),
              ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BoletosVendidosPage(partyId: p.idParty))),
              icon: const Icon(Icons.people),
              label: const Text('Boletos vendidos'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PresupuestoPage(partyId: p.idParty))),
              icon: const Icon(Icons.savings),
              label: const Text('Presupuesto'),
            ),
            if (p.sePuedeCancelar)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: tema.colorScheme.error),
                onPressed: () => _cancelar(context, p, vendidos),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar fiesta'),
              ),
          ]),
          TituloSeccion('Servicios solicitados (${solicitudes.length})'),
          if (solicitudes.isEmpty)
            const Text('Todavía no pides servicios para esta fiesta. Búscalos '
                'en la pestaña Servicios.')
          else
            for (final s in solicitudes) TarjetaSolicitud(solicitud: s),
        ],
      ),
    );
  }
}
