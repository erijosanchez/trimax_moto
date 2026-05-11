import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> mostrarNuevaEntrega({
    required String cliente,
    required String direccion,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '📦 Nueva entrega asignada',
      '$cliente — $direccion',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'trimax_entregas',
          'Entregas Trimax',
          channelDescription: 'Notificaciones de nuevas entregas',
          importance: Importance.high,
          priority:   Priority.high,
          icon:       '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> mostrarGpsActivo(double km) async {
    await _plugin.show(
      888,
      '🏍️ Trimax GPS — En ruta',
      'Recorrido: ${km.toStringAsFixed(2)} km',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'trimax_gps',
          'GPS Trimax',
          channelDescription: 'GPS activo en ruta',
          importance:  Importance.low,
          priority:    Priority.low,
          ongoing:     true,
          icon:        '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}