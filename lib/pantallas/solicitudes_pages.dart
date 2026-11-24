import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';

// ---------------------------------------------------------------------------
// Tarjeta de una solicitud (la usan organizador y proveedor).
// ---------------------------------------------------------------------------
class TarjetaSolicitud extends StatelessWidget {
  const TarjetaSolicitud({super.key, required this.solicitud});

  final Solicitud solicitud;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = solicitud;
    final serv = app.servicio(s.servicioId)!;
    final p = app.party(s.partyId)!;
    final c = s.cotizacionVigente;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        leading: CircleAvatar(child: Icon(_icono(s.estado))),
        title: Text(serv.nombre),
        subtitle: Text('${p.nombre} · ${fecha(s.fechaRequerida)}'
            '${c != null ? '\nCotización: ${dinero(c.precio)}' : ''}'),
        isThreeLine: c != null,
        trailing: ChipEstado.solicitud(s.estado),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DetalleSolicitudPage(solicitudId: s.idSolicitud))),
      ),
    );
  }

  static IconData _icono(EstadoSolicitud e) => switch (e) {
        EstadoSolicitud.pendiente => Icons.hourglass_top,
        EstadoSolicitud.cotizada => Icons.request_quote,
        EstadoSolicitud.aceptada => Icons.check,
        EstadoSolicitud.rechazada => Icons.close,
        EstadoSolicitud.cancelada => Icons.block,
      };
}

// ---------------------------------------------------------------------------
// Lista de solicitudes: "Mis solicitudes" del organizador o la bandeja del
// proveedor, con filtro por estado.
// ---------------------------------------------------------------------------
class ListaSolicitudes extends StatefulWidget {
  const ListaSolicitudes({super.key, required this.comoProveedor});

  final bool comoProveedor;

  @override
  State<ListaSolicitudes> createState() => _ListaSolicitudesState();
}

class _ListaSolicitudesState extends State<ListaSolicitudes> {
  EstadoSolicitud? _estado;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final todas = widget.comoProveedor
        ? app.solicitudes.delProveedor(app.yo)
        : app.solicitudes.delOrganizador(app.yo);
    final lista =
        todas.where((s) => _estado == null || s.estado == _estado).toList();

    if (todas.isEmpty) {
      return EstadoVacio(
        icono: Icons.inbox_outlined,
        titulo: 'No hay solicitudes',
        mensaje: widget.comoProveedor
            ? 'Cuando un organizador te pida un servicio, aparecerá aquí.'
            : 'Pide una cotización desde el catálogo de servicios.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final e in [null, ...EstadoSolicitud.values])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e == null
                      ? 'Todas (${todas.length})'
                      : '${e.nombre} (${todas.where((s) => s.estado == e).length})'),
                  selected: _estado == e,
                  onSelected: (_) => setState(() => _estado = e),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        if (lista.isEmpty) const Text('No hay solicitudes en ese estado.'),
        for (final s in lista) TarjetaSolicitud(solicitud: s),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detalle de solicitud: datos, historial de cotizaciones y acciones según
// quién la ve.
// ---------------------------------------------------------------------------
class DetalleSolicitudPage extends StatelessWidget {
  const DetalleSolicitudPage({super.key, required this.solicitudId});

  final int solicitudId;

  Future<void> _accion(BuildContext context,
      {required String titulo,
      required String mensaje,
      required String boton,
      required void Function(AppState app) hacer,
      required String exito,
      bool peligro = false}) async {
    final ok = await confirmar(context,
        titulo: titulo, mensaje: mensaje, accion: boton, peligro: peligro);
    if (!ok || !context.mounted) return;
    final app = AppScope.leer(context);
    resultado(context, app.hacer(() => hacer(app)), exito: exito);
  }

  Future<void> _rechazarProveedor(BuildContext context, Solicitud s) async {
    final motivo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rechazar solicitud'),
        content: TextField(
          controller: motivo,
          maxLines: 2,
          decoration: campo('Motivo (opcional)', Icons.comment),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Regresar')),
          FilledButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Rechazar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final app = AppScope.leer(context);
    resultado(
        context,
        app.hacer(() =>
            app.solicitudes.rechazarComoProveedor(app.yo, s, motivo.text)),
        exito: 'Solicitud rechazada');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.repo.solicitud(solicitudId)!;
    final serv = app.servicio(s.servicioId)!;
    final p = app.party(s.partyId)!;
    final org = app.usuario(s.organizadorId);
    final prov = app.usuario(s.proveedorId);
    final soyProveedor = app.yo.idUsuario == s.proveedorId;
    final soyOrganizador = app.yo.idUsuario == s.organizadorId;
    final c = s.cotizacionVigente;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
              child: Text(serv.nombre,
                  style: tema.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            ChipEstado.solicitud(s.estado),
          ]),
          const SizedBox(height: 8),
          Dato(Icons.celebration, 'Fiesta: ${p.nombre}'),
          Dato(Icons.event, 'Fecha requerida: ${fechaHora(s.fechaRequerida)}'),
          Dato(Icons.place, p.lugar.completo),
          Dato(Icons.person, 'Organiza: ${org?.nombre ?? '-'}'),
          Dato(Icons.storefront,
              'Proveedor: ${prov?.nombreNegocio ?? prov?.nombre ?? '-'}'),
          Dato(Icons.sell,
              'Precio de lista: ${dinero(serv.precio)} ${serv.unidadPrecio.nombre}'),
          Dato(Icons.schedule, 'Enviada: ${fechaHora(s.fechaCreacion)}'),
          const TituloSeccion('Mensaje'),
          Text(s.mensaje),
          if (s.motivoRechazo != null) ...[
            const TituloSeccion('Motivo del rechazo'),
            Text(s.motivoRechazo!),
          ],
          TituloSeccion('Cotizaciones (${s.cotizaciones.length})'),
          if (s.cotizaciones.isEmpty)
            const Text('El proveedor todavía no manda cotización.')
          else
            for (final x in s.cotizaciones.reversed)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('v${x.version}')),
                  title: Text(dinero(x.precio)),
                  subtitle: Text('${x.comentarios}\n'
                      'Enviada ${fecha(x.fecha)} · vigente hasta '
                      '${fecha(x.vigenciaHasta)}'),
                  isThreeLine: true,
                  trailing: switch (x.respuesta) {
                    RespuestaCotizacion.aceptada =>
                      const ChipEstado('Aceptada', tono: Tono.bien),
                    RespuestaCotizacion.rechazada =>
                      const ChipEstado('Rechazada', tono: Tono.mal),
                    RespuestaCotizacion.sinRespuesta => x == c
                        ? const ChipEstado('Vigente', tono: Tono.info)
                        : const ChipEstado('Reemplazada'),
                  },
                ),
              ),
          const SizedBox(height: 16),
          // ----- Acciones del proveedor -----
          if (soyProveedor && s.estado.abierta) ...[
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      ResponderSolicitudPage(solicitudId: s.idSolicitud))),
              icon: const Icon(Icons.request_quote),
              label: Text(s.cotizaciones.isEmpty
                  ? 'Enviar cotización'
                  : 'Enviar nueva versión de cotización'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _rechazarProveedor(context, s),
              icon: const Icon(Icons.close),
              label: const Text('Rechazar solicitud'),
            ),
          ],
          // ----- Acciones del organizador -----
          if (soyOrganizador && s.estado == EstadoSolicitud.cotizada) ...[
            FilledButton.icon(
              onPressed: () => _accion(context,
                  titulo: 'Confirmar cotización',
                  mensaje: 'Aceptas ${serv.nombre} por ${dinero(c!.precio)}. '
                      'Se suma a los gastos del presupuesto de ${p.nombre}.',
                  boton: 'Aceptar',
                  hacer: (app) => app.solicitudes.aceptarCotizacion(app.yo, s),
                  exito: 'Cotización aceptada'),
              icon: const Icon(Icons.check),
              label: const Text('Aceptar cotización'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _accion(context,
                  titulo: 'Rechazar cotización',
                  mensaje: 'La solicitud quedará rechazada.',
                  boton: 'Rechazar',
                  hacer: (app) =>
                      app.solicitudes.rechazarCotizacion(app.yo, s),
                  exito: 'Cotización rechazada'),
              icon: const Icon(Icons.close),
              label: const Text('Rechazar cotización'),
            ),
          ],
          if (soyOrganizador && s.estado.abierta) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _accion(context,
                  titulo: 'Cancelar solicitud',
                  mensaje: 'El proveedor verá que ya no necesitas el servicio.',
                  boton: 'Cancelar solicitud',
                  peligro: true,
                  hacer: (app) => app.solicitudes.cancelar(app.yo, s),
                  exito: 'Solicitud cancelada'),
              icon: const Icon(Icons.block),
              label: const Text('Cancelar solicitud'),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Responder o cotizar (proveedor): precio, comentarios y vigencia.
// ---------------------------------------------------------------------------
class ResponderSolicitudPage extends StatefulWidget {
  const ResponderSolicitudPage({super.key, required this.solicitudId});

  final int solicitudId;

  @override
  State<ResponderSolicitudPage> createState() => _ResponderSolicitudPageState();
}

class _ResponderSolicitudPageState extends State<ResponderSolicitudPage> {
  final _formKey = GlobalKey<FormState>();
  final _precio = TextEditingController();
  final _comentarios = TextEditingController();
  int _vigencia = 7;

  @override
  void initState() {
    super.initState();
    final app = AppScope.leer(context);
    final s = app.repo.solicitud(widget.solicitudId)!;
    final base = s.cotizacionVigente?.precio ?? app.servicio(s.servicioId)!.precio;
    _precio.text = (base.centavos / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _precio.dispose();
    _comentarios.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;
    final app = AppScope.leer(context);
    final s = app.repo.solicitud(widget.solicitudId)!;
    final error = app.hacer(() => app.solicitudes.cotizar(app.yo, s,
        Dinero.deTexto(_precio.text)!, _comentarios.text,
        diasVigencia: _vigencia));
    if (!resultado(context, error, exito: 'Cotización enviada')) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.repo.solicitud(widget.solicitudId)!;
    final serv = app.servicio(s.servicioId)!;
    final p = app.party(s.partyId)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Cotizar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.request_quote),
                  title: Text('${serv.nombre} para ${p.nombre}'),
                  subtitle: Text('${fechaHora(s.fechaRequerida)}\n“${s.mensaje}”'),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precio,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: campo('Precio cotizado (MXN)', Icons.attach_money),
                validator: validarDinero,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _comentarios,
                maxLines: 3,
                decoration: campo('Comentarios', Icons.comment,
                    ayuda: 'Qué incluye, horario, condiciones…'),
                validator: (v) => obligatorio(v, 'los comentarios'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _vigencia,
                decoration: campo('Vigencia', Icons.timer),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 días')),
                  DropdownMenuItem(value: 7, child: Text('7 días')),
                  DropdownMenuItem(value: 15, child: Text('15 días')),
                ],
                onChanged: (v) => setState(() => _vigencia = v ?? 7),
              ),
              const SizedBox(height: 8),
              Text(
                  s.cotizaciones.isEmpty
                      ? 'Es la primera cotización (versión 1).'
                      : 'Se guardará como versión ${s.cotizaciones.length + 1}; '
                          'las anteriores quedan en el historial.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _enviar,
                icon: const Icon(Icons.send),
                label: const Text('Enviar cotización'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
