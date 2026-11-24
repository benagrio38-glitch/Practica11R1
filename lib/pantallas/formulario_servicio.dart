import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../servicios_app.dart';
import '../widgets_comunes.dart';

// Formulario del proveedor para publicar o editar un servicio.
class FormularioServicio extends StatefulWidget {
  const FormularioServicio({super.key, this.servicio});

  final Servicio? servicio;

  @override
  State<FormularioServicio> createState() => _FormularioServicioState();
}

class _FormularioServicioState extends State<FormularioServicio> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final _descripcion = TextEditingController();
  final _zona = TextEditingController(text: 'Dolores Hidalgo');
  TipoServicio _tipo = TipoServicio.salon;
  UnidadPrecio _unidad = UnidadPrecio.porEvento;
  bool _disponible = true;

  bool get _editando => widget.servicio != null;

  @override
  void initState() {
    super.initState();
    final s = widget.servicio;
    if (s == null) return;
    _nombre.text = s.nombre;
    _precio.text = (s.precio.centavos / 100).toStringAsFixed(2);
    _descripcion.text = s.descripcion;
    _zona.text = s.zona;
    _tipo = s.tipo;
    _unidad = s.unidadPrecio;
    _disponible = s.disponible;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _descripcion.dispose();
    _zona.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final datos = DatosServicio(
      nombre: _nombre.text,
      tipo: _tipo,
      precio: Dinero.deTexto(_precio.text)!,
      unidad: _unidad,
      descripcion: _descripcion.text,
      zona: _zona.text,
      disponible: _disponible,
    );
    final app = AppScope.leer(context);
    final error = app.hacer(() {
      if (_editando) {
        app.catalogo.editar(app.yo, widget.servicio!, datos);
      } else {
        app.catalogo.publicar(app.yo, datos);
      }
    });
    if (!resultado(context, error,
        exito: _editando ? 'Servicio actualizado' : 'Servicio publicado')) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_editando ? 'Editar servicio' : 'Nuevo servicio')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<TipoServicio>(
                  initialValue: _tipo,
                  decoration: campo('Tipo de servicio', Icons.category),
                  items: [
                    for (final t in TipoServicio.values)
                      DropdownMenuItem(value: t, child: Text(t.nombre)),
                  ],
                  onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nombre,
                  decoration: campo('Nombre del servicio', Icons.edit),
                  validator: (v) => obligatorio(v, 'el nombre del servicio'),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precio,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: campo('Precio (MXN)', Icons.attach_money),
                      validator: validarDinero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<UnidadPrecio>(
                      initialValue: _unidad,
                      decoration: campo('Cobro', Icons.straighten),
                      items: [
                        for (final u in UnidadPrecio.values)
                          DropdownMenuItem(value: u, child: Text(u.nombre)),
                      ],
                      onChanged: (v) => setState(() => _unidad = v ?? _unidad),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _zona,
                  decoration: campo('Ciudad o zona de servicio', Icons.map),
                  validator: (v) => obligatorio(v, 'la zona'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descripcion,
                  maxLines: 3,
                  decoration: campo('Descripción', Icons.notes),
                  validator: (v) => obligatorio(v, 'una descripción'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _disponible,
                  onChanged: (v) => setState(() => _disponible = v),
                  title: const Text('Disponible para nuevas solicitudes'),
                ),
                const SizedBox(height: 8),
                Text(
                    'La imagen se asigna según el tipo. Los servicios pasan por '
                    'revisión antes de mostrarse en el catálogo.',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save),
                  label: Text(_editando ? 'Guardar cambios' : 'Publicar servicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
