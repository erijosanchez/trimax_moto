import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/entrega.dart';
import '../theme/app_theme.dart';

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
      case 'completado':
        return AppColors.success;
      case 'fallido':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _llamar() async {
    final tel = entrega.clienteTelefono;
    if (tel == null || tel.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: tel.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(left: BorderSide(color: _color, width: 5)),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(color: _color, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      entrega.completado
                          ? '✓'
                          : entrega.fallido
                              ? '✗'
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entrega.clienteNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (entrega.referencia != null)
                        Text(
                          'Ref: ${entrega.referencia}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    entrega.completado
                        ? 'Entregado'
                        : entrega.fallido
                            ? 'Fallido'
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: _color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    entrega.direccion,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),

            // Teléfono (toca para llamar)
            if (entrega.clienteTelefono != null &&
                entrega.clienteTelefono!.isNotEmpty) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: _llamar,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.phone,
                          color: AppColors.primary, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        entrega.clienteTelefono!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
                        backgroundColor: AppColors.success,
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
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
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
