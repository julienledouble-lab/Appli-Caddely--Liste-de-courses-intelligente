class Store {
  final String id;
  final String name;
  final bool isPrimary;
  final bool isSelectedForComparison;

  const Store({
    required this.id,
    required this.name,
    this.isPrimary = false,
    this.isSelectedForComparison = false,
  });

  Store copyWith({
    String? id,
    String? name,
    bool? isPrimary,
    bool? isSelectedForComparison,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      isPrimary: isPrimary ?? this.isPrimary,
      isSelectedForComparison: isSelectedForComparison ?? this.isSelectedForComparison,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isPrimary': isPrimary,
        'isSelectedForComparison': isSelectedForComparison,
      };

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json['id'] as String,
        name: json['name'] as String,
        isPrimary: json['isPrimary'] as bool? ?? false,
        isSelectedForComparison:
            json['isSelectedForComparison'] as bool? ?? false,
      );
}
