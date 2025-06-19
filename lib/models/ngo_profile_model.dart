class NgoProfileModel {
  final String id;
  final String name;
  final String organizationType;
  final String location;
  final String description;
  final int activeEvents;
  final int totalVolunteers;
  final List<String> focusAreas;
  final List<Map<String, dynamic>> recentActivities;
  final DateTime establishedDate;
  final String profileImage;

  NgoProfileModel({
    required this.id,
    required this.name,
    required this.organizationType,
    required this.location,
    required this.description,
    required this.activeEvents,
    required this.totalVolunteers,
    required this.focusAreas,
    required this.recentActivities,
    required this.establishedDate,
    this.profileImage = '',
  });

  // Create copy with updated values
  NgoProfileModel copyWith({
    String? id,
    String? name,
    String? organizationType,
    String? location,
    String? description,
    int? activeEvents,
    int? totalVolunteers,
    List<String>? focusAreas,
    List<Map<String, dynamic>>? recentActivities,
    DateTime? establishedDate,
    String? profileImage,
  }) {
    return NgoProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      organizationType: organizationType ?? this.organizationType,
      location: location ?? this.location,
      description: description ?? this.description,
      activeEvents: activeEvents ?? this.activeEvents,
      totalVolunteers: totalVolunteers ?? this.totalVolunteers,
      focusAreas: focusAreas ?? this.focusAreas,
      recentActivities: recentActivities ?? this.recentActivities,
      establishedDate: establishedDate ?? this.establishedDate,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'organizationType': organizationType,
      'location': location,
      'description': description,
      'activeEvents': activeEvents,
      'totalVolunteers': totalVolunteers,
      'focusAreas': focusAreas,
      'recentActivities': recentActivities,
      'establishedDate': establishedDate.toIso8601String(),
      'profileImage': profileImage,
    };
  }

  // Create from map
  factory NgoProfileModel.fromMap(Map<String, dynamic> map) {
    return NgoProfileModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      organizationType: map['organizationType'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      activeEvents: map['activeEvents'] ?? 0,
      totalVolunteers: map['totalVolunteers'] ?? 0,
      focusAreas: List<String>.from(map['focusAreas'] ?? []),
      recentActivities: List<Map<String, dynamic>>.from(
        map['recentActivities'] ?? [],
      ),
      establishedDate:
          map['establishedDate'] != null
              ? DateTime.parse(map['establishedDate'])
              : DateTime.now(),
      profileImage: map['profileImage'] ?? '',
    );
  }

  // Get initials for profile avatar
  String get initials {
    if (name.isEmpty) return '?';
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else {
      return names[0].substring(0, names[0].length >= 2 ? 2 : 1).toUpperCase();
    }
  }

  String get organizationName => name;
}
