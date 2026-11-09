import 'package:flutter/material.dart';

// Widgets y funciones que se usan en varias pantallas.

String dinero(num valor) => '\$${valor.toStringAsFixed(0)}';

void mostrarAviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

// ---------- Validaciones de los formularios ----------

String? validarCorreo(String? v) {
  if (v == null || v.trim().isEmpty) return 'Escribe tu correo';
  if (!v.contains('@') || !v.contains('.')) return 'El correo no es válido';
  return null;
}

String? validarClave(String? v) {
  if (v == null || v.isEmpty) return 'Escribe tu contraseña';
  if (v.length < 6) return 'Mínimo 6 caracteres';
  return null;
}

String? obligatorio(String? v, String campo) {
  if (v == null || v.trim().isEmpty) return 'Escribe $campo';
  return null;
}

String? validarNumero(String? v) {
  final n = double.tryParse(v ?? '');
  if (n == null || n <= 0) return 'Escribe un número mayor a 0';
  return null;
}

// ---------- Widgets ----------

class Imagen extends StatelessWidget {
  const Imagen(this.ruta, {super.key, this.alto = 140});

  final String ruta;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        ruta,
        height: alto,
        width: double.infinity,
        fit: BoxFit.cover,
        // Si la imagen no carga se muestra un icono y la app no se rompe.
        errorBuilder: (context, error, stack) => Container(
          height: alto,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const Icon(Icons.celebration, size: 40),
        ),
      ),
    );
  }
}

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 72, color: tema.colorScheme.outline),
            const SizedBox(height: 12),
            Text(titulo, style: tema.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(mensaje,
                textAlign: TextAlign.center, style: tema.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class Estadistica extends StatelessWidget {
  const Estadistica({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: tema.colorScheme.primary),
            const SizedBox(height: 8),
            Text(valor,
                style: tema.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(etiqueta, style: tema.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(texto,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}
