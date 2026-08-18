import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/entrega.dart';
import '../theme/app_theme.dart';
import 'ticket_stub.dart';

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
        return AppColors.route;
      case 'fallido':
        return AppColors.fail;
      default:
        return AppColors.turquoiseDeep;
    }
  }

  String get _estadoLabel {
    switch (entrega.estado) {
      case 'completado':
        return 'Entregado';
      case 'fallido':
        return 'Fallido';
      default:
        return 'Pendiente';
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TicketStub(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                PunchBadge(
                  label: entrega.completado
                      ? '✓'
                      : entrega.fallido
                          ? '✗'
                          : '${entrega.ordenSecuencia}',
                  color: _color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entrega.clienteNombre,
                        style: AppFonts.display(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (entrega.referencia != null)
                        Text(
                          'Ref: ${entrega.referencia}',
                          style: AppFonts.body(
                            color: AppColors.inkSoft,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                StatusPill(label: _estadoLabel, color: _color),
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
                    style: AppFonts.body(fontSize: 13, color: AppColors.ink),
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
                          color: AppColors.turquoiseDeep, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        entrega.clienteTelefono!,
                        style: AppFonts.mono(
                          fontSize: 12.5,
                          color: AppColors.turquoiseDeep,
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
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: AppColors.border,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: onCompletar,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Entregado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.route,
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
                          foregroundColor: AppColors.fail,
                          side: const BorderSide(color: AppColors.fail),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
