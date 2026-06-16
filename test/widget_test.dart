// Tests unitarios de la app Trimax Moto.

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:trimax_moto/models/ruta_calculada.dart';
import 'package:trimax_moto/models/motorizado.dart';

void main() {
  group('RutaCalculada', () {
    test('formatea distancia en metros y km', () {
      final corta = RutaCalculada(puntos: const [], distanciaM: 850, duracionS: 120);
      expect(corta.distanciaTexto, '850 m');

      final larga = RutaCalculada(puntos: const [], distanciaM: 1400, duracionS: 360);
      expect(larga.distanciaTexto, '1.4 km');
    });

    test('formatea ETA en minutos y horas', () {
      final corta = RutaCalculada(puntos: const [], distanciaM: 0, duracionS: 360);
      expect(corta.etaTexto, '6 min');

      final larga = RutaCalculada(puntos: const [], distanciaM: 0, duracionS: 4320);
      expect(larga.etaTexto, '1 h 12 min');
    });

    test('resumen combina distancia y ETA', () {
      final r = RutaCalculada(
        puntos: const [LatLng(0, 0)],
        distanciaM: 1400,
        duracionS: 360,
      );
      expect(r.resumen, '1.4 km · 6 min');
    });
  });

  group('Motorizado.tipo', () {
    test('default es motorizado con perfil driving', () {
      final m = Motorizado.fromJson({'id': 1, 'nombre': 'Ana', 'sede': 'Lima'});
      expect(m.esDelivery, false);
      expect(m.rutaProfile, 'driving');
    });

    test('detecta delivery y usa perfil cycling', () {
      final m = Motorizado.fromJson(
          {'id': 2, 'nombre': 'Beto', 'sede': 'Lima', 'tipo': 'delivery'});
      expect(m.esDelivery, true);
      expect(m.rutaProfile, 'cycling');
    });
  });
}
