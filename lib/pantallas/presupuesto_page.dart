import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';

// Resumen de presupuesto de una fiesta: presupuesto, servicios aceptados,
// otros gastos y lo recaudado por boletos. Se pueden registrar otros gastos.
class PresupuestoPage extends StatelessWidget {
  const PresupuestoPage({super.key, required this.partyId});

  final int partyId;

  Future<void> _agregarGasto(BuildContext context, Party p) async {
    final concepto = TextEditingController();
    final monto = TextEditingController();
    final llave = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Registrar gasto'),
        content: Form(
          key: llave,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: concepto,
              decoration: campo('Concepto', Icons.receipt_long),
              validator: (v) => obligatorio(v, 'el concepto'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: monto,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: campo('Monto (MXN)', Icons.attach_money),
              validator: validarDinero,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Regresar')),
          FilledButton(
              onPressed: () {
                if (llave.currentState!.validate()) Navigator.of(c).pop(true);
              },
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final app = AppScope.leer(context);
    resultado(
        context,
        app.hacer(() => app.presupuesto.agregarGasto(
            app.yo, p, concepto.text, Dinero.deTexto(monto.text)!)),
        exito: 'Gasto registrado');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.party(partyId)!;
    final r = app.presupuesto.resumen(p);
    final gastos = app.presupuesto.gastosDe(p);
    final tema = Theme.of(context);
    final excedido = r.restante.centavos < 0;

    Widget fila(String texto, Dinero d, {bool fuerte = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(texto)),
            Text(dinero(d),
                style: TextStyle(
                    fontWeight: fuerte ? FontWeight.bold : null, color: color)),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuesto')),
      floatingActionButton: p.sePuedeEditar
          ? FloatingActionButton.extended(
              onPressed: () => _agregarGasto(context, p),
              icon: const Icon(Icons.add),
              label: const Text('Otro gasto'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(p.nombre, style: tema.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Progreso(
                    valor: r.gastado.centavos,
                    total: r.presupuesto.centavos,
                    texto: excedido
                        ? 'Te pasaste del presupuesto por '
                            '${dinero(Dinero(-r.restante.centavos))}'
                        : 'Te quedan ${dinero(r.restante)} del presupuesto'),
                const Divider(height: 24),
                fila('Presupuesto', r.presupuesto, fuerte: true),
                fila('Servicios aceptados', r.servicios),
                fila('Otros gastos', r.otrosGastos),
                fila('Total gastado', r.gastado, fuerte: true),
                const Divider(height: 24),
                fila('Recaudado por boletos', r.recaudado,
                    color: Colors.green.shade300),
                fila('Balance (recaudado − gastado)', r.balance,
                    fuerte: true,
                    color: r.balance.centavos < 0
                        ? tema.colorScheme.error
                        : Colors.green.shade300),
              ]),
            ),
          ),
          TituloSeccion('Gastos (${gastos.length})'),
          if (gastos.isEmpty)
            const Text('No hay gastos registrados.')
          else
            for (final g in gastos)
              Card(
                child: ListTile(
                  leading: Icon(g.solicitudId != null
                      ? Icons.storefront
                      : Icons.receipt_long),
                  title: Text(g.concepto),
                  subtitle: Text(fecha(g.fecha)),
                  trailing: Text(dinero(g.monto),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
        ],
      ),
    );
  }
}
