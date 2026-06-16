import 'package:latlong2/latlong.dart';

/// Resultado de calcular una ruta por calles (OSRM).
class RutaCalculada {
  /// Puntos de la geometría de la ruta (para dibujar la polyline).
  final List<LatLng> puntos;

  /// Distancia total en metros.
  final double distanciaM;

  /// Duración estimada en segundos.
  final double duracionS;

  RutaCalculada({
    required this.puntos,
    required this.distanciaM,
    required this.duracionS,
  });

  double get distanciaKm => distanciaM / 1000.0;

  int get minutos => (duracionS / 60).round();

  /// Distancia legible: "850 m" o "1.4 km".
  String get distanciaTexto {
    if (distanciaM < 1000) return '${distanciaM.round()} m';
    return '${distanciaKm.toStringAsFixed(1)} km';
  }

  /// ETA legible: "6 min" o "1 h 12 min".
  String get etaTexto {
    final m = minutos;
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '$h h' : '$h h $r min';
  }

  /// Resumen compacto: "1.4 km · 6 min".
  String get resumen => '$distanciaTexto · $etaTexto';
}
