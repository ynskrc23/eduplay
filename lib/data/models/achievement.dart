class Achievement {
  final int? id;
  final String code;
  final String title;
  final String description;
  final String icon;

  Achievement({
    this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'description': description,
        'icon': icon,
      };

  static Achievement fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as int?,
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
      );
}
