class Game {
  final int? id;
  final String code;
  final String name;
  final String description;
  final bool isActive;

  Game({
    this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'description': description,
        'is_active': isActive ? 1 : 0,
      };

  static Game fromJson(Map<String, dynamic> json) => Game(
        id: json['id'] as int?,
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        isActive: json['is_active'] == 1,
      );
}
