import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// ── Inicializar el servicio ───────────────────────────────
Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  // Canal de notificación Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'trimax_gps',
    'GPS Trimax',
    description: 'Tracking de ruta activa',
    importance: Importance.low,
  );

  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart:           onStart,
      autoStart:         false,
      isForegroundMode:  true,
      notificationChannelId: 'trimax_gps',
      initialNotificationTitle: 'Trimax GPS',
      initialNotificationContent: 'Registrando ruta...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart:   false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// ── iOS background handler ────────────────────────────────
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

// ── Lógica principal del servicio ─────────────────────────
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((_) {
    service.stopSelf();
  });

  // Actualizar notificación con km
  service.on('updateKm').listen((data) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Trimax GPS — En ruta 🏍️',
        content: 'Recorrido: ${data?['km'] ?? 0} km',
      );
    }
  });

  Position? ultimaPosicion;

  // Enviar posición cada 15 segundos
  Timer.periodic(const Duration(seconds: 5), (_) async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final rutaId  = prefs.getInt('ruta_id_activa');
      final token   = prefs.getString('token');

      if (rutaId == null || token == null) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Filtrar puntos con baja precisión
      if (pos.accuracy > 30) return;

      // Filtrar puntos muy cercanos
      if (ultimaPosicion != null) {
        final dist = Geolocator.distanceBetween(
          ultimaPosicion!.latitude,  ultimaPosicion!.longitude,
          pos.latitude,              pos.longitude,
        );
        if (dist < 3) return; // menos de 3 metros, ignorar
      }

      ultimaPosicion = pos;

      await ApiService().init();
      final data = await ApiService().enviarPosicion(
        rutaId:    rutaId,
        lat:       pos.latitude,
        lng:       pos.longitude,
        velocidad: pos.speed * 3.6,
        precision: pos.accuracy,
      );

      // Notificar km actualizado a la UI
      service.invoke('kmActualizado', {
        'km': data['distance_km'] ?? 0,
      });

      // Actualizar notificación
      service.invoke('updateKm', {
        'km': data['distance_km'] ?? 0,
      });

    } catch (_) {
      // Silencioso — reintentará en 15s
    }
  });
}