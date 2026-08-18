import 'package:flutter/material.dart';
import '../models/entrega.dart';
import '../models/gps_ruta.dart';
import '../models/motorizado.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/gps_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrega_card.dart';
import '../widgets/ticket_stub.dart';
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
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text('¿Finalizar ruta?', style: AppFonts.display(fontSize: 18)),
        content: Text(
          'Se calcularán los km recorridos y se cerrará la ruta del día.',
          style: AppFonts.body(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.fail, foregroundColor: Colors.white),
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
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.route),
              const SizedBox(width: 8),
              Text('Ruta finalizada', style: AppFonts.display(fontSize: 18)),
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
          Text(label, style: AppFonts.body(color: AppColors.inkSoft)),
          Text(valor,
              style: AppFonts.mono(fontWeight: FontWeight.w700, color: AppColors.ink)),
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
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.ink,
      ),
    );
  }

  Widget _buildHeader(Motorizado? moto) {
    final completadas = _entregas.where((e) => e.completado).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 16),
      decoration: const BoxDecoration(color: AppColors.asphalt),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
            ),
            child: Icon(moto?.icono ?? Icons.delivery_dining,
                color: AppColors.amber, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moto?.nombre ?? '',
                  style: AppFonts.display(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${moto?.etiqueta.toUpperCase() ?? ''} · SEDE ${moto?.sede ?? ''}',
                  style: AppFonts.mono(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (_entregas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: MonoReadout(
                value: '$completadas/${_entregas.length}',
                label: 'entregas',
                valueColor: AppColors.amber,
                valueSize: 18,
              ),
            ),
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history, color: Colors.white54),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistorialScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildBarraGps() {
    final enRuta = _rutaActiva != null && _rutaActiva!.activa;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.asphaltPanel,
        border: Border(top: BorderSide(color: AppColors.asphaltLine)),
      ),
      child: Row(
        children: [
          Expanded(
            child: enRuta
                ? Row(
                    children: [
                      _PulsingDot(color: AppColors.route),
                      const SizedBox(width: 8),
                      MonoReadout(
                        value: (_distanciaKmLive > 0
                                ? _distanciaKmLive
                                : (_rutaActiva?.distanceKm ?? 0))
                            .toStringAsFixed(2),
                        unit: 'km',
                        label: 'GPS activo',
                        valueColor: AppColors.amber,
                        valueSize: 24,
                        glow: true,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS EN ESPERA',
                        style: AppFonts.mono(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Inicia para registrar km',
                        style: AppFonts.body(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
          ),
          _procesando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.amber,
                    strokeWidth: 2,
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: enRuta ? _finalizarRuta : _iniciarRuta,
                  icon: Icon(enRuta ? Icons.stop_circle : Icons.play_circle),
                  label: Text(enRuta ? 'Finalizar' : 'Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        enRuta ? AppColors.fail : AppColors.amber,
                    foregroundColor:
                        enRuta ? Colors.white : AppColors.ink,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return ListView(
      children: [
        const SizedBox(height: 90),
        const Icon(Icons.inbox_outlined, size: 56, color: AppColors.inkFaint),
        const SizedBox(height: 16),
        Text(
          'SIN ASIGNACIONES',
          textAlign: TextAlign.center,
          style: AppFonts.mono(
            color: AppColors.inkFaint,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sin entregas asignadas hoy.\nEl administrador debe asignarlas desde el CRM.',
          textAlign: TextAlign.center,
          style: AppFonts.body(color: AppColors.inkSoft, fontSize: 13),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
