class AddressModel {
  final int id;
  final String direccion;

  AddressModel({required this.id, required this.direccion});

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as int,
      direccion: json['direccion'] as String,
    );
  }
}
