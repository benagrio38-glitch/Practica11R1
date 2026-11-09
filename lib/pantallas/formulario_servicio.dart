import 'package:flutter/material.dart';

import '../estado.dart';
import '../widgets_comunes.dart';

// Formulario del proveedor para publicar un servicio.
class FormularioServicio extends StatefulWidget {
  const FormularioServicio({super.key});

  @override
  State<FormularioServicio> createState() => _FormularioServicioState();
}

class _FormularioServicioState extends State<FormularioServicio> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final _descripcion = TextEditingController();
  String _tipo = 'Salón';

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    AppScope.leer(context).agregarServicio(
      nombre: _nombre.text.trim(),
      tipo: _tipo,
      precio: double.parse(_precio.text),
      descripcion: _descripcion.text.trim(),
    );
    mostrarAviso(context, 'Servicio publicado');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo servicio')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'Salón',
                        label: Text('Salón')),
                    ButtonSegment(
                        value: 'Alberca',
                        label: Text('Alberca')),
                    ButtonSegment(
                        value: 'DJ',
                        label: Text('DJ')),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (s) => setState(() => _tipo = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del servicio',
                    prefixIcon: Icon(Icons.edit),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => obligatorio(v, 'el nombre del servicio'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _precio,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  validator: validarNumero,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcion,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => obligatorio(v, 'una descripción'),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save),
                  label: const Text('Publicar servicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
