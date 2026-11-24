import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';
import 'inicio_page.dart';
import 'perfil_page.dart';

// Dashboard del invitado. Navegación mínima del documento:
// Explorar fiestas, Mis boletos y Perfil.
class DashboardInvitado extends StatelessWidget {
  const DashboardInvitado({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardBase(
      titulo: 'Invitado',
      destinos: [
        NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explorar'),
        NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Mis boletos'),
        NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil'),
      ],
      paginas: [
        ExplorarFiestas(),
        MisBoletos(),
        PerfilPage(comoPestana: true),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Explorar: resumen del invitado + búsqueda por texto, fecha y precio.
// ---------------------------------------------------------------------------
class ExplorarFiestas extends StatefulWidget {
  const ExplorarFiestas({super.key});

  @override
  State<ExplorarFiestas> createState() => _ExplorarFiestasState();
}

class _ExplorarFiestasState extends State<ExplorarFiestas> {
  final _buscar = TextEditingController();
  DateTime? _desde;
  int? _maxPesos;

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _elegirDesde() async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _desde ?? hoy,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 2),
    );
    setState(() => _desde = d);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lista = app.fiestas.publicas(
      texto: _buscar.text,
      desde: _desde,
      maxPrecio: _maxPesos == null ? null : Dinero(_maxPesos! * 100),
    );
    final todas = app.fiestas.publicas();
    final misValidos =
        app.misBoletos.where((b) => b.estado == EstadoBoleto.valido).toList();
    final proximaMia = todas
        .where((p) => misValidos.any((b) => b.partyId == p.idParty))
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hola, ${app.yo.nombre}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Text('Encuentra tu próxima fiesta.'),
        const SizedBox(height: 8),
        ParEstadisticas(
          Estadistica(
              icono: Icons.celebration,
              valor: '${todas.length}',
              etiqueta: 'Fiestas disponibles'),
          Estadistica(
              icono: Icons.confirmation_number,
              valor: '${misValidos.length}',
              etiqueta: 'Mis boletos activos'),
        ),
        if (proximaMia != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_available),
              title: Text('Tu próxima fiesta: ${proximaMia.nombre}'),
              subtitle: Text(
                  horario(proximaMia.fechaHoraInicio, proximaMia.fechaHoraFin)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      DetalleFiestaPublica(partyId: proximaMia.idParty))),
            ),
          ),
        const TituloSeccion('Buscar fiestas'),
        TextField(
          controller: _buscar,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Nombre o lugar…',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          InputChip(
            avatar: const Icon(Icons.event, size: 18),
            label: Text(_desde == null ? 'Cualquier fecha' : 'Desde ${fecha(_desde!)}'),
            onPressed: _elegirDesde,
            onDeleted: _desde == null ? null : () => setState(() => _desde = null),
          ),
          for (final m in [null, 120, 150])
            ChoiceChip(
              label: Text(m == null ? 'Cualquier precio' : 'Hasta \$$m'),
              selected: _maxPesos == m,
              onSelected: (_) => setState(() => _maxPesos = m),
            ),
        ]),
        const SizedBox(height: 8),
        if (lista.isEmpty)
          const SizedBox(
            height: 240,
            child: EstadoVacio(
              icono: Icons.celebration_outlined,
              titulo: 'No hay fiestas',
              mensaje: 'No hay fiestas publicadas con esos filtros.',
            ),
          ),
        for (final p in lista)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(child: Icon(Icons.celebration)),
              title: Text(p.nombre),
              subtitle: Text(
                '${horario(p.fechaHoraInicio, p.fechaHoraFin)}\n'
                '${p.lugar.publico} · ${dinero(p.precioBoleto)} · '
                '${app.boletos.disponibles(p)} disponibles',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DetalleFiestaPublica(partyId: p.idParty))),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detalle público: solo la información que el organizador permite. La
// dirección completa aparece cuando ya tienes boleto.
// ---------------------------------------------------------------------------
class DetalleFiestaPublica extends StatelessWidget {
  const DetalleFiestaPublica({super.key, required this.partyId});

  final int partyId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.party(partyId)!;
    final tengo = app.boletos.tieneBoleto(app.yo, p);
    final disponibles = app.boletos.disponibles(p);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(p.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Imagen('assets/images/terraza_splash.jpg', alto: 180),
          const SizedBox(height: 12),
          Text(p.nombre,
              style: tema.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (p.descripcion.isNotEmpty) Text(p.descripcion),
          const SizedBox(height: 8),
          Dato(Icons.event, horario(p.fechaHoraInicio, p.fechaHoraFin)),
          Dato(Icons.place, tengo ? p.lugar.completo : p.lugar.publico),
          if (!tengo)
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Text('La dirección exacta se muestra al comprar tu boleto.',
                  style: tema.textTheme.bodySmall),
            ),
          Dato(Icons.person,
              'Organiza: ${app.usuario(p.organizadorId)?.nombre ?? '-'}'),
          Dato(Icons.no_drinks, 'Solo mayores de ${p.edadMinima} años'),
          Dato(Icons.confirmation_number,
              '${dinero(p.precioBoleto)} por persona · quedan $disponibles'),
          const SizedBox(height: 8),
          Text('Política: puedes cancelar tu boleto hasta 48 horas antes. '
              'Si el organizador cancela la fiesta se te reembolsa el 100%.',
              style: tema.textTheme.bodySmall),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: disponibles > 0
                ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CompraBoletosPage(partyId: p.idParty)))
                : null,
            icon: const Icon(Icons.shopping_cart),
            label: Text(disponibles > 0 ? 'Comprar boletos' : 'Boletos agotados'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compra de boletos: cantidad, datos de cada asistente, total y pago.
// ---------------------------------------------------------------------------
class CompraBoletosPage extends StatefulWidget {
  const CompraBoletosPage({super.key, required this.partyId});

  final int partyId;

  @override
  State<CompraBoletosPage> createState() => _CompraBoletosPageState();
}

class _CompraBoletosPageState extends State<CompraBoletosPage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _asistentes = [];
  final _tarjeta = TextEditingController();

  @override
  void initState() {
    super.initState();
    _asistentes.add(TextEditingController(
        text: AppScope.leer(context).yo.nombre));
  }

  @override
  void dispose() {
    for (final c in _asistentes) {
      c.dispose();
    }
    _tarjeta.dispose();
    super.dispose();
  }

  void _cambiarCantidad(int delta) {
    setState(() {
      if (delta > 0) {
        _asistentes.add(TextEditingController());
      } else if (_asistentes.length > 1) {
        _asistentes.removeLast().dispose();
      }
    });
  }

  Future<void> _comprar(Party p) async {
    if (!_formKey.currentState!.validate()) return;
    final total = p.precioBoleto.por(_asistentes.length);
    final ok = await confirmar(context,
        titulo: 'Confirmar compra',
        mensaje: '${_asistentes.length} boleto(s) para ${p.nombre}.\n'
            'Total a pagar: ${dinero(total)} MXN con la tarjeta terminación '
            '${_tarjeta.text}.',
        accion: 'Pagar ${dinero(total)}');
    if (!ok || !mounted) return;
    final app = AppScope.leer(context);
    final error = app.hacer(() => app.boletos.comprar(
        app.yo, p, [for (final c in _asistentes) c.text],
        terminacionTarjeta: _tarjeta.text));
    if (!resultado(context, error,
        exito: 'Compra lista: ${_asistentes.length} boleto(s). Los ves en '
            'Mis boletos.')) {
      return;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.party(widget.partyId)!;
    final disponibles = app.boletos.disponibles(p);
    final total = p.precioBoleto.por(_asistentes.length);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Comprar boletos')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(p.nombre, style: tema.textTheme.titleLarge),
                Text(horario(p.fechaHoraInicio, p.fechaHoraFin)),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Cantidad'),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed:
                        _asistentes.length > 1 ? () => _cambiarCantidad(-1) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('${_asistentes.length}',
                        style: tema.textTheme.titleLarge),
                  ),
                  IconButton.filledTonal(
                    onPressed: _asistentes.length < disponibles
                        ? () => _cambiarCantidad(1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ]),
                const TituloSeccion('Datos de cada asistente'),
                for (var i = 0; i < _asistentes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _asistentes[i],
                      textCapitalization: TextCapitalization.words,
                      decoration: campo('Asistente ${i + 1}', Icons.person,
                          ayuda: i == 0 ? 'Cada asistente recibe su propio '
                              'boleto con código único' : null),
                      validator: (v) => obligatorio(v, 'el nombre'),
                    ),
                  ),
                const TituloSeccion('Pago'),
                TextFormField(
                  controller: _tarjeta,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: campo('Últimos 4 dígitos de la tarjeta',
                      Icons.credit_card,
                      ayuda: 'Pago simulado: la app no guarda el número '
                          'completo ni el código de seguridad'),
                  validator: (v) => RegExp(r'^\d{4}$').hasMatch(v ?? '')
                      ? null
                      : 'Escribe 4 dígitos',
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Total'),
                    subtitle: Text('${_asistentes.length} × '
                        '${dinero(p.precioBoleto)}'),
                    trailing: Text('${dinero(total)} MXN',
                        style: tema.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: disponibles > 0 ? () => _comprar(p) : null,
                  icon: const Icon(Icons.lock),
                  label: Text('Pagar ${dinero(total)}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mis boletos: una tarjeta por compra con fiesta, cantidad y estado.
// ---------------------------------------------------------------------------
class MisBoletos extends StatelessWidget {
  const MisBoletos({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final compras = app.boletos.comprasDe(app.yo);

    if (compras.isEmpty) {
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
        for (final c in compras)
          Builder(builder: (context) {
            final p = app.party(c.partyId)!;
            final boletos = app.boletos.boletosDeCompra(c);
            return Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: const CircleAvatar(
                    child: Icon(Icons.confirmation_number)),
                title: Text(p.nombre),
                subtitle: Text('${boletos.length} boleto(s) · '
                    '${dinero(c.total)} · ${horario(p.fechaHoraInicio, p.fechaHoraFin)}'),
                trailing: p.estado == EstadoParty.cancelada
                    ? const ChipEstado('Reembolsada', tono: Tono.mal)
                    : ChipEstado(
                        c.estado == EstadoCompra.pagada ? 'Pagada' : 'Pendiente',
                        tono: Tono.bien),
                children: [
                  for (final b in boletos)
                    ListTile(
                      leading: const Icon(Icons.qr_code_2),
                      title: Text(b.asistente),
                      subtitle: Text(b.codigoAcceso),
                      trailing: ChipEstado.boleto(b.estado),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => DetalleBoletoPage(boleto: b))),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detalle del boleto: datos de acceso con QR único; cancelar según política.
// ---------------------------------------------------------------------------
class DetalleBoletoPage extends StatelessWidget {
  const DetalleBoletoPage({super.key, required this.boleto});

  final Boleto boleto;

  Future<void> _cancelar(BuildContext context) async {
    final ok = await confirmar(context,
        titulo: 'Cancelar boleto',
        mensaje: 'Se cancela el boleto de ${boleto.asistente} y se te '
            'reembolsan ${dinero(boleto.precioUnitario)}. Ya no podrá entrar '
            'con este código.',
        accion: 'Cancelar boleto',
        peligro: true);
    if (!ok || !context.mounted) return;
    final app = AppScope.leer(context);
    resultado(context, app.hacer(() => app.boletos.cancelarBoleto(app.yo, boleto)),
        exito: 'Boleto cancelado y reembolsado');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final b = boleto;
    final p = app.party(b.partyId)!;
    final puedeCancelar =
        b.estado == EstadoBoleto.valido && p.permiteCancelarBoleto(app.reloj());
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi boleto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text(p.nombre,
                    textAlign: TextAlign.center,
                    style: tema.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data: b.codigoAcceso,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(b.codigoAcceso,
                    style: tema.textTheme.titleMedium
                        ?.copyWith(letterSpacing: 2)),
                const SizedBox(height: 8),
                ChipEstado.boleto(b.estado),
              ]),
            ),
          ),
          const TituloSeccion('Datos de acceso'),
          Dato(Icons.person, 'Asistente: ${b.asistente}'),
          Dato(Icons.event, horario(p.fechaHoraInicio, p.fechaHoraFin)),
          Dato(Icons.place, p.lugar.completo),
          Dato(Icons.no_drinks, 'Presenta identificación (mayores de '
              '${p.edadMinima})'),
          Dato(Icons.receipt, 'Comprado el ${fecha(b.fechaCompra)} por '
              '${dinero(b.precioUnitario)}'),
          if (b.usadoEn != null)
            Dato(Icons.how_to_reg, 'Entró el ${fechaHora(b.usadoEn!)}'),
          const TituloSeccion('Política del boleto'),
          const Text('• Cancelación con reembolso hasta 48 horas antes.\n'
              '• Transferencias: esta fiesta no permite transferir boletos; '
              'cada boleto está a nombre de su asistente.\n'
              '• Si el organizador cancela, se reembolsa el 100%.'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: puedeCancelar ? () => _cancelar(context) : null,
            icon: const Icon(Icons.cancel),
            label: Text(puedeCancelar
                ? 'Cancelar boleto'
                : 'Ya no se puede cancelar'),
          ),
        ],
      ),
    );
  }
}
