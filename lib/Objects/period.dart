class Period {
  final int id;
  final String name;
  final String value;
  final int order;

  Period(
      {required this.id,
      required this.name,
      required this.value,
      required this.order});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
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
