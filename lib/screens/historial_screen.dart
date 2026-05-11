import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
        _rutas   = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<List<dynamic>> historialKm() async {
    // Endpoint historial del motorizado autenticado
    final api = ApiService();
    final res = await api.entregasHoy(); // placeholder
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f2f5),
      appBar: AppBar(
        title: const Text('Historial de Km'),
        backgroundColor: const Color(0xFF1a2035),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _cargar,
            child: _rutas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Sin rutas registradas',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rutas.length,
                  itemBuilder: (_, i) {
                    final r = _rutas[i];
                    return _buildRutaCard(r);
                  },
                ),
          ),
    );
  }

  Widget _buildRutaCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a73e8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.route,
                    color: Color(0xFF1a73e8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['fecha'] ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${r['started_at'] ?? '--'} → ${r['ended_at'] ?? '--'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Km destacado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${r['distance_km']} km',
                      style: const TextStyle(
                        color: Color(0xFF1a73e8),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      r['duracion'] ?? '—',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Completadas', '${r['completadas']}', Colors.green),
                _stat('Fallidas',    '${r['fallidas']}',    Colors.red),
                _stat('Total',       '${r['total']}',       Colors.grey),
              ],
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
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }
}