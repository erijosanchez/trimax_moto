import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import '../models/entrega.dart';
import '../models/gps_ruta.dart';
import '../services/gps_service.dart';
import '../services/api_service.dart';
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

  // Polyline del recorrido en tiempo real
  final List<LatLng> _recorrido = [];

  // Timer para refrescar km
  Timer? _kmTimer;
  double _distanciaKm = 0;

  @override
  void initState() {
    super.initState();
    _distanciaKm = widget.rutaActiva?.distanceKm ?? 0;
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
    }

    // Stream de posiciones
    _posStream =
        Geolocator.getPositionStream(
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

  // ── Ir a entrega en el mapa ───────────────────────────
  void _irAEntrega(Entrega e) {
    if (e.latitud != null && e.longitud != null) {
      _mapController.move(LatLng(e.latitud!, e.longitud!), 16);
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

              // Polyline recorrido real — 3 capas estilo Didi/Rappi
              if (_recorrido.length > 1) ...[
                // Capa 1 — sombra
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _recorrido,
                      color: Colors.black.withOpacity(0.15),
                      strokeWidth: 10,
                    ),
                  ],
                ),
                // Capa 2 — borde blanco
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _recorrido,
                      color: Colors.white,
                      strokeWidth: 7,
                    ),
                  ],
                ),
                // Capa 3 — línea principal azul
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _recorrido,
                      color: const Color(0xFF1a73e8),
                      strokeWidth: 4,
                    ),
                  ],
                ),
              ],

              // Marcadores de paradas
              MarkerLayer(
                markers: [
                  // Paradas
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

                  // Posición actual — moto pulsante
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1a2035), Color(0xFF0d47a1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.rutaActiva?.activa == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4cff91).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF4cff91).withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Color(0xFF4cff91),
                                size: 8,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_distanciaKm.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  color: Color(0xFF4cff91),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Panel inferior de paradas ────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
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
                ],
              ),
            ),
          ),

          // ── Botón centrar ────────────────────────────────
          Positioned(
            bottom: 180,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _centrar,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Color(0xFF1a73e8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Marcador moto pulsante ────────────────────────────
  Widget _buildMotoMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Anillo pulsante
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.3),
          duration: const Duration(seconds: 2),
          builder: (_, val, __) => Transform.scale(
            scale: val,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1a73e8).withOpacity(0.3 * (1.3 - val)),
              ),
            ),
          ),
          onEnd: () => setState(() {}),
        ),
        // Ícono moto
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF1a73e8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x661a73e8),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.delivery_dining,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    );
  }

  // ── Chip de parada en panel inferior ─────────────────
  Widget _buildPinParada(Entrega e) {
    Color color;
    String label;

    switch (e.estado) {
      case 'completado':
        color = Colors.green;
        label = '✓';
        break;
      case 'fallido':
        color = Colors.red;
        label = '✗';
        break;
      default:
        color = const Color(0xFF1a73e8);
        label = '${e.ordenSecuencia}';
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Círculo principal
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
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
        // Punta del pin
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
}

Widget _buildParadaChip(Entrega e) {
  Color color;
  switch (e.estado) {
    case 'completado': color = Colors.green; break;
    case 'fallido':    color = Colors.red;   break;
    default:           color = const Color(0xFF1a73e8);
  }

  return Container(
    width: 200,
    margin: const EdgeInsets.only(right: 12, bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                e.completado ? '✓' : e.fallido ? '✗' : '${e.ordenSecuencia}',
                style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              e.clienteNombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          e.direccion,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
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
