import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../models/ruta_calculada.dart';

/// Calcula rutas por calles usando el servidor público de OSRM.
///
/// Usa una instancia de Dio propia (sin el header Authorization del CRM): no
/// hay que mandar el token de Trimax a un servidor externo.
class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  static const String _baseUrl = 'https://router.project-osrm.org';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  /// Calcula la ruta de [origen] a [destino] con el [profile] dado
  /// ('driving' para moto, 'cycling'/'foot' para delivery).
  ///
  /// Devuelve null si OSRM falla o no hay ruta (la UI debe tolerarlo).
  Future<RutaCalculada?> calcular({
    required LatLng origen,
    required LatLng destino,
    String profile = 'driving',
  }) async {
    try {
      // OSRM usa el orden lng,lat.
      final coords =
          '${origen.longitude},${origen.latitude};${destino.longitude},${destino.latitude}';
      final res = await _dio.get(
        '$_baseUrl/route/v1/$profile/$coords',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );

      final data = res.data;
      if (data is! Map ||
          data['code'] != 'Ok' ||
          data['routes'] is! List ||
          (data['routes'] as List).isEmpty) {
        return null;
      }

      final route = (data['routes'] as List).first as Map;
      final geometry = route['geometry'] as Map;
      final coordsList = geometry['coordinates'] as List;

      final puntos = coordsList
          .map<LatLng>((c) => LatLng(
                (c[1] as num).toDouble(), // lat
                (c[0] as num).toDouble(), // lng
              ))
          .toList();

      return RutaCalculada(
        puntos: puntos,
        distanciaM: (route['distance'] as num).toDouble(),
        duracionS: (route['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
