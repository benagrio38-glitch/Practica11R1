import 'package:flutter/material.dart';

import 'modelos.dart';

// Widgets y funciones que se usan en varias pantallas.

String dinero(Dinero d) => d.texto;

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String fecha(DateTime d) => '${d.day} ${_meses[d.month - 1]} ${d.year}';

String hora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String fechaHora(DateTime d) => '${fecha(d)}, ${hora(d)}';

String horario(DateTime inicio, DateTime fin) =>
    '${fecha(inicio)} · ${hora(inicio)} a ${hora(fin)}';

void mostrarAviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

/// Diálogo de confirmación; regresa true si el usuario acepta.
Future<bool> confirmar(BuildContext context,
    {required String titulo,
    required String mensaje,
    String accion = 'Confirmar',
    bool peligro = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Regresar')),
        FilledButton(
          style: peligro
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(c).colorScheme.error,
                  foregroundColor: Theme.of(c).colorScheme.onError)
              : null,
          onPressed: () => Navigator.of(c).pop(true),
          child: Text(accion),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Muestra el error si lo hay; regresa true si todo salió bien.
bool resultado(BuildContext context, String? error, {String? exito}) {
  if (error != null) {
    mostrarAviso(context, error);
    return false;
  }
  if (exito != null) mostrarAviso(context, exito);
  return true;
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

String? validarDinero(String? v) {
  final d = Dinero.deTexto(v ?? '');
  if (d == null || !d.esPositivo) return 'Escribe un monto mayor a 0';
  return null;
}

String? validarEntero(String? v, {int minimo = 1}) {
  final n = int.tryParse(v ?? '');
  if (n == null || n < minimo) return 'Escribe un número entero de $minimo o más';
  return null;
}

InputDecoration campo(String etiqueta, IconData icono, {String? ayuda}) =>
    InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      prefixIcon: Icon(icono),
      border: const OutlineInputBorder(),
    );

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
    this.alTocar,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
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
      ),
    );
  }
}

/// Dos estadísticas lado a lado.
class ParEstadisticas extends StatelessWidget {
  const ParEstadisticas(this.a, this.b, {super.key});
  final Estadistica a;
  final Estadistica b;

  @override
  Widget build(BuildContext context) =>
      Row(children: [Expanded(child: a), Expanded(child: b)]);
}

class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion});

  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(texto,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}

/// Fila con icono y texto (fecha, lugar, organizador...).
class Dato extends StatelessWidget {
  const Dato(this.icono, this.texto, {super.key});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(texto)),
          ],
        ),
      );
}

/// Chip de color según el estado.
class ChipEstado extends StatelessWidget {
  const ChipEstado(this.texto, {super.key, this.tono = Tono.neutro});
  final String texto;
  final Tono tono;

  factory ChipEstado.party(EstadoParty e) => ChipEstado(e.nombre,
      tono: switch (e) {
        EstadoParty.publicada => Tono.bien,
        EstadoParty.borrador => Tono.aviso,
        EstadoParty.cancelada => Tono.mal,
        EstadoParty.finalizada => Tono.neutro,
      });

  factory ChipEstado.solicitud(EstadoSolicitud e) => ChipEstado(e.nombre,
      tono: switch (e) {
        EstadoSolicitud.pendiente => Tono.aviso,
        EstadoSolicitud.cotizada => Tono.info,
        EstadoSolicitud.aceptada => Tono.bien,
        EstadoSolicitud.rechazada || EstadoSolicitud.cancelada => Tono.mal,
      });

  factory ChipEstado.boleto(EstadoBoleto e) => ChipEstado(e.nombre,
      tono: switch (e) {
        EstadoBoleto.valido => Tono.bien,
        EstadoBoleto.usado => Tono.neutro,
        EstadoBoleto.cancelado => Tono.mal,
      });

  @override
  Widget build(BuildContext context) {
    final color = switch (tono) {
      Tono.bien => Colors.green,
      Tono.aviso => Colors.orange,
      Tono.mal => Colors.red,
      Tono.info => Colors.lightBlue,
      Tono.neutro => Colors.blueGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(texto,
          style: TextStyle(
              color: color.shade200,
              fontWeight: FontWeight.w600,
              fontSize: 12)),
    );
  }
}

enum Tono { bien, aviso, mal, info, neutro }

/// Barra de progreso con texto ("18 de 80").
class Progreso extends StatelessWidget {
  const Progreso(
      {super.key,
      required this.valor,
      required this.total,
      required this.texto});
  final int valor;
  final int total;
  final String texto;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: total == 0 ? 0 : (valor / total).clamp(0, 1).toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 4),
          Text(texto, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
