import 'package:flutter/material.dart';

import 'estado.dart';
import 'pantallas/splash_page.dart';

void main() => runApp(const RecuPartyApp());

class RecuPartyApp extends StatefulWidget {
  const RecuPartyApp({super.key});

  @override
  State<RecuPartyApp> createState() => _RecuPartyAppState();
}

class _RecuPartyAppState extends State<RecuPartyApp> {
  // El estado de toda la app se crea una sola vez aquí.
  final AppState _estado = AppState();

  @override
  void dispose() {
    _estado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      estado: _estado,
      child: MaterialApp(
        title: 'RecuParty R1',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE91E63),
            brightness: Brightness.dark,
          ),
        ),
        home: const SplashPage(),
      ),
    );
  }
}
