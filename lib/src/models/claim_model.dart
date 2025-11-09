class ClaimModel {
  final int garantiaId;
  final int ventaId;
  final int productoId;
  final String estado;
  final int cantidad;
  final String motivo;
  final String hora;

  ClaimModel({
    required this.garantiaId,
    required this.ventaId,
    required this.productoId,
    required this.estado,
    required this.cantidad,
    required this.motivo,
    required this.hora,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      garantiaId: json['garantia_id'] as int,
      ventaId: json['venta_id'] as int,
      productoId: json['producto_id'] as int,
      estado: json['estado'] as String,
      cantidad: json['cantidad'] as int,
      motivo: json['motivo'] as String,
      hora: json['hora'] as String,
    );
  }
}
