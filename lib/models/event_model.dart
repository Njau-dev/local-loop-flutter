import 'package:flutter/material.dart';

class EventModel {
  final String id;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? location;
  final String? organizerId;

  EventModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.description,
    this.startTime,
    this.endTime,
    this.location,
    this.organizerId,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      color: Color(map['color'] ?? 0xFF4CAF50),
      icon: IconData(
        map['icon'] ?? Icons.event.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      description: map['description'],
      startTime:
          map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      location: map['location'],
      organizerId: map['organizerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'color': color.toARGB32(),
      'icon': icon.codePoint,
      'description': description,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'location': location,
      'organizerId': organizerId,
    };
  }
}
