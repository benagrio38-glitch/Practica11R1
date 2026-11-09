import 'package:flutter/material.dart';

import '../estado.dart';
import '../widgets_comunes.dart';
import 'inicio_page.dart';
import 'registro_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _verClave = false;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  void _entrar() {
    // validate() revisa todos los campos y muestra los errores en rojo.
    if (!_formKey.currentState!.validate()) return;
    final error =
        AppScope.leer(context).iniciarSesion(_correo.text, _clave.text);
    if (error != null) {
      mostrarAviso(context, error);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const InicioPage()),
    );
  }

  // Llena los campos con un usuario de prueba para la demostración.
  void _usarPrueba(String correo) {
    setState(() {
      _correo.text = correo;
      _clave.text = '123456';
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
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
                    const Icon(Icons.celebration, size: 64),
                    const SizedBox(height: 8),
                    Text('RecuParty R1',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Inicia sesión para continuar',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.bodyMedium),
                    const SizedBox(height: 24),
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
                      obscureText: !_verClave,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_verClave
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _verClave = !_verClave),
                        ),
                      ),
                      validator: validarClave,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _entrar,
                      icon: const Icon(Icons.login),
                      label: const Text('Iniciar sesión'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegistroPage()),
                      ),
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                    const Divider(height: 32),
                    Text('Usuarios de prueba (contraseña 123456)',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.celebration, size: 18),
                          label: const Text('Organizador'),
                          onPressed: () =>
                              _usarPrueba('organizador@recuparty.com'),
                        ),
                        ActionChip(
                          avatar:
                              const Icon(Icons.confirmation_number, size: 18),
                          label: const Text('Invitado'),
                          onPressed: () =>
                              _usarPrueba('invitado@recuparty.com'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.storefront, size: 18),
                          label: const Text('Proveedor'),
                          onPressed: () =>
                              _usarPrueba('proveedor@recuparty.com'),
                        ),
                      ],
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
