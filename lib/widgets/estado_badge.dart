import 'package:flutter/material.dart';

class EstadoBadge extends StatelessWidget {
  final String estado;

  const EstadoBadge({super.key, required this.estado});

  Color get color {
    switch (estado) {
      case 'completado': return Colors.green;
      case 'fallido':    return Colors.red;
      case 'activa':     return Colors.orange;
      default:           return Colors.grey;
    }
  }

  String get label {
    switch (estado) {
      case 'completado': return 'Entregado';
      case 'fallido':    return 'Fallido';
      case 'activa':     return 'En ruta';
      case 'pendiente':  return 'Pendiente';
      default:           return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}