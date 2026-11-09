import 'dart:async';

import 'package:flutter/material.dart';

import 'login_page.dart';

// Pantalla de carga inicial. Se queda 3 segundos y pasa al login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: Center(
        // La animación hace crecer el logo y aparecer el texto.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutBack,
          builder: (context, valor, hijo) => Opacity(
            opacity: valor.clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(scale: 0.6 + valor * 0.4, child: hijo),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/party.jpg',
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const Icon(
                    Icons.celebration,
                    size: 120,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('RecuParty R1',
                  style: tema.textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Organiza tu fiesta', style: tema.textTheme.titleMedium),
              const SizedBox(height: 32),
              const SizedBox(
                width: 160,
                child: LinearProgressIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
