/// Modelo para un rol de usuario
class RolUsuario {
  final int rolId;
  final String rolNombre;
  final bool esActivo;

  RolUsuario({
    required this.rolId,
    required this.rolNombre,
    required this.esActivo,
  });

  factory RolUsuario.fromJson(Map<String, dynamic> json) {
    return RolUsuario(
      rolId: json['rol_id'] as int,
      rolNombre: json['rol_nombre'] as String,
      esActivo: json['es_activo'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'rol_id': rolId,
    'rol_nombre': rolNombre,
    'es_activo': esActivo,
  };
}

/// Respuesta del endpoint /api/rolesusuario/me/
class RolesResponse {
  final String userId;
  final String correo;
  final String nombre;
  final String? telefono;
  final List<String> roles;
  final List<int> rolesIds;
  final bool tieneRolAdmin;
  final bool tieneRolVendedor;
  final bool tieneRolAnalista;
  final bool tieneRolUsuario;

  RolesResponse({
    required this.userId,
    required this.correo,
    required this.nombre,
    this.telefono,
    required this.roles,
    required this.rolesIds,
    required this.tieneRolAdmin,
    required this.tieneRolVendedor,
    required this.tieneRolAnalista,
    required this.tieneRolUsuario,
  });

  factory RolesResponse.fromJson(Map<String, dynamic> json) {
    // Los roles vienen como array de strings: ["Cliente", "Administrador"]
    final rolesList = (json['roles'] as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    // Los IDs vienen como array de ints: [1, 2, 4, 5]
    final rolesIdsList = (json['roles_ids'] as List<dynamic>)
        .map((e) => e as int)
        .toList();

    return RolesResponse(
      userId: json['user_id'] as String,
      correo: json['correo'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      roles: rolesList,
      rolesIds: rolesIdsList,
      tieneRolAdmin: json['is_admin'] as bool? ?? false,
      tieneRolVendedor: json['is_vendedor'] as bool? ?? false,
      tieneRolAnalista: json['is_analista'] as bool? ?? false,
      tieneRolUsuario: json['is_usuario'] as bool? ?? false,
    );
  }

  /// Verifica si el usuario puede acceder al dashboard ejecutivo
  /// Admin (rol_id = 2) o Analista (rol_id = 3)
  bool get puedeAccederDashboardEjecutivo => tieneRolAnalista || tieneRolAdmin;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'correo': correo,
    'nombre': nombre,
    'telefono': telefono,
    'roles': roles,
    'roles_ids': rolesIds,
    'is_admin': tieneRolAdmin,
    'is_vendedor': tieneRolVendedor,
    'is_analista': tieneRolAnalista,
    'is_usuario': tieneRolUsuario,
  };
}
