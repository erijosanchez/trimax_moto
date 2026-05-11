import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        headers: {
          ...ApiConfig.headers,
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('motorizado');
    _dio.options.headers.remove('Authorization');
  }

  // ── Auth ──────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post(
      '/motorizado/login',
      data: {'email': email, 'password': password},
    );
    return res.data;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/motorizado/logout');
    } catch (_) {}
    await clearToken();
  }

  // ── GPS ───────────────────────────────────────────────
  Future<Map<String, dynamic>> iniciarRuta() async {
    final res = await _dio.post('/gps/iniciar');
    return res.data;
  }

  Future<Map<String, dynamic>> enviarPosicion({
    required int rutaId,
    required double lat,
    required double lng,
    required double velocidad,
    required double precision,
  }) async {
    final now = DateTime.now().toLocal();
    final res = await _dio.post(
      '/gps/posicion',
      data: {
        'ruta_id': rutaId,
        'latitud': lat,
        'longitud': lng,
        'velocidad': velocidad,
        'precision': precision,
        'capturado_en':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
      },
    );
    return res.data;
  }

  Future<Map<String, dynamic>> finalizarRuta(int rutaId) async {
    final res = await _dio.post('/gps/finalizar', data: {'ruta_id': rutaId});
    return res.data;
  }

  Future<Map<String, dynamic>?> rutaActiva() async {
    final res = await _dio.get('/gps/ruta-activa');
    return res.data['ruta'];
  }

  // ── Entregas ──────────────────────────────────────────
  Future<Map<String, dynamic>> entregasHoy() async {
    final res = await _dio.get('/entregas/hoy');
    return res.data;
  }

  Future<void> completarEntrega({
    required int id,
    double? lat,
    double? lng,
    String? notas,
  }) async {
    await _dio.post(
      '/entregas/$id/completar',
      data: {
        if (lat != null) 'latitud': lat,
        if (lng != null) 'longitud': lng,
        if (notas != null) 'notas': notas,
      },
    );
  }

  Future<void> fallarEntrega({required int id, String? notas}) async {
    await _dio.post(
      '/entregas/$id/fallar',
      data: {if (notas != null) 'notas': notas},
    );
  }

  Future<List<dynamic>> historialKm() async {
    final res = await _dio.get('/motorizado/historial');
    return res.data as List;
  }
}
