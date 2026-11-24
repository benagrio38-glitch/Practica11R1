import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

// Contraseñas: se guarda solo un hash con sal (SHA-256 repetido varias veces).
// Nunca se guarda ni se muestra la contraseña legible.
class Seguridad {
  Seguridad({Random? aleatorio}) : _rnd = aleatorio ?? Random.secure();

  final Random _rnd;
  static const int _vueltas = 2000;

  String nuevaSal() {
    final bytes = List<int>.generate(16, (_) => _rnd.nextInt(256));
    return base64Url.encode(bytes);
  }

  String hashDe(String clave, String sal) {
    List<int> datos = utf8.encode('$sal:$clave');
    for (var i = 0; i < _vueltas; i++) {
      datos = sha256.convert(datos).bytes;
    }
    return base64Url.encode(datos);
  }

  bool coincide(String clave, String sal, String hashGuardado) {
    final calculado = hashDe(clave, sal);
    // Comparación en tiempo constante.
    if (calculado.length != hashGuardado.length) return false;
    var diferencia = 0;
    for (var i = 0; i < calculado.length; i++) {
      diferencia |= calculado.codeUnitAt(i) ^ hashGuardado.codeUnitAt(i);
    }
    return diferencia == 0;
  }

  /// Código de acceso único para un boleto, por ejemplo "RP-7K3Q-9XWD".
  String codigoBoleto() {
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String bloque() =>
        List.generate(4, (_) => letras[_rnd.nextInt(letras.length)]).join();
    return 'RP-${bloque()}-${bloque()}';
  }

  /// Código de 6 dígitos para recuperar el acceso.
  String codigoRecuperacion() =>
      (100000 + _rnd.nextInt(900000)).toString();
}
