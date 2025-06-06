import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final Color color;
  final IconData icon;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final double locationLatitude;
  final double locationLongitude;
  final String organizerId;
  final String organizerName;
  final List<String> images;
  final int maxVolunteers;
  final int currentVolunteers;
  final List<String> volunteerIds;
  final DateTime createdAt;
  final bool isActive;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.color,
    required this.icon,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.organizerId,
    required this.organizerName,
    this.images = const [],
    this.maxVolunteers = 50,
    this.currentVolunteers = 0,
    this.volunteerIds = const [],
    required this.createdAt,
    this.isActive = true,
  });

  // Get subtitle based on time
  String get subtitle {
    final now = DateTime.now();
    final difference = startTime.difference(now);

    if (difference.inDays > 0) {
      return 'In ${difference.inDays} days • $location';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hours • $location';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minutes • $location';
    } else if (endTime.isAfter(now)) {
      return 'Happening now • $location';
    } else {
      return 'Completed • $location';
    }
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final categoryData = EventCategories.getCategory(
      data['category'] ?? 'community',
    );
    
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'community',
      color: categoryData['color'],
      icon: categoryData['icon'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      locationLatitude: (data['locationLatitude'] ?? 0).toDouble(),
      locationLongitude: (data['locationLongitude'] ?? 0).toDouble(),
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      maxVolunteers: data['maxVolunteers'] ?? 50,
      currentVolunteers: data['currentVolunteers'] ?? 0,
      volunteerIds: List<String>.from(data['volunteerIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'images': images,
      'maxVolunteers': maxVolunteers,
      'currentVolunteers': currentVolunteers,
      'volunteerIds': volunteerIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    Color? color,
    IconData? icon,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    double? locationLatitude,
    double? locationLongitude,
    String? organizerId,
    String? organizerName,
    List<String>? images,
    int? maxVolunteers,
    int? currentVolunteers,
    List<String>? volunteerIds,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      images: images ?? this.images,
      maxVolunteers: maxVolunteers ?? this.maxVolunteers,
      currentVolunteers: currentVolunteers ?? this.currentVolunteers,
      volunteerIds: volunteerIds ?? this.volunteerIds,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class EventCategories {
  static const Map<String, Map<String, dynamic>> categories = {
    'community': {
      'name': 'Community',
      'color': Colors.orange,
      'icon': Icons.people,
    },
    'environment': {
      'name': 'Environment',
      'color': Colors.green,
      'icon': Icons.eco,
    },
    'education': {
      'name': 'Education',
      'color': Colors.blue,
      'icon': Icons.school,
    },
    'health': {
      'name': 'Health',
      'color': Colors.deepPurple,
      'icon': Icons.health_and_safety,
    },
    'animals': {'name': 'Animals', 'color': Colors.brown, 'icon': Icons.pets},
    'emergency': {
      'name': 'Emergency',
      'color': Colors.red,
      'icon': Icons.emergency,
    },
  };

  static Map<String, dynamic> getCategory(String key) {
    return categories[key] ?? categories['community']!;
  }

  static List<String> getCategoryKeys() {
    return categories.keys.toList();
  }

  static List<String> getCategoryNames() {
    return categories.values.map((cat) => cat['name'] as String).toList();
  }

  static String getCategoryKey(String name) {
    return categories.entries
        .firstWhere((entry) => entry.value['name'] == name)
        .key;
  }
}
