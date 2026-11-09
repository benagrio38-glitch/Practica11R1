import 'package:flutter/material.dart';

// Los tres tipos de usuario que tiene la app.
enum Rol { organizador, invitado, proveedor }

extension RolTexto on Rol {
  String get nombre {
    switch (this) {
      case Rol.organizador:
        return 'Organizador';
      case Rol.invitado:
        return 'Invitado';
      case Rol.proveedor:
        return 'Proveedor';
    }
  }

  String get descripcion {
    switch (this) {
      case Rol.organizador:
        return 'Crea parties, contrata salones, albercas y DJs y vende boletos.';
      case Rol.invitado:
        return 'Busca parties y compra tus boletos.';
      case Rol.proveedor:
        return 'Ofrece tus servicios y responde las solicitudes.';
    }
  }

  IconData get icono {
    switch (this) {
      case Rol.organizador:
        return Icons.celebration;
      case Rol.invitado:
        return Icons.confirmation_number;
      case Rol.proveedor:
        return Icons.storefront;
    }
  }
}

class Usuario {
  const Usuario({
    required this.nombre,
    required this.correo,
    required this.clave,
    required this.rol,
  });

  final String nombre;
  final String correo;
  final String clave;
  final Rol rol;
}

class Party {
  Party({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.lugar,
    required this.invitados,
    required this.presupuesto,
    required this.precioBoleto,
    required this.organizador,
    required this.organizadorNombre,
    this.vendidos = 0,
  });

  final int id;
  final String nombre;
  final String fecha;
  final String lugar;
  final int invitados;
  final double presupuesto;
  final double precioBoleto;
  final String organizador; // correo del organizador
  final String organizadorNombre;
  int vendidos;

  int get disponibles => invitados - vendidos;
}

class Servicio {
  const Servicio({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.precio,
    required this.descripcion,
    required this.proveedor,
    required this.proveedorNombre,
    required this.imagen,
  });

  final int id;
  final String nombre;
  final String tipo; // Salón, Alberca o DJ
  final double precio;
  final String descripcion;
  final String proveedor; // correo del proveedor
  final String proveedorNombre;
  final String imagen;
}

class Boleto {
  const Boleto({
    required this.id,
    required this.party,
    required this.cantidad,
    required this.asistente,
    required this.comprador,
  });

  final int id;
  final Party party;
  final int cantidad;
  final String asistente;
  final String comprador; // correo de quien compró

  double get total => cantidad * party.precioBoleto;
}

class Solicitud {
  Solicitud({
    required this.id,
    required this.servicio,
    required this.party,
    this.estado = 'Pendiente',
  });

  final int id;
  final Servicio servicio;
  final Party party;
  String estado; // Pendiente, Aceptada o Rechazada
}
