class GpsRuta {
  final int id;
  final String status;
  final String? startedAt;
  final double distanceKm;

  GpsRuta({
    required this.id,
    required this.status,
    this.startedAt,
    required this.distanceKm,
  });

  factory GpsRuta.fromJson(Map<String, dynamic> json) {
    return GpsRuta(
      id: json['id'],
      status: json['status'],
      startedAt: json['started_at'],
      distanceKm: double.parse((json['distance_km'] ?? 0).toString()),
    );
  }

  bool get activa => status == 'activa';
}
