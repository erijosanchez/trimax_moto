import 'package:flutter/material.dart';

/// Tipo de repartidor. El CRM maneja dos: motorizado (moto) y delivery
/// (vehículo menor: bici o a pie). Ambos usan el mismo login.
enum TipoRepartidor { motorizado, delivery }

class Motorizado {
  final int id;
  final String nombre;
  final String sede;
  final String? telefono;
  final TipoRepartidor tipo;

  Motorizado({
    required this.id,
    required this.nombre,
    required this.sede,
    this.telefono,
    this.tipo = TipoRepartidor.motorizado,
  });

  factory Motorizado.fromJson(Map<String, dynamic> json) {
    return Motorizado(
      id: json['id'],
      nombre: json['nombre'],
      sede: json['sede'],
      telefono: json['telefono'],
      tipo: _parseTipo(json['tipo'] ?? json['rol'] ?? json['vehiculo']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'sede': sede,
        'telefono': telefono,
        'tipo': tipo.name,
      };

  // Acepta varias formas en las que el CRM podría mandar el tipo.
  static TipoRepartidor _parseTipo(dynamic raw) {
    final v = raw?.toString().toLowerCase().trim() ?? '';
    if (v.contains('delivery') ||
        v.contains('bici') ||
        v.contains('cicl') ||
        v.contains('pie') ||
        v.contains('walk') ||
        v.contains('foot')) {
      return TipoRepartidor.delivery;
    }
    return TipoRepartidor.motorizado;
  }

  bool get esDelivery => tipo == TipoRepartidor.delivery;

  /// Ícono según el vehículo.
  IconData get icono =>
      esDelivery ? Icons.pedal_bike : Icons.delivery_dining;

  /// Etiqueta legible del rol.
  String get etiqueta => esDelivery ? 'Delivery' : 'Motorizado';

  /// Perfil de ruteo OSRM: moto = driving, delivery (bici/pie) = cycling.
  String get rutaProfile => esDelivery ? 'cycling' : 'driving';
}
