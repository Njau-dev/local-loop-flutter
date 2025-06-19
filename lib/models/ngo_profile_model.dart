class NgoProfileModel {
  final String id;
  final String username;
  final String location;
  final int activeEvents;
  final int totalVolunteers;
  final List<String> focusAreas; // categories of events created
  final List<Map<String, dynamic>> recentActivities; // events created by user
  final DateTime establishedDate;

  NgoProfileModel({
    required this.id,
    required this.username,
    required this.location,
    required this.activeEvents,
    required this.totalVolunteers,
    required this.focusAreas,
    required this.recentActivities,
    required this.establishedDate,
  });

  // Create copy with updated values
  NgoProfileModel copyWith({
    String? id,
    String? username,
    String? location,
    int? activeEvents,
    int? totalVolunteers,
    List<String>? focusAreas,
    List<Map<String, dynamic>>? recentActivities,
    DateTime? establishedDate,
  }) {
    return NgoProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      location: location ?? this.location,
      activeEvents: activeEvents ?? this.activeEvents,
      totalVolunteers: totalVolunteers ?? this.totalVolunteers,
      focusAreas: focusAreas ?? this.focusAreas,
      recentActivities: recentActivities ?? this.recentActivities,
      establishedDate: establishedDate ?? this.establishedDate,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'location': location,
      'activeEvents': activeEvents,
      'totalVolunteers': totalVolunteers,
      'focusAreas': focusAreas,
      'recentActivities': recentActivities,
      'establishedDate': establishedDate.toIso8601String(),
    };
  }

  // Create from map
  factory NgoProfileModel.fromMap(Map<String, dynamic> map) {
    return NgoProfileModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      location:
          (map['location'] == null || (map['location'] as String).isEmpty)
              ? 'Location not provided'
              : map['location'],
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
    );
  }

  // Get initials for profile avatar
  String get initials {
    if (username.isEmpty) return '?';
    final names = username.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else {
      return names[0].substring(0, names[0].length >= 2 ? 2 : 1).toUpperCase();
    }
  }

  String get organizationName => username;
}
