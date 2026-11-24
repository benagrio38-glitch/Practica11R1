import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../servicios_app.dart';
import '../widgets_comunes.dart';

// Formulario del organizador para crear o editar una fiesta.
// Si [party] es null se crea una nueva (queda en borrador).
class FormularioParty extends StatefulWidget {
  const FormularioParty({super.key, this.party});

  final Party? party;

  @override
  State<FormularioParty> createState() => _FormularioPartyState();
}

class _FormularioPartyState extends State<FormularioParty> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _fecha = TextEditingController();
  final _inicio = TextEditingController();
  final _fin = TextEditingController();
  final _lugar = TextEditingController();
  final _direccion = TextEditingController();
  final _ciudad = TextEditingController(text: 'Dolores Hidalgo');
  final _esperados = TextEditingController();
  final _aforo = TextEditingController();
  final _presupuesto = TextEditingController();
  final _precio = TextEditingController();
  final _edad = TextEditingController(text: '18');

  DateTime? _dia;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;

  bool get _editando => widget.party != null;

  @override
  void initState() {
    super.initState();
    final p = widget.party;
    if (p == null) return;
    _nombre.text = p.nombre;
    _descripcion.text = p.descripcion;
    _dia = p.fechaHoraInicio;
    _horaInicio = TimeOfDay.fromDateTime(p.fechaHoraInicio);
    _horaFin = TimeOfDay.fromDateTime(p.fechaHoraFin);
    _fecha.text = fecha(p.fechaHoraInicio);
    _inicio.text = hora(p.fechaHoraInicio);
    _fin.text = hora(p.fechaHoraFin);
    _lugar.text = p.lugar.nombre;
    _direccion.text = p.lugar.direccion;
    _ciudad.text = p.lugar.ciudad;
    _esperados.text = '${p.invitadosEsperados}';
    _aforo.text = '${p.aforoMaximo}';
    _presupuesto.text = (p.presupuesto.centavos / 100).toStringAsFixed(2);
    _precio.text = (p.precioBoleto.centavos / 100).toStringAsFixed(2);
    _edad.text = '${p.edadMinima}';
  }

  @override
  void dispose() {
    for (final c in [
      _nombre, _descripcion, _fecha, _inicio, _fin, _lugar, _direccion,
      _ciudad, _esperados, _aforo, _presupuesto, _precio, _edad,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dia ?? hoy,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 2),
    );
    if (d != null) {
      setState(() {
        _dia = d;
        _fecha.text = fecha(d);
      });
    }
  }

  Future<void> _elegirHora(bool esInicio) async {
    final h = await showTimePicker(
      context: context,
      initialTime: (esInicio ? _horaInicio : _horaFin) ??
          TimeOfDay(hour: esInicio ? 20 : 23, minute: 0),
    );
    if (h == null) return;
    setState(() {
      final texto =
          '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';
      if (esInicio) {
        _horaInicio = h;
        _inicio.text = texto;
      } else {
        _horaFin = h;
        _fin.text = texto;
      }
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final inicio = DateTime(_dia!.year, _dia!.month, _dia!.day,
        _horaInicio!.hour, _horaInicio!.minute);
    var fin = DateTime(_dia!.year, _dia!.month, _dia!.day, _horaFin!.hour,
        _horaFin!.minute);
    // Si termina "antes" que empieza, es que acaba al día siguiente.
    if (!fin.isAfter(inicio)) fin = fin.add(const Duration(days: 1));

    final datos = DatosParty(
      nombre: _nombre.text,
      descripcion: _descripcion.text,
      inicio: inicio,
      fin: fin,
      lugar: Lugar(
        nombre: _lugar.text.trim(),
        direccion: _direccion.text.trim(),
        ciudad: _ciudad.text.trim(),
      ),
      invitadosEsperados: int.parse(_esperados.text),
      aforoMaximo: int.parse(_aforo.text),
      presupuesto: Dinero.deTexto(_presupuesto.text)!,
      precioBoleto: Dinero.deTexto(_precio.text)!,
      edadMinima: int.parse(_edad.text),
    );
    final app = AppScope.leer(context);
    final error = app.hacer(() {
      if (_editando) {
        app.fiestas.editar(app.yo, widget.party!, datos,
            app.boletos.vendidos(widget.party!));
      } else {
        app.fiestas.crear(app.yo, datos);
      }
    });
    if (!resultado(context, error,
        exito: _editando
            ? 'Fiesta actualizada'
            : 'Fiesta guardada como borrador. Publícala desde su detalle.')) {
      return;
    }
    Navigator.of(context).pop();
  }

  Widget _separador() => const SizedBox(height: 14);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar fiesta' : 'Nueva fiesta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: campo('Nombre de la fiesta', Icons.edit),
                  validator: (v) => obligatorio(v, 'el nombre de la fiesta'),
                ),
                _separador(),
                TextFormField(
                  controller: _descripcion,
                  maxLines: 2,
                  decoration: campo('Descripción', Icons.notes),
                ),
                const TituloSeccion('Fecha y horario'),
                TextFormField(
                  controller: _fecha,
                  readOnly: true,
                  onTap: _elegirFecha,
                  decoration: campo('Fecha', Icons.event),
                  validator: (v) => obligatorio(v, 'la fecha'),
                ),
                _separador(),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _inicio,
                      readOnly: true,
                      onTap: () => _elegirHora(true),
                      decoration: campo('Inicia', Icons.schedule),
                      validator: (v) => obligatorio(v, 'la hora'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fin,
                      readOnly: true,
                      onTap: () => _elegirHora(false),
                      decoration: campo('Termina', Icons.schedule_outlined),
                      validator: (v) => obligatorio(v, 'la hora'),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('Hora del centro de México (America/Mexico_City)',
                    style: Theme.of(context).textTheme.bodySmall),
                const TituloSeccion('Lugar'),
                TextFormField(
                  controller: _lugar,
                  decoration: campo('Nombre del lugar', Icons.place),
                  validator: (v) => obligatorio(v, 'el lugar'),
                ),
                _separador(),
                TextFormField(
                  controller: _direccion,
                  decoration: campo('Dirección', Icons.signpost,
                      ayuda: 'Solo la ven quienes compraron boleto'),
                  validator: (v) => obligatorio(v, 'la dirección'),
                ),
                _separador(),
                TextFormField(
                  controller: _ciudad,
                  decoration: campo('Ciudad', Icons.location_city),
                  validator: (v) => obligatorio(v, 'la ciudad'),
                ),
                const TituloSeccion('Asistentes y dinero'),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _esperados,
                      keyboardType: TextInputType.number,
                      decoration: campo('Invitados esperados', Icons.groups),
                      validator: validarEntero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _aforo,
                      keyboardType: TextInputType.number,
                      decoration: campo('Aforo máximo', Icons.reduce_capacity),
                      validator: validarEntero,
                    ),
                  ),
                ]),
                _separador(),
                TextFormField(
                  controller: _presupuesto,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: campo('Presupuesto (MXN)', Icons.savings),
                  validator: validarDinero,
                ),
                _separador(),
                TextFormField(
                  controller: _precio,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      campo('Precio del boleto (MXN)', Icons.confirmation_number),
                  validator: validarDinero,
                ),
                _separador(),
                TextFormField(
                  controller: _edad,
                  keyboardType: TextInputType.number,
                  decoration: campo('Edad mínima', Icons.no_drinks,
                      ayuda: 'Mínimo 18 años (puede haber alcohol)'),
                  validator: (v) => validarEntero(v, minimo: 18),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save),
                  label: Text(_editando ? 'Guardar cambios' : 'Guardar fiesta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
