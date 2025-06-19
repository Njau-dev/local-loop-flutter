import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _attendanceCollection =>
      _firestore.collection('attendance');
  CollectionReference get _eventsCollection => _firestore.collection('events');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Generate QR code data for event sign-in
  String generateQRData(String eventId) {
    // Simple QR data format: event_id|timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$eventId|$timestamp|checkin';
  }

  // Create attendance records for all joined volunteers when event starts
  Future<void> initializeEventAttendance(String eventId) async {
    try {
      // Get event details
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final event = EventModel.fromFirestore(eventDoc);

      // Get all volunteers who joined the event
      final volunteerIds = event.volunteerIds;

      if (volunteerIds.isEmpty) return;

      // Get volunteer details
      final volunteerDocs =
          await _usersCollection
              .where(FieldPath.documentId, whereIn: volunteerIds)
              .get();

      final batch = _firestore.batch();

      for (final volunteerDoc in volunteerDocs.docs) {
        final volunteer = UserModel.fromDocument(
          volunteerDoc.id,
          volunteerDoc.data() as Map<String, dynamic>,
        );

        // Check if attendance record already exists
        final existingAttendance =
            await _attendanceCollection
                .where('eventId', isEqualTo: eventId)
                .where('volunteerId', isEqualTo: volunteer.uid)
                .get();

        if (existingAttendance.docs.isEmpty) {
          // Create new attendance record
          final attendanceRef = _attendanceCollection.doc();
          final attendance = AttendanceModel(
            id: attendanceRef.id,
            eventId: eventId,
            volunteerId: volunteer.uid,
            volunteerName: volunteer.username ?? '',
            volunteerEmail: volunteer.email,
            totalHours: 0,
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
          );

          batch.set(attendanceRef, attendance.toFirestore());
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error initializing event attendance: $e');
      throw Exception('Failed to initialize attendance: $e');
    }
  }

  // Sign in volunteer using QR code data
  Future<void> signInVolunteer(String qrData, String volunteerId) async {
    try {
      // Parse QR data
      final parts = qrData.split('|');
      if (parts.length != 3 || parts[2] != 'checkin') {
        throw Exception('Invalid QR code');
      }

      final eventId = parts[0];
      final signInTime = DateTime.now();

      // Get attendance record
      final attendanceQuery =
          await _attendanceCollection
              .where('eventId', isEqualTo: eventId)
              .where('volunteerId', isEqualTo: volunteerId)
              .get();

      if (attendanceQuery.docs.isEmpty) {
        throw Exception('Attendance record not found');
      }

      final attendanceDoc = attendanceQuery.docs.first;
      final attendance = AttendanceModel.fromFirestore(attendanceDoc);

      // Check if already signed in
      if (attendance.signInTime != null) {
        throw Exception('Already signed in');
      }

      // Update attendance record
      await attendanceDoc.reference.update({
        'signInTime': Timestamp.fromDate(signInTime),
        'status': AttendanceStatus.signedIn.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error signing in volunteer: $e');
      rethrow;
    }
  }

  // Sign out volunteer
  Future<void> signOutVolunteer(String eventId, String volunteerId) async {
    try {
      final signOutTime = DateTime.now();

      // Get attendance record
      final attendanceQuery =
          await _attendanceCollection
              .where('eventId', isEqualTo: eventId)
              .where('volunteerId', isEqualTo: volunteerId)
              .get();

      if (attendanceQuery.docs.isEmpty) {
        throw Exception('Attendance record not found');
      }

      final attendanceDoc = attendanceQuery.docs.first;
      final attendance = AttendanceModel.fromFirestore(attendanceDoc);

      // Check if signed in
      if (attendance.signInTime == null) {
        throw Exception('Not signed in');
      }

      // Calculate total hours
      final totalHours =
          signOutTime.difference(attendance.signInTime!).inMinutes / 60.0;

      // Update attendance record
      await attendanceDoc.reference.update({
        'signOutTime': Timestamp.fromDate(signOutTime),
        'totalHours': totalHours,
        'status': AttendanceStatus.signedOut.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error signing out volunteer: $e');
      rethrow;
    }
  }

  // Auto sign out volunteers when event ends
  Future<void> autoSignOutVolunteers(String eventId) async {
    try {
      // Get all signed-in volunteers for the event
      final attendanceQuery =
          await _attendanceCollection
              .where('eventId', isEqualTo: eventId)
              .where(
                'status',
                isEqualTo: AttendanceStatus.signedIn.toString().split('.').last,
              )
              .get();

      if (attendanceQuery.docs.isEmpty) return;

      final batch = _firestore.batch();
      final autoSignOutTime = DateTime.now();

      for (final attendanceDoc in attendanceQuery.docs) {
        final attendance = AttendanceModel.fromFirestore(attendanceDoc);

        if (attendance.signInTime != null) {
          final totalHours =
              autoSignOutTime.difference(attendance.signInTime!).inMinutes /
              60.0;

          batch.update(attendanceDoc.reference, {
            'signOutTime': Timestamp.fromDate(autoSignOutTime),
            'totalHours': totalHours,
            'status': AttendanceStatus.signedOut.toString().split('.').last,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error auto signing out volunteers: $e');
    }
  }

  // Get attendance for an event
  Stream<List<AttendanceModel>> getEventAttendance(String eventId) {
    return _attendanceCollection
        .where('eventId', isEqualTo: eventId)
        .orderBy('volunteerName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => AttendanceModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get volunteer's attendance history
  Stream<List<AttendanceModel>> getVolunteerAttendance(String volunteerId) {
    return _attendanceCollection
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => AttendanceModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get attendance statistics for an event
  Future<Map<String, dynamic>> getEventAttendanceStats(String eventId) async {
    try {
      final attendanceQuery =
          await _attendanceCollection
              .where('eventId', isEqualTo: eventId)
              .get();

      final attendanceList =
          attendanceQuery.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList();

      final total = attendanceList.length;
      final present =
          attendanceList
              .where(
                (a) =>
                    a.status == AttendanceStatus.present ||
                    a.status == AttendanceStatus.signedIn ||
                    a.status == AttendanceStatus.signedOut,
              )
              .length;
      final absent =
          attendanceList
              .where((a) => a.status == AttendanceStatus.absent)
              .length;
      final late =
          attendanceList.where((a) => a.status == AttendanceStatus.late).length;
      final totalHours = attendanceList.fold<double>(
        0,
        (sum, a) => sum + a.totalHours,
      );

      return {
        'total': total,
        'present': present,
        'absent': absent,
        'late': late,
        'totalHours': totalHours,
        'attendanceRate': total > 0 ? (present / total * 100).round() : 0,
      };
    } catch (e) {
      debugPrint('Error getting attendance stats: $e');
      return {
        'total': 0,
        'present': 0,
        'absent': 0,
        'late': 0,
        'totalHours': 0.0,
        'attendanceRate': 0,
      };
    }
  }

  // Check if volunteer can sign in (within event time and has joined)
  Future<bool> canVolunteerSignIn(String eventId, String volunteerId) async {
    try {
      // Check if event exists and is active
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) return false;

      final event = EventModel.fromFirestore(eventDoc);
      final now = DateTime.now();

      // Check if event has started and not ended
      if (now.isBefore(event.startTime) || now.isAfter(event.endTime)) {
        return false;
      }

      // Check if volunteer joined the event
      if (!event.volunteerIds.contains(volunteerId)) {
        return false;
      }

      // Check if attendance record exists and not already signed in
      final attendanceQuery =
          await _attendanceCollection
              .where('eventId', isEqualTo: eventId)
              .where('volunteerId', isEqualTo: volunteerId)
              .get();

      if (attendanceQuery.docs.isEmpty) {
        // Initialize attendance if it doesn't exist
        await initializeEventAttendance(eventId);
        return true;
      }

      final attendance = AttendanceModel.fromFirestore(
        attendanceQuery.docs.first,
      );
      return attendance.signInTime == null;
    } catch (e) {
      debugPrint('Error checking sign-in eligibility: $e');
      return false;
    }
  }

  // Mark volunteer as late
  Future<void> markVolunteerLate(String eventId, String volunteerId) async {
    try {
      final attendanceQuery =
          await _attendanceCollection
              .where('eventId', isEqualTo: eventId)
              .where('volunteerId', isEqualTo: volunteerId)
              .get();

      if (attendanceQuery.docs.isNotEmpty) {
        await attendanceQuery.docs.first.reference.update({
          'status': AttendanceStatus.late.toString().split('.').last,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error marking volunteer as late: $e');
    }
  }

  // Get NGO's events with attendance summary
  Stream<List<Map<String, dynamic>>> getNGOEventsWithAttendance(String ngoId) {
    return _eventsCollection
        .where('organizerId', isEqualTo: ngoId)
        .where('isActive', isEqualTo: true)
        .orderBy('startTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Map<String, dynamic>> eventsWithAttendance = [];

          for (final doc in snapshot.docs) {
            final event = EventModel.fromFirestore(doc);
            final stats = await getEventAttendanceStats(event.id);

            eventsWithAttendance.add({'event': event, 'stats': stats});
          }

          return eventsWithAttendance;
        });
  }
}
