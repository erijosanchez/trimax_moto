import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ticket_stub.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<dynamic> _rutas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().historialKm();
      setState(() {
        _rutas = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  double get _totalKm {
    double total = 0;
    for (final r in _rutas) {
      total += double.tryParse('${r['distance_km'] ?? 0}') ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.board,
      appBar: AppBar(title: const Text('Historial de Km')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
          : RefreshIndicator(
              color: AppColors.amberDeep,
              onRefresh: _cargar,
              child: _rutas.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        const Icon(Icons.route_outlined,
                            size: 56, color: AppColors.inkFaint),
                        const SizedBox(height: 16),
                        Text(
                          'SIN RUTAS REGISTRADAS',
                          textAlign: TextAlign.center,
                          style: AppFonts.mono(
                            color: AppColors.inkFaint,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildResumen(),
                        const SizedBox(height: 18),
                        ..._rutas.map((r) =>
                            _buildRutaCard(r as Map<String, dynamic>)),
                      ],
                    ),
            ),
    );
  }

  Widget _buildResumen() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.asphalt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          Expanded(
            child: MonoReadout(
              value: '${_rutas.length}',
              label: 'Rutas',
              valueColor: AppColors.amber,
              labelColor: Colors.white54,
              valueSize: 26,
              glow: true,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.asphaltLine,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: MonoReadout(
                value: _totalKm.toStringAsFixed(1),
                unit: 'km',
                label: 'Acumulado',
                valueColor: AppColors.amber,
                labelColor: Colors.white54,
                valueSize: 26,
                glow: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRutaCard(Map<String, dynamic> r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TicketStub(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.route, color: AppColors.amberDeep),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['fecha'] ?? '—',
                        style: AppFonts.display(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${r['started_at'] ?? '--'} → ${r['ended_at'] ?? '--'}',
                        style: AppFonts.mono(
                          color: AppColors.inkSoft,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                MonoReadout(
                  value: '${r['distance_km']}',
                  unit: 'km',
                  label: r['duracion'] ?? '—',
                  valueColor: AppColors.amberDeep,
                  labelColor: AppColors.inkFaint,
                  valueSize: 19,
                ),
              ],
            ),
            const PerforatedDivider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('Completadas', '${r['completadas']}', AppColors.route),
                  _stat('Fallidas', '${r['fallidas']}', AppColors.fail),
                  _stat('Total', '${r['total']}', AppColors.inkSoft),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String valor, Color color) {
    return Column(
      children: [
        Text(
          valor,
          style: AppFonts.mono(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: AppFonts.mono(
            color: AppColors.inkFaint,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
