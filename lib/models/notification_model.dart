import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  eventReminder,
  badgeEarned,
  certificateReady,
  eventJoined,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  // Factory for creating from Firestore map
  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.eventReminder,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.toString(),
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  // Helper to get icon for type
  IconData getTypeIcon() {
    switch (type) {
      case NotificationType.eventReminder:
        return Icons.event;
      case NotificationType.badgeEarned:
        return Icons.emoji_events;
      case NotificationType.certificateReady:
        return Icons.verified;
      case NotificationType.eventJoined:
        return Icons.check_circle_outline;
    }
  }

  // Helper to get color for type
  Color getTypeColor() {
    switch (type) {
      case NotificationType.eventReminder:
        return Colors.blue;
      case NotificationType.badgeEarned:
        return Colors.orange;
      case NotificationType.certificateReady:
        return Colors.green;
      case NotificationType.eventJoined:
        return Colors.teal;
    }
  }
}
