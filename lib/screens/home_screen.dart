import 'package:flutter/material.dart';
import '../models/entrega.dart';
import '../models/gps_ruta.dart';
import '../models/motorizado.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/gps_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrega_card.dart';
import 'login_screen.dart';
import 'mapa_screen.dart';
import 'historial_screen.dart';
import 'dart:async';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Entrega> _entregas = [];
  GpsRuta? _rutaActiva;
  bool _loading = true;
  bool _procesando = false;
  StreamSubscription<double>? _kmSubscription;

  double _distanciaKmLive = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    // Escuchar km en tiempo real del background service
    _kmSubscription = GpsService().kmStream.listen((km) {
      if (mounted && _rutaActiva != null) {
        setState(() => _distanciaKmLive = km);
      }
    });
  }

  @override
  void dispose() {
    _kmSubscription?.cancel();
    super.dispose();
  }

  // ── Cargar entregas y ruta activa ─────────────────────
  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService().entregasHoy(),
        ApiService().rutaActiva(),
      ]);

      final dataEntregas = results[0] as Map<String, dynamic>;
      final dataRuta = results[1];

      final nuevasEntregas = (dataEntregas['entregas'] as List)
          .map((e) => Entrega.fromJson(e))
          .toList();

      // Notificar si hay entregas nuevas
      final cantAnterior = _entregas.length;
      if (nuevasEntregas.length > cantAnterior && cantAnterior > 0) {
        final nueva = nuevasEntregas.last;
        await NotificationService().mostrarNuevaEntrega(
          cliente: nueva.clienteNombre,
          direccion: nueva.direccion,
        );
      }

      setState(() {
        _entregas = nuevasEntregas;
        _rutaActiva = dataRuta != null ? GpsRuta.fromJson(dataRuta) : null;
        if (_rutaActiva != null && _rutaActiva!.activa) {
          GpsService().iniciar(_rutaActiva!.id);
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error al cargar datos.');
    }
  }

  // ── Iniciar ruta ──────────────────────────────────────
  Future<void> _iniciarRuta() async {
    setState(() => _procesando = true);
    try {
      final data = await ApiService().iniciarRuta();
      final rutaId = data['ruta_id'] as int;

      final iniciado = await GpsService().iniciar(rutaId);
      if (!iniciado) {
        _showError('No se pudo acceder al GPS. Verifica los permisos.');
        setState(() => _procesando = false);
        return;
      }

      await _cargarDatos();
      _showSnack('¡Ruta iniciada! GPS activo 🚀', AppColors.success);
    } catch (e) {
      _showError('Error al iniciar ruta.');
    } finally {
      setState(() => _procesando = false);
    }
  }

  // ── Finalizar ruta ────────────────────────────────────
  Future<void> _finalizarRuta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Finalizar ruta?'),
        content: const Text(
          'Se calcularán los km recorridos y se cerrará la ruta del día.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _procesando = true);
    try {
      final data = await ApiService().finalizarRuta(_rutaActiva!.id);
      await GpsService().detener();

      final km = data['distance_km'];
      final puntos = data['puntos'];

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Ruta finalizada'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statRow('Distancia total', '$km km'),
              _statRow('Puntos GPS', '$puntos registros'),
              _statRow(
                'Entregas ok',
                '${_entregas.where((e) => e.completado).length}',
              ),
              _statRow(
                'Fallidas',
                '${_entregas.where((e) => e.fallido).length}',
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cargarDatos();
              },
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Error al finalizar ruta.');
    } finally {
      setState(() => _procesando = false);
    }
  }

  Widget _statRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Marcar entrega ────────────────────────────────────
  Future<void> _marcarEntrega(Entrega entrega, String estado) async {
    final pos = await GpsService().obtenerPosicionActual();

    try {
      if (estado == 'completado') {
        await ApiService().completarEntrega(
          id: entrega.id,
          lat: pos?.latitude,
          lng: pos?.longitude,
        );
      } else {
        await ApiService().fallarEntrega(id: entrega.id);
      }

      setState(() => entrega.estado = estado);

      _showSnack(
        estado == 'completado'
            ? '✓ Entrega completada'
            : '✗ Marcada como fallida',
        estado == 'completado' ? AppColors.success : AppColors.danger,
      );
    } catch (e) {
      _showError('Error al guardar. Verifica tu conexión.');
    }
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> _logout() async {
    await GpsService().detener();
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _showError(String msg) => _showSnack(msg, AppColors.danger);

  // ── UI ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final moto = AuthService().motorizado;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(moto),
            _buildBarraGps(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _cargarDatos,
                      child: _entregas.isEmpty
                          ? _buildVacio()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _entregas.length,
                              itemBuilder: (_, i) => EntregaCard(
                                entrega: _entregas[i],
                                onCompletar: () =>
                                    _marcarEntrega(_entregas[i], 'completado'),
                                onFallar: () =>
                                    _marcarEntrega(_entregas[i], 'fallido'),
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MapaScreen(entregas: _entregas, rutaActiva: _rutaActiva),
          ),
        ),
        icon: const Icon(Icons.map),
        label: const Text('Ver mapa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(Motorizado? moto) {
    final completadas = _entregas.where((e) => e.completado).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 16),
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(moto?.icono ?? Icons.delivery_dining,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moto?.nombre ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${moto?.etiqueta ?? ''} · Sede ${moto?.sede ?? ''} · ${_entregas.length} entregas',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_entregas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$completadas/${_entregas.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'completadas',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistorialScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildBarraGps() {
    final enRuta = _rutaActiva != null && _rutaActiva!.activa;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.navy,
      child: Row(
        children: [
          Expanded(
            child: enRuta
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'GPS activo',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_distanciaKmLive > 0 ? _distanciaKmLive.toStringAsFixed(2) : (_rutaActiva?.distanceKm ?? 0).toStringAsFixed(2)} km recorridos',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS no iniciado',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11),
                      ),
                      Text(
                        'Inicia para registrar km',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13),
                      ),
                    ],
                  ),
          ),
          _procesando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: enRuta ? _finalizarRuta : _iniciarRuta,
                  icon: Icon(enRuta ? Icons.stop_circle : Icons.play_circle),
                  label: Text(enRuta ? 'Finalizar' : 'Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        enRuta ? AppColors.danger : AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return ListView(
      children: const [
        SizedBox(height: 90),
        Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
        SizedBox(height: 16),
        Text(
          'Sin entregas asignadas hoy',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          'El administrador debe asignar entregas\ndesde el CRM',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}
