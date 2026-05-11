class Entrega {
  final int id;
  final String clienteNombre;
  final String? clienteTelefono;
  final String? referencia;
  final String direccion;
  final double? latitud;
  final double? longitud;
  final int ordenSecuencia;
  String estado;
  final String? notas;

  Entrega({
    required this.id,
    required this.clienteNombre,
    this.clienteTelefono,
    this.referencia,
    required this.direccion,
    this.latitud,
    this.longitud,
    required this.ordenSecuencia,
    required this.estado,
    this.notas,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) {
    return Entrega(
      id: json['id'],
      clienteNombre: json['cliente_nombre'],
      clienteTelefono: json['cliente_telefono'],
      referencia: json['referencia'],
      direccion: json['direccion'],
      latitud: json['latitud'] != null
          ? double.parse(json['latitud'].toString())
          : null,
      longitud: json['longitud'] != null
          ? double.parse(json['longitud'].toString())
          : null,
      ordenSecuencia: json['orden_secuencia'],
      estado: json['estado'],
      notas: json['notas'],
    );
  }

  bool get pendiente => estado == 'pendiente';
  bool get completado => estado == 'completado';
  bool get fallido => estado == 'fallido';
}
