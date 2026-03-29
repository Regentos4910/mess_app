class Student {
  Student({
    required this.id,
    required this.qrPayload,
    required this.name,
    required this.prn,
    required this.membershipActive,
    required this.deleted,
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
  final bool membershipActive;
  final bool deleted;
  final String photoPath;
  final String photoUrl;
  final bool syncedToCloud;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasLocalPhoto => photoPath.isNotEmpty;
  bool get hasRemotePhoto => photoUrl.isNotEmpty;
  bool get hasAnyPhoto => hasLocalPhoto || hasRemotePhoto;
 String get subtitle => 'PRN: $prn';

  Student copyWith({
    String? id,
    String? qrPayload,
    String? name,
    String? prn,
    bool? membershipActive,
    bool? deleted,
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
      membershipActive: membershipActive ?? this.membershipActive,
      deleted: deleted ?? this.deleted,
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
      'membershipActive': membershipActive,
      'deleted': deleted,
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
      membershipActive: map['membershipActive'] as bool? ?? true,
      deleted: map['deleted'] as bool? ?? false,
      photoPath: map['photoPath'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      syncedToCloud: map['syncedToCloud'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
