import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceModel {
  final String id;
  final String eventId;
  final String volunteerId;
  final String volunteerName;
  final String volunteerEmail;
  final DateTime? signInTime;
  final DateTime? signOutTime;
  final double totalHours;
  final AttendanceStatus status;
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.eventId,
    required this.volunteerId,
    required this.volunteerName,
    required this.volunteerEmail,
    this.signInTime,
    this.signOutTime,
    required this.totalHours,
    required this.status,
    required this.createdAt,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      volunteerId: data['volunteerId'] ?? '',
      volunteerName: data['volunteerName'] ?? '',
      volunteerEmail: data['volunteerEmail'] ?? '',
      signInTime:
          data['signInTime'] != null
              ? (data['signInTime'] as Timestamp).toDate()
              : null,
      signOutTime:
          data['signOutTime'] != null
              ? (data['signOutTime'] as Timestamp).toDate()
              : null,
      totalHours: (data['totalHours'] ?? 0.0).toDouble(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'volunteerEmail': volunteerEmail,
      'signInTime': signInTime != null ? Timestamp.fromDate(signInTime!) : null,
      'signOutTime':
          signOutTime != null ? Timestamp.fromDate(signOutTime!) : null,
      'totalHours': totalHours,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? eventId,
    String? volunteerId,
    String? volunteerName,
    String? volunteerEmail,
    DateTime? signInTime,
    DateTime? signOutTime,
    double? totalHours,
    AttendanceStatus? status,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      volunteerEmail: volunteerEmail ?? this.volunteerEmail,
      signInTime: signInTime ?? this.signInTime,
      signOutTime: signOutTime ?? this.signOutTime,
      totalHours: totalHours ?? this.totalHours,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedDuration {
    if (totalHours == 0) return '0h 0m';
    final hours = totalHours.floor();
    final minutes = ((totalHours - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }
}

enum AttendanceStatus { present, signedIn, signedOut, absent, late }

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.signedIn:
        return 'Signed In';
      case AttendanceStatus.signedOut:
        return 'Signed Out';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return const Color(0xFF00664F);
      case AttendanceStatus.signedIn:
        return const Color(0xFF00664F);
      case AttendanceStatus.signedOut:
        return const Color(0xFF00664F);
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
    }
  }
}
