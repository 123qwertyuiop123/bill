class TallyCounter {
  const TallyCounter({
    required this.id,
    required this.name,
    required this.value,
  });

  final String id;
  final String name;
  final int value;

  TallyCounter copyWith({String? name, int? value}) =>
      TallyCounter(id: id, name: name ?? this.name, value: value ?? this.value);

  Map<String, Object> toJson() => {'id': id, 'name': name, 'value': value};

  static TallyCounter? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final name = json['name'];
    final value = json['value'];
    if (id is! String ||
        !RegExp(r'^[a-zA-Z0-9_-]{1,50}$').hasMatch(id) ||
        name is! String ||
        name.trim().isEmpty ||
        name.length > 30 ||
        value is! int ||
        value.abs() > 999999999) {
      return null;
    }
    return TallyCounter(id: id, name: name.trim(), value: value);
  }
}
