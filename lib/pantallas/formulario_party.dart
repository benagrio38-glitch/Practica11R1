import 'package:flutter/material.dart';

import '../estado.dart';
import '../widgets_comunes.dart';

// Formulario del organizador para crear una party.
class FormularioParty extends StatefulWidget {
  const FormularioParty({super.key});

  @override
  State<FormularioParty> createState() => _FormularioPartyState();
}

class _FormularioPartyState extends State<FormularioParty> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _fecha = TextEditingController();
  final _lugar = TextEditingController();
  final _invitados = TextEditingController();
  final _presupuesto = TextEditingController();
  final _precio = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _fecha.dispose();
    _lugar.dispose();
    _invitados.dispose();
    _presupuesto.dispose();
    _precio.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: hoy,
      firstDate: hoy,
      lastDate: DateTime(hoy.year + 2),
    );
    if (d != null) {
      _fecha.text = '${d.day}/${d.month}/${d.year}';
    }
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    AppScope.leer(context).crearParty(
      nombre: _nombre.text.trim(),
      fecha: _fecha.text,
      lugar: _lugar.text.trim(),
      invitados: int.parse(_invitados.text),
      presupuesto: double.parse(_presupuesto.text),
      precioBoleto: double.parse(_precio.text),
    );
    mostrarAviso(context, 'Party creada');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva party')),
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
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la fiesta',
                    prefixIcon: Icon(Icons.edit),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => obligatorio(v, 'el nombre de la fiesta'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fecha,
                  readOnly: true,
                  onTap: _elegirFecha,
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.event),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => obligatorio(v, 'la fecha'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lugar,
                  decoration: const InputDecoration(
                    labelText: 'Lugar',
                    prefixIcon: Icon(Icons.place),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => obligatorio(v, 'el lugar'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _invitados,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de invitados',
                    prefixIcon: Icon(Icons.groups),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Escribe un número entero';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _presupuesto,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Presupuesto',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  validator: validarNumero,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _precio,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio del boleto',
                    prefixIcon: Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(),
                  ),
                  validator: validarNumero,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar party'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
