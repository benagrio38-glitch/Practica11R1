import 'package:flutter/material.dart';

import '../estado.dart';
import '../widgets_comunes.dart';

// Recuperación de acceso en dos pasos: pedir código y poner contraseña nueva.
// Como la app no tiene servidor de correo, el código se muestra en pantalla
// (en producción llegaría por correo).
class RecuperarPage extends StatefulWidget {
  const RecuperarPage({super.key});

  @override
  State<RecuperarPage> createState() => _RecuperarPageState();
}

class _RecuperarPageState extends State<RecuperarPage> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _codigo = TextEditingController();
  final _nueva = TextEditingController();
  bool _codigoEnviado = false;
  String? _codigoDemo;

  @override
  void dispose() {
    _correo.dispose();
    _codigo.dispose();
    _nueva.dispose();
    super.dispose();
  }

  void _pedirCodigo() {
    if (validarCorreo(_correo.text) != null) {
      _formKey.currentState!.validate();
      return;
    }
    final app = AppScope.leer(context);
    String? codigo;
    final error = app.hacer(
        () => codigo = app.cuentas.solicitarRecuperacion(_correo.text));
    if (!resultado(context, error)) return;
    setState(() {
      _codigoEnviado = true;
      _codigoDemo = codigo;
    });
  }

  void _restablecer() {
    if (!_formKey.currentState!.validate()) return;
    final app = AppScope.leer(context);
    final error = app.hacer(() =>
        app.cuentas.restablecerClave(_correo.text, _codigo.text, _nueva.text));
    if (!resultado(context, error,
        exito: 'Contraseña actualizada. Ya puedes iniciar sesión')) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar acceso')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 64),
                const SizedBox(height: 12),
                Text(
                  _codigoEnviado
                      ? 'Escribe el código que te mandamos y tu contraseña nueva.'
                      : 'Escribe el correo de tu cuenta y te mandamos un código.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _correo,
                  enabled: !_codigoEnviado,
                  keyboardType: TextInputType.emailAddress,
                  decoration: campo('Correo', Icons.email),
                  validator: validarCorreo,
                ),
                if (!_codigoEnviado) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _pedirCodigo,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar código'),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.mark_email_read),
                      title: const Text('Código enviado (válido 15 min)'),
                      subtitle: Text('Demostración sin servidor de correo: '
                          'tu código es $_codigoDemo'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codigo,
                    keyboardType: TextInputType.number,
                    decoration: campo('Código de 6 dígitos', Icons.pin),
                    validator: (v) => (v ?? '').trim().length == 6
                        ? null
                        : 'El código tiene 6 dígitos',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nueva,
                    obscureText: true,
                    decoration: campo('Contraseña nueva', Icons.lock),
                    validator: validarClave,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _restablecer,
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar contraseña'),
                  ),
                ],
                const SizedBox(height: 12),
                Text('Tu contraseña se guarda cifrada (hash), nadie la puede '
                    'leer.', textAlign: TextAlign.center,
                    style: tema.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
