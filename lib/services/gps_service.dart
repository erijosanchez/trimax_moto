import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  bool _activo = false;
  bool get activo => _activo;

  final _kmController = StreamController<double>.broadcast();
  Stream<double> get kmStream => _kmController.stream;

  Future<bool> verificarPermisos() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<bool> iniciar(int rutaId) async {
    final tienePermiso = await verificarPermisos();
    if (!tienePermiso) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ruta_id_activa', rutaId);

    final service = FlutterBackgroundService();
    await service.startService();

    service.on('kmActualizado').listen((data) {
      if (data != null) {
        _kmController.add(
          double.parse((data['km'] ?? 0).toString())
        );
      }
    });

    _activo = true;
    return true;
  }

  Future<Position?> obtenerPosicionActual() async {
    final tienePermiso = await verificarPermisos();
    if (!tienePermiso) return null;
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> detener() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    _activo = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ruta_id_activa');
  }

  Future<int?> rutaIdGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ruta_id_activa');
  }
}