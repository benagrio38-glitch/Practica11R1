import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelos.dart';
import '../widgets_comunes.dart';

// Boletos vendidos de una fiesta (solo los ve su organizador) y control de
// acceso: se escribe o escanea el código del boleto y no deja entrar dos
// veces con el mismo.
class BoletosVendidosPage extends StatefulWidget {
  const BoletosVendidosPage({super.key, required this.partyId});

  final int partyId;

  @override
  State<BoletosVendidosPage> createState() => _BoletosVendidosPageState();
}

class _BoletosVendidosPageState extends State<BoletosVendidosPage> {
  final _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _validar(Party p) {
    final app = AppScope.leer(context);
    Boleto? b;
    final error =
        app.hacer(() => b = app.boletos.validarEntrada(app.yo, p, _codigo.text));
    if (resultado(context, error,
        exito: error == null ? 'Acceso correcto: ${b!.asistente}' : null)) {
      _codigo.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.party(widget.partyId)!;
    final lista = app.boletos.vendidosDe(app.yo, p);
    final usados = lista.where((b) => b.estado == EstadoBoleto.usado).length;
    final validos = lista.where((b) => b.estado == EstadoBoleto.valido).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Boletos vendidos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(p.nombre, style: Theme.of(context).textTheme.titleLarge),
          Text(horario(p.fechaHoraInicio, p.fechaHoraFin)),
          const SizedBox(height: 8),
          ParEstadisticas(
            Estadistica(
                icono: Icons.confirmation_number,
                valor: '${validos + usados}',
                etiqueta: 'Emitidos (aforo ${p.aforoMaximo})'),
            Estadistica(
                icono: Icons.how_to_reg,
                valor: '$usados',
                etiqueta: 'Ya entraron'),
          ),
          const TituloSeccion('Control de acceso'),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _codigo,
                textCapitalization: TextCapitalization.characters,
                decoration: campo('Código del boleto', Icons.qr_code_scanner,
                    ayuda: 'Ej. RP-7K3Q-9XWD (viene en el QR del boleto)'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: p.vendeBoletos ? () => _validar(p) : null,
              child: const Text('Validar'),
            ),
          ]),
          TituloSeccion('Asistentes (${lista.length})'),
          if (lista.isEmpty)
            const Text('Todavía no se vende ningún boleto.')
          else
            for (final b in lista)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(b.asistente),
                  subtitle: Text('Compró ${app.usuario(b.compradorId)?.nombre ?? '-'}'
                      ' · ${fecha(b.fechaCompra)}\n${b.codigoAcceso}'),
                  isThreeLine: true,
                  trailing: ChipEstado.boleto(b.estado),
                ),
              ),
        ],
      ),
    );
  }
}
