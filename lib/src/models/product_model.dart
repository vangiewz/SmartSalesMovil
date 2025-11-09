class ProductModel {
  final int id;
  final String nombre;
  final double precio;
  final int stock;
  final int tiempogarantia;
  final String? imagenUrl;
  final Map<String, dynamic>? marca;
  final Map<String, dynamic>? tipoproducto;
  final Map<String, dynamic>? vendedor;

  ProductModel({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.tiempogarantia,
    this.imagenUrl,
    this.marca,
    this.tipoproducto,
    this.vendedor,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      precio: (json['precio'] is String)
          ? double.parse(json['precio'])
          : (json['precio'] as num).toDouble(),
      stock: json['stock'] as int,
      tiempogarantia: json['tiempogarantia'] as int,
      imagenUrl: json['imagen_url'] as String?,
      marca: json['marca'] as Map<String, dynamic>?,
      tipoproducto: json['tipoproducto'] as Map<String, dynamic>?,
      vendedor: json['vendedor'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'precio': precio,
    'stock': stock,
    'tiempogarantia': tiempogarantia,
    'imagen_url': imagenUrl,
    'marca': marca,
    'tipoproducto': tipoproducto,
    'vendedor': vendedor,
  };
}
