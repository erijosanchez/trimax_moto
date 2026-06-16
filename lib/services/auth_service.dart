import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/motorizado.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Motorizado? _motorizado;
  Motorizado? get motorizado => _motorizado;
  bool get isLoggedIn => _motorizado != null;

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final motoJson = prefs.getString('motorizado');

    if (token == null || motoJson == null) return false;

    await ApiService().init();
    await ApiService().setToken(token);
    _motorizado = Motorizado.fromJson(jsonDecode(motoJson));
    return true;
  }

  Future<Motorizado> login(String email, String password) async {
    await ApiService().init();
    final data = await ApiService().login(email, password);

    final token = data['token'];
    final moto  = Motorizado.fromJson(data['motorizado']);

    await ApiService().setToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('motorizado', jsonEncode(moto.toJson()));

    _motorizado = moto;
    return moto;
  }

  Future<void> logout() async {
    await ApiService().logout();
    _motorizado = null;
  }
}