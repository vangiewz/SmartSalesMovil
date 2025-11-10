// lib/models/carrito_voz.dart

class CarritoVozProductoOpcion {
  final int productoId;
  final String nombre;
  final String precioUnitario;

  CarritoVozProductoOpcion({
    required this.productoId,
    required this.nombre,
    required this.precioUnitario,
  });

  factory CarritoVozProductoOpcion.fromJson(Map<String, dynamic> json) {
    return CarritoVozProductoOpcion(
      productoId: json['producto_id'] as int,
      nombre: json['nombre'] as String,
      precioUnitario: json['precio_unitario'] as String,
    );
  }
}

class CarritoVozItem {
  final int productoId;
  final String nombre;
  final int cantidad;
  final String precioUnitario;
  final String subtotal;
  final String fragmentoVoz;
  final List<CarritoVozProductoOpcion> opciones;

  CarritoVozItem({
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.fragmentoVoz,
    required this.opciones,
  });

  factory CarritoVozItem.fromJson(Map<String, dynamic> json) {
    final opcionesJson = json['opciones'] as List<dynamic>?;
    return CarritoVozItem(
      productoId: json['producto_id'] as int,
      nombre: json['nombre'] as String,
      cantidad: json['cantidad'] as int,
      precioUnitario: json['precio_unitario'] as String,
      subtotal: json['subtotal'] as String,
      fragmentoVoz: json['fragmento_voz'] as String,
      opciones: opcionesJson == null
          ? []
          : opcionesJson
              .map((e) => CarritoVozProductoOpcion.fromJson(e))
              .toList(),
    );
  }
}

class CarritoVozResponse {
  final String usuarioId;
  final String texto;
  final String totalEstimado;
  final List<CarritoVozItem> items;
  final List<String> fragmentosSinMatch;
  final String? mensaje;

  CarritoVozResponse({
    required this.usuarioId,
    required this.texto,
    required this.totalEstimado,
    required this.items,
    required this.fragmentosSinMatch,
    this.mensaje,
  });

  factory CarritoVozResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final fragmentosJson = json['fragmentos_sin_match'] as List<dynamic>? ?? [];

    return CarritoVozResponse(
      usuarioId: json['usuario_id'] as String,
      texto: json['texto'] as String,
      totalEstimado: json['total_estimado'] as String,
      items: itemsJson.map((e) => CarritoVozItem.fromJson(e)).toList(),
      fragmentosSinMatch: fragmentosJson.map((e) => e.toString()).toList(),
      mensaje: json['mensaje'] as String?,
    );
  }
}
