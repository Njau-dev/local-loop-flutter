import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_model.dart';

// Enhanced schedule model that can represent both events and calendar items
class ScheduleModel {
  final String id;
  final String title;
  final String subtitle;
  final String startTime;
  final String endTime;
  final String location;
  final String organizer; // For backwards compatibility, can be organizer
  final Color color;
  final DateTime date;
  final ScheduleType type;
  final String? eventId; // Reference to original event if applicable
  final bool isJoined; // Whether user has joined this event
  final bool isMarked; // Whether user has marked this event in calendar

  ScheduleModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.organizer,
    required this.color,
    required this.date,
    this.type = ScheduleType.event,
    this.eventId,
    this.isJoined = false,
    this.isMarked = false,
  });

  // Create ScheduleModel from EventModel
  factory ScheduleModel.fromEvent(
    EventModel event, {
    bool isJoined = false,
    bool isMarked = false,
  }) {
    return ScheduleModel(
      id: event.id,
      title: event.title,
      subtitle: event.description,
      startTime: _formatTime(event.startTime),
      endTime: _formatTime(event.endTime),
      location: event.location,
      organizer: event.organizerName,
      color: event.color,
      date: event.startTime,
      type: ScheduleType.event,
      eventId: event.id,
      isJoined: isJoined,
      isMarked: isMarked,
    );
  }

  // Helper method to format DateTime to time string
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final hourString = hour.toString().padLeft(2, '0');
    final minuteString = minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
  }

  // Create a copy with updated values
  ScheduleModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? startTime,
    String? endTime,
    String? location,
    String? organizer,
    Color? color,
    DateTime? date,
    ScheduleType? type,
    String? eventId,
    bool? isJoined,
    bool? isMarked,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      organizer: organizer ?? this.organizer,
      color: color ?? this.color,
      date: date ?? this.date,
      type: type ?? this.type,
      eventId: eventId ?? this.eventId,
      isJoined: isJoined ?? this.isJoined,
      isMarked: isMarked ?? this.isMarked,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'organizer': organizer,
      'color': color.value,
      'date': Timestamp.fromDate(date),
      'type': type.toString(),
      'eventId': eventId,
      'isJoined': isJoined,
      'isMarked': isMarked,
    };
  }

  // Create from map (Firestore)
  factory ScheduleModel.fromMap(String id, Map<String, dynamic> map) {
    return ScheduleModel(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      location: map['location'] ?? '',
      organizer: map['organizer'] ?? '',
      color: Color(map['color'] ?? Colors.blue.value),
      date: (map['date'] as Timestamp).toDate(),
      type: ScheduleType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ScheduleType.event,
      ),
      eventId: map['eventId'],
      isJoined: map['isJoined'] ?? false,
      isMarked: map['isMarked'] ?? false,
    );
  }

  // Get status display text
  String get statusText {
    if (isJoined) return 'Joined';
    if (isMarked) return 'Marked';
    return '';
  }

  // Get status color
  Color get statusColor {
    if (isJoined) return Colors.green;
    if (isMarked) return Colors.orange;
    return Colors.grey;
  }

  // Check if event is currently happening
  bool get isOngoing {
    final now = DateTime.now();
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(endTime.split(':')[0]),
      int.parse(endTime.split(':')[1]),
    );
    return now.isAfter(start) && now.isBefore(end);
  }

  // Check if event is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );
    return now.isBefore(start);
  }

  // Check if event is past
  bool get isPast {
    final now = DateTime.now();
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(endTime.split(':')[0]),
      int.parse(endTime.split(':')[1]),
    );
    return now.isAfter(end);
  }
}

// Enum for different types of schedule items
enum ScheduleType {
  event, // Volunteer events
  reminder, // Personal reminders
  meeting, // Meetings or calls
  task, // Tasks or todos
}
