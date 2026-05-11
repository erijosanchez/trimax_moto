class Motorizado {
  final int id;
  final String nombre;
  final String sede;
  final String? telefono;

  Motorizado({
    required this.id,
    required this.nombre,
    required this.sede,
    this.telefono,
  });

  factory Motorizado.fromJson(Map<String, dynamic> json) {
    return Motorizado(
      id: json['id'],
      nombre: json['nombre'],
      sede: json['sede'],
      telefono: json['telefono'],
    );
  }
}
