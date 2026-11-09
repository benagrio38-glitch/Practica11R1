import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';
import 'inicio_page.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmar = TextEditingController();
  Rol _rol = Rol.organizador;
  bool _mayorDeEdad = false;
  bool _faltaEdad = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _clave.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  void _registrar() {
    final camposBien = _formKey.currentState!.validate();
    setState(() => _faltaEdad = !_mayorDeEdad);
    if (!camposBien || !_mayorDeEdad) return;

    final error = AppScope.leer(context)
        .registrar(_nombre.text, _correo.text, _clave.text, _rol);
    if (error != null) {
      mostrarAviso(context, error);
      return;
    }
    // La cuenta nueva entra directo a su dashboard.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const InicioPage()),
      (ruta) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => obligatorio(v, 'tu nombre'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: validarCorreo,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _clave,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: validarClave,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmar,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Confirma tu contraseña';
                        }
                        if (v != _clave.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('¿Cómo vas a usar la app?',
                        style: tema.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final r in Rol.values)
                          ChoiceChip(
                            avatar: Icon(r.icono, size: 18),
                            label: Text(r.nombre),
                            selected: _rol == r,
                            onSelected: (_) => setState(() => _rol = r),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_rol.descripcion, style: tema.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _mayorDeEdad,
                      onChanged: (v) =>
                          setState(() => _mayorDeEdad = v ?? false),
                      title: const Text('Soy mayor de 18 años'),
                      subtitle: _faltaEdad
                          ? Text('Debes confirmar tu edad',
                              style:
                                  TextStyle(color: tema.colorScheme.error))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _registrar,
                      icon: const Icon(Icons.check),
                      label: const Text('Crear cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
