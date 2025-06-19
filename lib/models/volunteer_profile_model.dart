import 'package:flutter/material.dart';

class VolunteerProfileModel {
  final String id;
  final String name;
  final String title;
  final String location;
  final int totalHours;
  final int eventsJoined;
  final List<ProfileBadge> badges; // Changed from skills to badges
  final List<Map<String, dynamic>> recentActivities;
  final String profileImage;

  VolunteerProfileModel({
    required this.id,
    required this.name,
    required this.title,
    required this.location,
    required this.totalHours,
    required this.eventsJoined,
    required this.badges,
    required this.recentActivities,
    this.profileImage = '',
  });

  // Create copy with updated values
  VolunteerProfileModel copyWith({
    String? id,
    String? name,
    String? title,
    String? location,
    int? totalHours,
    int? eventsJoined,
    List<ProfileBadge>? badges,
    List<Map<String, dynamic>>? recentActivities,
    String? profileImage,
  }) {
    return VolunteerProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      location: location ?? this.location,
      totalHours: totalHours ?? this.totalHours,
      eventsJoined: eventsJoined ?? this.eventsJoined,
      badges: badges ?? this.badges,
      recentActivities: recentActivities ?? this.recentActivities,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'location': location,
      'totalHours': totalHours,
      'eventsJoined': eventsJoined,
      'badges': badges.map((badge) => badge.toMap()).toList(),
      'recentActivities': recentActivities,
      'profileImage': profileImage,
    };
  }

  // Create from map
  factory VolunteerProfileModel.fromMap(Map<String, dynamic> map) {
    return VolunteerProfileModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      totalHours: map['totalHours'] ?? 0,
      eventsJoined: map['eventsJoined'] ?? 0,
      badges:
          (map['badges'] as List<dynamic>?)
              ?.map((badgeMap) => ProfileBadge.fromMap(badgeMap))
              .toList() ??
          [],
      recentActivities: List<Map<String, dynamic>>.from(
        map['recentActivities'] ?? [],
      ),
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
}

class ProfileBadge {
  final String name;
  final IconData icon;
  final String category;
  final int eventCount;
  final Color? color;

  ProfileBadge({
    required this.name,
    required this.icon,
    required this.category,
    required this.eventCount,
    this.color,
  });

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon.codePoint,
      'category': category,
      'eventCount': eventCount,
      'color': color?.value,
    };
  }

  // Create from map
  factory ProfileBadge.fromMap(Map<String, dynamic> map) {
    return ProfileBadge(
      name: map['name'] ?? '',
      icon: IconData(
        map['icon'] ?? Icons.star.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      category: map['category'] ?? '',
      eventCount: map['eventCount'] ?? 0,
      color: map['color'] != null ? Color(map['color']) : null,
    );
  }

  // Get badge description
  String get description {
    return 'Participated in $eventCount $category events';
  }

  // Get badge color based on category
  Color get badgeColor {
    if (color != null) return color!;

    switch (category.toLowerCase()) {
      case 'education':
        return const Color(0xFF2196F3);
      case 'environment':
        return const Color(0xFF4CAF50);
      case 'healthcare':
        return const Color(0xFFE91E63);
      case 'community':
        return const Color(0xFFFF9800);
      case 'disaster relief':
        return const Color(0xFFF44336);
      case 'animal welfare':
        return const Color(0xFF795548);
      case 'food security':
        return const Color(0xFFFF5722);
      case 'technology':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF607D8B);
    }
  }
}
