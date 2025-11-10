/// KPI individual del dashboard
class KPI {
  final String titulo;
  final String valor;
  final double? cambioPorcentual;
  final String? tendencia;
  final String icono;

  KPI({
    required this.titulo,
    required this.valor,
    this.cambioPorcentual,
    this.tendencia,
    required this.icono,
  });

  factory KPI.fromJson(Map<String, dynamic> json) {
    return KPI(
      titulo: json['titulo'] as String,
      valor: json['valor'] as String,
      cambioPorcentual: json['cambio_porcentual'] != null
          ? _parseDouble(json['cambio_porcentual'])
          : null,
      tendencia: json['tendencia'] as String?,
      icono: json['icono'] as String,
    );
  }
}

/// Helper para parsear doubles de forma segura
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Helper para parsear ints de forma segura
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Ventas por día
class VentasPorDia {
  final DateTime fecha;
  final int totalVentas;
  final double montoTotal;

  VentasPorDia({
    required this.fecha,
    required this.totalVentas,
    required this.montoTotal,
  });

  factory VentasPorDia.fromJson(Map<String, dynamic> json) {
    return VentasPorDia(
      fecha: DateTime.parse(json['fecha'] as String),
      totalVentas: _parseInt(json['total_ventas']),
      montoTotal: _parseDouble(json['monto_total']),
    );
  }
}

/// Producto más vendido
class ProductoTop {
  final int productoId;
  final String nombre;
  final int cantidadVendida;
  final double montoTotal;
  final String marca;

  ProductoTop({
    required this.productoId,
    required this.nombre,
    required this.cantidadVendida,
    required this.montoTotal,
    required this.marca,
  });

  factory ProductoTop.fromJson(Map<String, dynamic> json) {
    return ProductoTop(
      productoId: _parseInt(json['producto_id']),
      nombre: json['nombre'] as String,
      cantidadVendida: _parseInt(json['cantidad_vendida']),
      montoTotal: _parseDouble(json['monto_total']),
      marca: json['marca'] as String,
    );
  }
}

/// Cliente top
class ClienteTop {
  final String clienteId;
  final String nombre;
  final String correo;
  final int totalCompras;
  final double montoTotal;

  ClienteTop({
    required this.clienteId,
    required this.nombre,
    required this.correo,
    required this.totalCompras,
    required this.montoTotal,
  });

  factory ClienteTop.fromJson(Map<String, dynamic> json) {
    return ClienteTop(
      clienteId: json['cliente_id'] as String,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      totalCompras: _parseInt(json['total_compras']),
      montoTotal: _parseDouble(json['monto_total']),
    );
  }
}

/// Ventas por categoría
class VentasPorCategoria {
  final String categoria;
  final int cantidad;
  final double monto;
  final double porcentaje;

  VentasPorCategoria({
    required this.categoria,
    required this.cantidad,
    required this.monto,
    required this.porcentaje,
  });

  factory VentasPorCategoria.fromJson(Map<String, dynamic> json) {
    return VentasPorCategoria(
      categoria: json['categoria'] as String,
      cantidad: _parseInt(json['cantidad']),
      monto: _parseDouble(json['monto']),
      porcentaje: _parseDouble(json['porcentaje']),
    );
  }
}

/// Alerta del sistema
class Alerta {
  final String tipo;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String severidad;

  Alerta({
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.severidad,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      severidad: json['severidad'] as String,
    );
  }
}

/// Resumen general del sistema
class ResumenGeneral {
  final int totalProductos;
  final int totalUsuarios;
  final int totalVendedores;
  final double valorInventario;

  ResumenGeneral({
    required this.totalProductos,
    required this.totalUsuarios,
    required this.totalVendedores,
    required this.valorInventario,
  });

  factory ResumenGeneral.fromJson(Map<String, dynamic> json) {
    return ResumenGeneral(
      totalProductos: _parseInt(json['total_productos']),
      totalUsuarios: _parseInt(json['total_usuarios']),
      totalVendedores: _parseInt(json['total_vendedores']),
      valorInventario: _parseDouble(json['valor_inventario']),
    );
  }
}

/// Datos completos del dashboard ejecutivo
class DashboardData {
  final String periodo;
  final DateTime fechaActualizacion;
  final List<KPI> kpis;
  final List<VentasPorDia> ventasPorDia;
  final List<ProductoTop> productosMasVendidos;
  final List<VentasPorCategoria> ventasPorCategoria;
  final List<ClienteTop> mejoresClientes;
  final List<Alerta> alertas;
  final ResumenGeneral resumen;

  DashboardData({
    required this.periodo,
    required this.fechaActualizacion,
    required this.kpis,
    required this.ventasPorDia,
    required this.productosMasVendidos,
    required this.ventasPorCategoria,
    required this.mejoresClientes,
    required this.alertas,
    required this.resumen,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      periodo: json['periodo'] as String,
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion'] as String),
      kpis: (json['kpis'] as List<dynamic>)
          .map((e) => KPI.fromJson(e as Map<String, dynamic>))
          .toList(),
      ventasPorDia: (json['ventas_por_dia'] as List<dynamic>)
          .map((e) => VentasPorDia.fromJson(e as Map<String, dynamic>))
          .toList(),
      productosMasVendidos: (json['productos_mas_vendidos'] as List<dynamic>)
          .map((e) => ProductoTop.fromJson(e as Map<String, dynamic>))
          .toList(),
      ventasPorCategoria: (json['ventas_por_categoria'] as List<dynamic>)
          .map((e) => VentasPorCategoria.fromJson(e as Map<String, dynamic>))
          .toList(),
      mejoresClientes: (json['mejores_clientes'] as List<dynamic>)
          .map((e) => ClienteTop.fromJson(e as Map<String, dynamic>))
          .toList(),
      alertas: (json['alertas'] as List<dynamic>)
          .map((e) => Alerta.fromJson(e as Map<String, dynamic>))
          .toList(),
      resumen: ResumenGeneral.fromJson(json['resumen'] as Map<String, dynamic>),
    );
  }
}
