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
    required this.photoUrl,
    required this.syncedToCloud,
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
  final String photoUrl;
  final bool syncedToCloud;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasLocalPhoto => photoPath.isNotEmpty;
  bool get hasRemotePhoto => photoUrl.isNotEmpty;
  bool get hasAnyPhoto => hasLocalPhoto || hasRemotePhoto;
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
    String? photoUrl,
    bool? syncedToCloud,
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
      photoUrl: photoUrl ?? this.photoUrl,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
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
      'photoUrl': photoUrl,
      'syncedToCloud': syncedToCloud,
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
      photoUrl: map['photoUrl'] as String? ?? '',
      syncedToCloud: map['syncedToCloud'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
