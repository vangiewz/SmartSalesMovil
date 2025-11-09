class UserModel {
  final String id;
  final String nombre;
  final String correo;
  final String? telefono;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.telefono,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      telefono: json['telefono'] as String?,
      roles: (json['roles'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'correo': correo,
    'telefono': telefono,
    'roles': roles,
  };
}
