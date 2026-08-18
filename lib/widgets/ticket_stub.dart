import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta plana sobre el fondo de contenido, con sombra sutil — la
/// tarjeta base para listados (entregas, rutas).
class TicketStub extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final double borderWidth;

  const TicketStub({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor = AppColors.border,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: AppShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Insignia circular tipo "perforado" con un número o ícono — usada como
/// el número de orden de parada en la ruta.
class PunchBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double size;
  final double borderWidth;

  const PunchBadge({
    super.key,
    required this.label,
    required this.color,
    this.size = 38,
    this.borderWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: AppFonts.mono(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de estado mono en mayúsculas — PENDIENTE / ENTREGADO / FALLIDO.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool dense;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10, vertical: dense ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppFonts.mono(
          color: color,
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Lectura numérica tipo cuentakilómetros — la firma tipográfica de la
/// app. Todo número (km, horas, contadores) se muestra en mono.
class MonoReadout extends StatelessWidget {
  final String value;
  final String? unit;
  final String? label;
  final Color valueColor;
  final Color labelColor;
  final double valueSize;
  final bool glow;

  const MonoReadout({
    super.key,
    required this.value,
    this.unit,
    this.label,
    this.valueColor = AppColors.turquoise,
    this.labelColor = Colors.white54,
    this.valueSize = 22,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppFonts.mono(
                color: valueColor,
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ).copyWith(
                shadows: glow
                    ? [Shadow(color: valueColor.withValues(alpha: 0.55), blurRadius: 16)]
                    : null,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Text(
                unit!,
                style: AppFonts.mono(
                  color: valueColor.withValues(alpha: 0.75),
                  fontSize: valueSize * 0.42,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label!.toUpperCase(),
              style: AppFonts.mono(
                color: labelColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
      ],
    );
  }
}
