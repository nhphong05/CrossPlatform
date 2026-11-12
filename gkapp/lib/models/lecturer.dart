class LecturerDraft {
  const LecturerDraft({
    required this.fullname,
    required this.image,
    required this.sumClass,
  });

  final String fullname;
  final String image;
  final int sumClass;

  Map<String, dynamic> toJson() => {
    'Fullname': fullname,
    'Image': image,
    'SumClass': sumClass,
  };
}

class Lecturer {
  const Lecturer({
    required this.id,
    required this.fullname,
    required this.image,
    required this.sumClass,
  });

  final String id;
  final String fullname;
  final String image;
  final int sumClass;

  factory Lecturer.fromJson(Map<String, dynamic> json) {
    final sumClass = json['SumClass'];
    if (sumClass is! num ||
        !sumClass.isFinite ||
        sumClass < 0 ||
        sumClass % 1 != 0) {
      throw const FormatException('SumClass không hợp lệ.');
    }

    return Lecturer(
      id: _requiredString(json, 'IDGV'),
      fullname: _requiredString(json, 'Fullname'),
      image: _requiredString(json, 'Image'),
      sumClass: sumClass.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'IDGV': id,
    'Fullname': fullname,
    'Image': image,
    'SumClass': sumClass,
  };

  Lecturer copyWith({
    String? id,
    String? fullname,
    String? image,
    int? sumClass,
  }) {
    return Lecturer(
      id: id ?? this.id,
      fullname: fullname ?? this.fullname,
      image: image ?? this.image,
      sumClass: sumClass ?? this.sumClass,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('$key không hợp lệ.');
    }
    return value;
  }
}
