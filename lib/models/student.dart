class Student {
  Student({
    required this.id,
    required this.qrPayload,
    required this.name,
    required this.prn,
    required this.studyYear,
    required this.courseName,
    required this.division,
    required this.membershipActive,
    required this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String qrPayload;
  final String name;
  final String prn;
  final String studyYear;
  final String courseName;
  final String division;
  final bool membershipActive;
  final String photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get subtitle => '$courseName • Year $studyYear • Div $division';

  Student copyWith({
    String? id,
    String? qrPayload,
    String? name,
    String? prn,
    String? studyYear,
    String? courseName,
    String? division,
    bool? membershipActive,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      qrPayload: qrPayload ?? this.qrPayload,
      name: name ?? this.name,
      prn: prn ?? this.prn,
      studyYear: studyYear ?? this.studyYear,
      courseName: courseName ?? this.courseName,
      division: division ?? this.division,
      membershipActive: membershipActive ?? this.membershipActive,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'qrPayload': qrPayload,
      'name': name,
      'prn': prn,
      'studyYear': studyYear,
      'courseName': courseName,
      'division': division,
      'membershipActive': membershipActive,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      qrPayload: map['qrPayload'] as String,
      name: map['name'] as String,
      prn: map['prn'] as String,
      studyYear: map['studyYear'] as String,
      courseName: map['courseName'] as String,
      division: map['division'] as String,
      membershipActive: map['membershipActive'] as bool? ?? true,
      photoPath: map['photoPath'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
