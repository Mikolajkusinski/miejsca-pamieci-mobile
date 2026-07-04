class Type {
  final int id;
  final String name;
  final String value;
  final int order;

  Type(
      {required this.id,
      required this.name,
      required this.value,
      required this.order});

  factory Type.fromJson(Map<String, dynamic> json) {
    return Type(
        id: json['id'] as int,
        name: json['name'] as String,
        value: json['value'] as String,
        order: json['order'] as int);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'order': order,
    };
  }
}
