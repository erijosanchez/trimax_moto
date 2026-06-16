import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/entrega.dart';
import '../models/gps_ruta.dart';
import '../models/ruta_calculada.dart';
import '../services/gps_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/routing_service.dart';
import '../theme/app_theme.dart';
import 'dart:ui' as ui;

class MapaScreen extends StatefulWidget {
  final List<Entrega> entregas;
  final GpsRuta? rutaActiva;

  const MapaScreen({super.key, required this.entregas, this.rutaActiva});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();

  // Posición actual
  LatLng? _posActual;
  StreamSubscription<Position>? _posStream;

  // Polyline del recorrido en tiempo real (lo ya recorrido)
  final List<LatLng> _recorrido = [];

  // Ruta planificada hacia la siguiente entrega (por calles, OSRM)
  RutaCalculada? _rutaPlan;
  Entrega? _siguienteParada;
  bool _calculandoRuta = false;
  LatLng? _ultimoOrigenRuta; // para throttle de recálculo

  // Timer para refrescar km
  Timer? _kmTimer;
  double _distanciaKm = 0;

  @override
  void initState() {
    super.initState();
    _distanciaKm = widget.rutaActiva?.distanceKm ?? 0;
    _siguienteParada = _calcularSiguienteParada();
    _iniciarSeguimiento();
    if (widget.rutaActiva?.activa == true) {
      _iniciarTimerKm();
    }
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _kmTimer?.cancel();
    super.dispose();
  }

  // ── Siguiente parada = primera pendiente con coords, por orden ─────
  Entrega? _calcularSiguienteParada() {
    final pendientes = widget.entregas
        .where((e) => e.pendiente && e.latitud != null && e.longitud != null)
        .toList()
      ..sort((a, b) => a.ordenSecuencia.compareTo(b.ordenSecuencia));
    return pendientes.isEmpty ? null : pendientes.first;
  }

  // ── Seguimiento GPS en tiempo real ────────────────────
  Future<void> _iniciarSeguimiento() async {
    final tienePermiso = await GpsService().verificarPermisos();
    if (!tienePermiso) return;

    // Posición inicial
    final pos = await GpsService().obtenerPosicionActual();
    if (pos != null && mounted) {
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _posActual = latlng;
        _recorrido.add(latlng);
      });
      _mapController.move(latlng, 15);
      _recalcularRuta(latlng, force: true);
    }

    // Stream de posiciones
    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      if (!mounted) return;
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _posActual = latlng;
        _recorrido.add(latlng);
      });
      _recalcularRuta(latlng);
    });
  }

  // ── Calcular ruta por calles hacia la siguiente parada ────
  // Throttle: solo recalcula si nos movimos > 50 m o si se forzó.
  Future<void> _recalcularRuta(LatLng origen, {bool force = false}) async {
    final destino = _siguienteParada;
    if (destino == null || destino.latitud == null || destino.longitud == null) {
      return;
    }
    if (_calculandoRuta) return;

    if (!force && _ultimoOrigenRuta != null) {
      final movido = const Distance().as(
        LengthUnit.Meter,
        _ultimoOrigenRuta!,
        origen,
      );
      if (movido < 50) return;
    }

    _calculandoRuta = true;
    final profile = AuthService().motorizado?.rutaProfile ?? 'driving';
    final ruta = await RoutingService().calcular(
      origen: origen,
      destino: LatLng(destino.latitud!, destino.longitud!),
      profile: profile,
    );

    if (!mounted) {
      _calculandoRuta = false;
      return;
    }
    setState(() {
      _rutaPlan = ruta;
      _ultimoOrigenRuta = origen;
      _calculandoRuta = false;
    });
  }

  // ── Refrescar km cada 15s ─────────────────────────────
  void _iniciarTimerKm() {
    _kmTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final data = await ApiService().rutaActiva();
        if (data != null && mounted) {
          setState(() {
            _distanciaKm = double.parse((data['distance_km'] ?? 0).toString());
          });
        }
      } catch (_) {}
    });
  }

  // ── Centrar en posición actual ────────────────────────
  void _centrar() {
    if (_posActual != null) {
      _mapController.move(_posActual!, 16);
    }
  }

  // ── Encuadrar ruta + posición ─────────────────────────
  void _encuadrarRuta() {
    final puntos = <LatLng>[
      ?_posActual,
      if (_siguienteParada?.latitud != null)
        LatLng(_siguienteParada!.latitud!, _siguienteParada!.longitud!),
      ...?_rutaPlan?.puntos,
    ];
    if (puntos.length < 2) {
      _centrar();
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: puntos,
        padding: const EdgeInsets.only(left: 50, right: 50, top: 120, bottom: 240),
      ),
    );
  }

  // ── Ir a entrega en el mapa ───────────────────────────
  void _irAEntrega(Entrega e) {
    if (e.latitud != null && e.longitud != null) {
      _mapController.move(LatLng(e.latitud!, e.longitud!), 16);
    }
  }

  // ── Abrir navegación externa (Google Maps / Waze) ─────
  Future<void> _navegar(Entrega e) async {
    if (e.latitud == null || e.longitud == null) return;
    final esDelivery = AuthService().motorizado?.esDelivery ?? false;
    final modo = esDelivery ? 'bicycling' : 'driving';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${e.latitud},${e.longitud}'
      '&travelmode=$modo',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la app de mapas'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Mapa ────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _posActual ?? const LatLng(-12.046374, -77.042793),
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Tiles OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trimax.moto',
              ),

              // Ruta planificada hacia la siguiente parada (por calles)
              if (_rutaPlan != null && _rutaPlan!.puntos.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _rutaPlan!.puntos,
                      color: AppColors.primary.withValues(alpha: 0.25),
                      strokeWidth: 11,
                    ),
                    Polyline(
                      points: _rutaPlan!.puntos,
                      color: AppColors.primary,
                      strokeWidth: 5,
                    ),
                  ],
                ),

              // Polyline recorrido real — estilo Didi/Rappi
              if (_recorrido.length > 1) ...[
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _recorrido,
                      color: Colors.black.withValues(alpha: 0.12),
                      strokeWidth: 9,
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _recorrido,
                      color: Colors.white,
                      strokeWidth: 6,
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _recorrido,
                      color: AppColors.success,
                      strokeWidth: 3.5,
                    ),
                  ],
                ),
              ],

              // Marcadores de paradas
              MarkerLayer(
                markers: [
                  ...widget.entregas
                      .where((e) => e.latitud != null && e.longitud != null)
                      .map(
                        (e) => Marker(
                          point: LatLng(e.latitud!, e.longitud!),
                          width: 40,
                          height: 44,
                          child: _buildPinParada(e),
                        ),
                      ),

                  // Posición actual — repartidor pulsante
                  if (_posActual != null)
                    Marker(
                      point: _posActual!,
                      width: 60,
                      height: 60,
                      child: _buildMotoMarker(),
                    ),
                ],
              ),
            ],
          ),

          // ── Header ──────────────────────────────────────
          _buildHeader(),

          // ── Tarjeta siguiente parada + ETA ──────────────
          _buildPanelInferior(),

          // ── Botones flotantes ───────────────────────────
          Positioned(
            bottom: 215,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'fit',
                  onPressed: _encuadrarRuta,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.zoom_out_map,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'center',
                  onPressed: _centrar,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header superior ───────────────────────────────────
  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Mapa de ruta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.rutaActiva?.activa == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accentGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            color: AppColors.accentGreen, size: 8),
                        const SizedBox(width: 6),
                        Text(
                          '${_distanciaKm.toStringAsFixed(2)} km',
                          style: const TextStyle(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Panel inferior: siguiente parada + ETA + chips ────
  Widget _buildPanelInferior() {
    final sig = _siguienteParada;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: AppShadows.floating,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Tarjeta de la siguiente parada
            if (sig != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSiguienteCard(sig),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 10),
                    Text(
                      'Sin paradas pendientes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Carrusel de paradas
            SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.entregas.length,
                itemBuilder: (_, i) {
                  final e = widget.entregas[i];
                  return GestureDetector(
                    onTap: () => _irAEntrega(e),
                    child: _buildParadaChip(e),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSiguienteCard(Entrega sig) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SIGUIENTE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (_calculandoRuta)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_rutaPlan != null)
                Row(
                  children: [
                    const Icon(Icons.near_me,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      _rutaPlan!.resumen,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sig.clienteNombre,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sig.direccion,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navegar(sig),
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Navegar'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Marcador repartidor pulsante ──────────────────────
  Widget _buildMotoMarker() {
    final icono = AuthService().motorizado?.icono ?? Icons.delivery_dining;
    return Stack(
      alignment: Alignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.3),
          duration: const Duration(seconds: 2),
          builder: (_, val, child) => Transform.scale(
            scale: val,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.3 * (1.3 - val)),
              ),
            ),
          ),
          onEnd: () => setState(() {}),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icono, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  // ── Pin de parada ─────────────────────────────────────
  Widget _buildPinParada(Entrega e) {
    Color color;
    String label;

    switch (e.estado) {
      case 'completado':
        color = AppColors.success;
        label = '✓';
        break;
      case 'fallido':
        color = AppColors.danger;
        label = '✗';
        break;
      default:
        color = AppColors.primary;
        label = '${e.ordenSecuencia}';
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: CustomPaint(
            size: const Size(12, 8),
            painter: _PinPainter(color),
          ),
        ),
      ],
    );
  }

  // ── Chip de parada en panel inferior ──────────────────
  Widget _buildParadaChip(Entrega e) {
    Color color;
    switch (e.estado) {
      case 'completado':
        color = AppColors.success;
        break;
      case 'fallido':
        color = AppColors.danger;
        break;
      default:
        color = AppColors.primary;
    }

    final esSiguiente = identical(e, _siguienteParada);

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: esSiguiente ? AppColors.primary : AppColors.border,
          width: esSiguiente ? 1.6 : 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    e.completado
                        ? '✓'
                        : e.fallido
                            ? '✗'
                            : '${e.ordenSecuencia}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.clienteNombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            e.direccion,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Pintor punta del pin ──────────────────────────────────
class _PinPainter extends CustomPainter {
  final Color color;
  _PinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
