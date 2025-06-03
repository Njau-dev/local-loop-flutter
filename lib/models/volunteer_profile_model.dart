class VolunteerProfileModel {
  final String id;
  final String name;
  final String title;
  final String location;
  final String profileImage;
  final int totalHours;
  final int eventsJoined;
  final int impactScore;
  final int rank;
  final List<String> skills;
  final List<Map<String, dynamic>> recentActivities;
  final DateTime joinDate;
  final String email;
  final String phone;
  final String bio;
  final List<String> certifications;
  final List<String> preferredCategories;
  final bool isAvailable;
  final double rating;

  VolunteerProfileModel({
    required this.id,
    required this.name,
    required this.title,
    required this.location,
    required this.profileImage,
    required this.totalHours,
    required this.eventsJoined,
    required this.impactScore,
    required this.rank,
    required this.skills,
    required this.recentActivities,
    DateTime? joinDate,
    this.email = '',
    this.phone = '',
    this.bio = '',
    this.certifications = const [],
    this.preferredCategories = const [],
    this.isAvailable = true,
    this.rating = 5.0,
  }) : joinDate = joinDate ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'location': location,
      'profileImage': profileImage,
      'totalHours': totalHours,
      'eventsJoined': eventsJoined,
      'impactScore': impactScore,
      'rank': rank,
      'skills': skills,
      'recentActivities': recentActivities,
      'joinDate': joinDate.toIso8601String(),
      'email': email,
      'phone': phone,
      'bio': bio,
      'certifications': certifications,
      'preferredCategories': preferredCategories,
      'isAvailable': isAvailable,
      'rating': rating,
    };
  }

  // Create from JSON
  factory VolunteerProfileModel.fromJson(Map<String, dynamic> json) {
    return VolunteerProfileModel(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      location: json['location'],
      profileImage: json['profileImage'],
      totalHours: json['totalHours'],
      eventsJoined: json['eventsJoined'],
      impactScore: json['impactScore'],
      rank: json['rank'],
      skills: List<String>.from(json['skills']),
      recentActivities: List<Map<String, dynamic>>.from(
        json['recentActivities'],
      ),
      joinDate: DateTime.parse(json['joinDate']),
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      bio: json['bio'] ?? '',
      certifications: List<String>.from(json['certifications'] ?? []),
      preferredCategories: List<String>.from(json['preferredCategories'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] ?? 5.0).toDouble(),
    );
  }

  // Copy with method for updating properties
  VolunteerProfileModel copyWith({
    String? id,
    String? name,
    String? title,
    String? location,
    String? profileImage,
    int? totalHours,
    int? eventsJoined,
    int? impactScore,
    int? rank,
    List<String>? skills,
    List<Map<String, dynamic>>? recentActivities,
    DateTime? joinDate,
    String? email,
    String? phone,
    String? bio,
    List<String>? certifications,
    List<String>? preferredCategories,
    bool? isAvailable,
    double? rating,
  }) {
    return VolunteerProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      location: location ?? this.location,
      profileImage: profileImage ?? this.profileImage,
      totalHours: totalHours ?? this.totalHours,
      eventsJoined: eventsJoined ?? this.eventsJoined,
      impactScore: impactScore ?? this.impactScore,
      rank: rank ?? this.rank,
      skills: skills ?? this.skills,
      recentActivities: recentActivities ?? this.recentActivities,
      joinDate: joinDate ?? this.joinDate,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      certifications: certifications ?? this.certifications,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
    );
  }

  // Helper methods
  String get initials {
    return name.split(' ').map((n) => n[0]).join('').toUpperCase();
  }

  String get experienceLevel {
    if (totalHours < 10) return 'Beginner';
    if (totalHours < 50) return 'Intermediate';
    if (totalHours < 100) return 'Experienced';
    return 'Expert';
  }

  double get averageHoursPerEvent {
    if (eventsJoined == 0) return 0.0;
    return totalHours / eventsJoined;
  }

  bool get isTopVolunteer {
    return rank <= 100;
  }

  @override
  String toString() {
    return 'VolunteerProfileModel(id: $id, name: $name, totalHours: $totalHours, eventsJoined: $eventsJoined)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VolunteerProfileModel &&
        other.id == id &&
        other.name == name &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ email.hashCode;
  }
}
