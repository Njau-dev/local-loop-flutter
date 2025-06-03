import 'package:flutter/material.dart';

class ScheduleModel {
  final String id;
  final String title;
  final String subtitle;
  final String startTime;
  final String endTime;
  final String location;
  final String instructor;
  final String instructorImage;
  final Color color;
  final DateTime date;

  ScheduleModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.instructor,
    required this.instructorImage,
    required this.color,
    required this.date,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'instructor': instructor,
      'instructorImage': instructorImage,
      'color': color.value,
      'date': date.toIso8601String(),
    };
  }

  // Create from JSON
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      location: json['location'],
      instructor: json['instructor'],
      instructorImage: json['instructorImage'],
      color: Color(json['color']),
      date: DateTime.parse(json['date']),
    );
  }

  // Copy with method for updating properties
  ScheduleModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? startTime,
    String? endTime,
    String? location,
    String? instructor,
    String? instructorImage,
    Color? color,
    DateTime? date,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      instructor: instructor ?? this.instructor,
      instructorImage: instructorImage ?? this.instructorImage,
      color: color ?? this.color,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'ScheduleModel(id: $id, title: $title, startTime: $startTime, endTime: $endTime, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleModel &&
        other.id == id &&
        other.title == title &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        date.hashCode;
  }
}
