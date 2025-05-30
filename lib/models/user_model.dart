class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? username;
  final String? certificateLink; // For NGO registration
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.username,
    this.certificateLink,
    this.createdAt,
  });

  factory UserModel.fromDocument(String uid, Map<String, dynamic> doc) {
    return UserModel(
      uid: uid,
      email: doc['email'] ?? '',
      role: doc['role'] ?? 'volunteer',
      username: doc['username'],
      certificateLink: doc['certificateLink'],
      createdAt: doc['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'username': username,
      'certificateLink': certificateLink,
      'createdAt': createdAt ?? DateTime.now(),
    };
  }
}
