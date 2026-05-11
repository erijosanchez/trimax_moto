import 'package:flutter/material.dart';
import '../models/entrega.dart';

class EntregaCard extends StatelessWidget {
  final Entrega entrega;
  final VoidCallback onCompletar;
  final VoidCallback onFallar;

  const EntregaCard({
    super.key,
    required this.entrega,
    required this.onCompletar,
    required this.onFallar,
  });

  Color get _color {
    switch (entrega.estado) {
      case 'completado': return Colors.green;
      case 'fallido':    return Colors.red;
      default:           return const Color(0xFF1a73e8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: _color, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Row(
              children: [
                // Número
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      entrega.completado ? '✓'
                        : entrega.fallido  ? '✗'
                        : '${entrega.ordenSecuencia}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entrega.clienteNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (entrega.referencia != null)
                        Text(
                          'Ref: ${entrega.referencia}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                // Badge estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _color.withOpacity(0.3)),
                  ),
                  child: Text(
                    entrega.completado ? 'Entregado'
                      : entrega.fallido  ? 'Fallido'
                      : 'Pendiente',
                    style: TextStyle(
                      color: _color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dirección
            Row(
              children: [
                Icon(Icons.location_on, color: _color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    entrega.direccion,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),

            // Teléfono
            if (entrega.clienteTelefono != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.grey, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    entrega.clienteTelefono!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],

            // Botones acción
            if (entrega.pendiente) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: onCompletar,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Entregado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: onFallar,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Fallido'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}