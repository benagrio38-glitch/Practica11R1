import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';

// ---------------------------------------------------------------------------
// Catálogo de servicios: buscar y filtrar por tipo y precio.
// ---------------------------------------------------------------------------
class CatalogoServicios extends StatefulWidget {
  const CatalogoServicios({super.key});

  @override
  State<CatalogoServicios> createState() => _CatalogoServiciosState();
}

class _CatalogoServiciosState extends State<CatalogoServicios> {
  final _buscar = TextEditingController();
  TipoServicio? _tipo;
  int? _maxPesos;

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lista = app.catalogo.catalogo(
      texto: _buscar.text,
      tipo: _tipo,
      maxPrecio: _maxPesos == null ? null : Dinero(_maxPesos! * 100),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _buscar,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Buscar servicio…',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final t in [null, ...TipoServicio.values])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t?.nombre ?? 'Todos'),
                  selected: _tipo == t,
                  onSelected: (_) => setState(() => _tipo = t),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: _maxPesos,
          decoration: campo('Precio máximo', Icons.attach_money),
          items: const [
            DropdownMenuItem(value: null, child: Text('Cualquier precio')),
            DropdownMenuItem(value: 500, child: Text('Hasta \$500')),
            DropdownMenuItem(value: 2000, child: Text('Hasta \$2,000')),
            DropdownMenuItem(value: 3000, child: Text('Hasta \$3,000')),
          ],
          onChanged: (v) => setState(() => _maxPesos = v),
        ),
        const SizedBox(height: 12),
        if (lista.isEmpty)
          const SizedBox(
            height: 260,
            child: EstadoVacio(
              icono: Icons.search_off,
              titulo: 'No hay servicios',
              mensaje: 'No hay servicios con esos filtros.',
            ),
          ),
        for (final s in lista) TarjetaServicio(servicio: s),
      ],
    );
  }
}

class TarjetaServicio extends StatelessWidget {
  const TarjetaServicio({super.key, required this.servicio, this.acciones});

  final Servicio servicio;
  final Widget? acciones;

  @override
  Widget build(BuildContext context) {
    final s = servicio;
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: acciones == null
            ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DetalleServicioPage(servicioId: s.idServicio)))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Imagen(s.imagen, alto: 110),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(s.nombre,
                          style: tema.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    ChipEstado(s.tipo.nombre, tono: Tono.info),
                  ]),
                  const SizedBox(height: 4),
                  Text(s.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('${dinero(s.precio)} ${s.unidadPrecio.nombre}',
                        style: TextStyle(
                            color: tema.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Spacer(),
                    if (!s.disponible)
                      const ChipEstado('No disponible', tono: Tono.mal)
                    else if (!s.activo)
                      const ChipEstado('Desactivado', tono: Tono.neutro),
                  ]),
                  if (acciones != null) ...[
                    const SizedBox(height: 6),
                    acciones!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detalle de servicio con el botón para pedir cotización.
// ---------------------------------------------------------------------------
class DetalleServicioPage extends StatelessWidget {
  const DetalleServicioPage({super.key, required this.servicioId});

  final int servicioId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.servicio(servicioId)!;
    final prov = app.usuario(s.proveedorId);
    final tema = Theme.of(context);
    final esOrganizador = app.yo.rol == Rol.organizador;

    return Scaffold(
      appBar: AppBar(title: Text(s.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Imagen(s.imagen, alto: 200),
          const SizedBox(height: 12),
          Text(s.nombre,
              style: tema.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Dato(Icons.category, s.tipo.nombre),
          Dato(Icons.attach_money,
              '${dinero(s.precio)} ${s.unidadPrecio.nombre} (MXN)'),
          Dato(Icons.map, 'Da servicio en: ${s.zona}'),
          Dato(Icons.storefront,
              'Proveedor: ${prov?.nombreNegocio ?? prov?.nombre ?? '-'}'),
          Dato(s.disponible ? Icons.check_circle : Icons.block,
              s.disponible ? 'Disponible' : 'No disponible por ahora'),
          const TituloSeccion('Descripción'),
          Text(s.descripcion),
          const SizedBox(height: 24),
          if (esOrganizador)
            FilledButton.icon(
              onPressed: s.disponible
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          SolicitarServicioPage(servicioId: s.idServicio)))
                  : null,
              icon: const Icon(Icons.request_quote),
              label: const Text('Solicitar cotización'),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Solicitar servicio: el organizador elige fiesta, fecha y escribe detalles.
// ---------------------------------------------------------------------------
class SolicitarServicioPage extends StatefulWidget {
  const SolicitarServicioPage({super.key, required this.servicioId});

  final int servicioId;

  @override
  State<SolicitarServicioPage> createState() => _SolicitarServicioPageState();
}

class _SolicitarServicioPageState extends State<SolicitarServicioPage> {
  final _formKey = GlobalKey<FormState>();
  final _mensaje = TextEditingController();
  final _fechaTexto = TextEditingController();
  Party? _party;
  DateTime? _fecha;

  @override
  void dispose() {
    _mensaje.dispose();
    _fechaTexto.dispose();
    super.dispose();
  }

  void _elegirParty(Party? p) {
    setState(() {
      _party = p;
      if (p != null) {
        _fecha = p.fechaHoraInicio;
        _fechaTexto.text = fechaHora(p.fechaHoraInicio);
      }
    });
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 2),
    );
    if (d == null) return;
    setState(() {
      final h = _fecha ?? DateTime(d.year, d.month, d.day, 20);
      _fecha = DateTime(d.year, d.month, d.day, h.hour, h.minute);
      _fechaTexto.text = fechaHora(_fecha!);
    });
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;
    final app = AppScope.leer(context);
    final s = app.servicio(widget.servicioId)!;
    final error = app.hacer(() => app.solicitudes.solicitar(app.yo, _party!, s,
        mensaje: _mensaje.text, fechaRequerida: _fecha!));
    if (!resultado(context, error,
        exito: 'Solicitud enviada. Te avisamos cuando cotice el proveedor.')) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.servicio(widget.servicioId)!;
    final mis =
        app.fiestas.delOrganizador(app.yo).where((p) => p.sePuedeEditar).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar servicio')),
      body: SafeArea(
        child: mis.isEmpty
            ? const EstadoVacio(
                icono: Icons.celebration_outlined,
                titulo: 'Primero crea una fiesta',
                mensaje: 'Necesitas una fiesta para pedir servicios.')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.storefront),
                          title: Text(s.nombre),
                          subtitle: Text(
                              '${dinero(s.precio)} ${s.unidadPrecio.nombre}'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Party>(
                        initialValue: _party,
                        decoration: campo('¿Para qué fiesta?', Icons.celebration),
                        items: [
                          for (final p in mis)
                            DropdownMenuItem(value: p, child: Text(p.nombre)),
                        ],
                        onChanged: _elegirParty,
                        validator: (v) => v == null ? 'Elige una fiesta' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _fechaTexto,
                        readOnly: true,
                        onTap: _elegirFecha,
                        decoration: campo('Fecha requerida', Icons.event),
                        validator: (v) => obligatorio(v, 'la fecha'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _mensaje,
                        maxLines: 4,
                        decoration: campo('Mensaje y detalles', Icons.message,
                            ayuda: 'Horario, número de personas, extras…'),
                        validator: (v) => obligatorio(v, 'los detalles'),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _enviar,
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar solicitud'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
