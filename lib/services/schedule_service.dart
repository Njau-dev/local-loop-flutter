import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/volunteer_schedule_model.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _schedulesCollection =>
      _firestore.collection('user_schedules');
  CollectionReference get _notificationsCollection =>
      _firestore.collection('user_notifications');

  // Add event to personal calendar without joining
  Future<void> addToCalendar(String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _schedulesCollection.doc(userId).set({
        'markedEvents': FieldValue.arrayUnion([eventId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add event to calendar: $e');
    }
  }

  // Remove event from personal calendar
  Future<void> removeFromCalendar(String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _schedulesCollection.doc(userId).update({
        'markedEvents': FieldValue.arrayRemove([eventId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove event from calendar: $e');
    }
  }

  // Get events marked in calendar (not joined)
  Stream<List<String>> getMarkedEvents() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _schedulesCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data() as Map<String, dynamic>?;
      return List<String>.from(data?['markedEvents'] ?? []);
    });
  }

  // Check if event is marked in calendar
  Future<bool> isEventMarked(String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _schedulesCollection.doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      final markedEvents = List<String>.from(data?['markedEvents'] ?? []);
      return markedEvents.contains(eventId);
    } catch (e) {
      debugPrint('Error checking if event is marked: $e');
      return false;
    }
  }

  // Set up notification for event (1 day before)
  Future<void> scheduleEventNotification(EventModel event) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final notificationTime = event.startTime.subtract(const Duration(days: 1));

    // Only schedule if notification time is in the future
    if (notificationTime.isAfter(DateTime.now())) {
      try {
        await _notificationsCollection.add({
          'userId': userId,
          'eventId': event.id,
          'eventTitle': event.title,
          'eventLocation': event.location,
          'eventStartTime': Timestamp.fromDate(event.startTime),
          'notificationTime': Timestamp.fromDate(notificationTime),
          'type': 'event_reminder',
          'isRead': false,
          'isJoined': true, // User has joined this event
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error scheduling notification: $e');
      }
    }
  }

  // Schedule notification for marked event (not joined)
  Future<void> scheduleMarkedEventNotification(EventModel event) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final notificationTime = event.startTime.subtract(const Duration(days: 1));

    if (notificationTime.isAfter(DateTime.now())) {
      try {
        await _notificationsCollection.add({
          'userId': userId,
          'eventId': event.id,
          'eventTitle': event.title,
          'eventLocation': event.location,
          'eventStartTime': Timestamp.fromDate(event.startTime),
          'notificationTime': Timestamp.fromDate(notificationTime),
          'type': 'event_reminder',
          'isRead': false,
          'isJoined': false, // User has only marked this event
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error scheduling marked event notification: $e');
      }
    }
  }

  // Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('notificationTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Get events for a specific date (both joined and marked)
  Stream<Map<String, List<EventModel>>> getEventsForDate(DateTime date) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value({'joined': [], 'marked': []});
    }

    // Get joined events from EventService
    final joinedEventsStream =
        FirebaseFirestore.instance
            .collection('events')
            .where('volunteerIds', arrayContains: userId)
            .where('isActive', isEqualTo: true)
            .snapshots();

    // Get marked events
    final markedEventsStream = getMarkedEvents();

    return joinedEventsStream.asyncMap((joinedSnapshot) async {
      final joinedEvents =
          joinedSnapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .where(
                (event) =>
                    _isSameDay(event.startTime, date) ||
                    _isDateInEventRange(event, date),
              )
              .toList();

      // Get marked event IDs
      final markedEventIds = await markedEventsStream.first;

      if (markedEventIds.isEmpty) {
        return {'joined': joinedEvents, 'marked': <EventModel>[]};
      }

      // Get marked events details
      final markedEventsSnapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where(FieldPath.documentId, whereIn: markedEventIds)
              .where('isActive', isEqualTo: true)
              .get();

      final markedEvents =
          markedEventsSnapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .where(
                (event) =>
                    !joinedEvents.any(
                      (joined) => joined.id == event.id,
                    ) && // Not already joined
                    (_isSameDay(event.startTime, date) ||
                        _isDateInEventRange(event, date)),
              )
              .toList();

      return {'joined': joinedEvents, 'marked': markedEvents};
    });
  }

  // Get all schedule/commitments for a user
  Stream<List<ScheduleModel>> getUserSchedule(String userId) {
    try {
      final now = DateTime.now();
      return FirebaseFirestore.instance
          .collection('events')
          .where('volunteerIds', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .where('endTime', isGreaterThan: Timestamp.fromDate(now))
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              try {
                final event = EventModel.fromFirestore(doc);
                return ScheduleModel(
                  id: event.id,
                  title: event.title,
                  subtitle: event.description,
                  startTime: event.startTime.toString().substring(11, 16),
                  endTime: event.endTime.toString().substring(11, 16),
                  location: event.location,
                  organizer: event.organizerName,
                  color: event.color,
                  date: event.startTime,
                );
              } catch (e) {
                debugPrint('Error mapping event to schedule: $e');
                rethrow;
              }
            }).toList();
          });
    } catch (e) {
      debugPrint('Error in getUserSchedule: $e');
      rethrow;
    }
  }

  // Helper methods
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isDateInEventRange(EventModel event, DateTime date) {
    final eventStart = DateTime(
      event.startTime.year,
      event.startTime.month,
      event.startTime.day,
    );
    final eventEnd = DateTime(
      event.endTime.year,
      event.endTime.month,
      event.endTime.day,
    );
    final checkDate = DateTime(date.year, date.month, date.day);

    return checkDate.isAfter(eventStart.subtract(const Duration(days: 1))) &&
        checkDate.isBefore(eventEnd.add(const Duration(days: 1)));
  }

  // Clean up old notifications (call periodically)
  Future<void> cleanupOldNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

    try {
      final oldNotifications =
          await _notificationsCollection
              .where('userId', isEqualTo: userId)
              .where(
                'notificationTime',
                isLessThan: Timestamp.fromDate(cutoffDate),
              )
              .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error cleaning up notifications: $e');
    }
  }

  // Get events for a date range (for marking calendar days)
  Stream<Map<String, List<EventModel>>> getEventsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value({'joined': [], 'marked': []});
    }

    // Get joined events from EventService
    final joinedEventsStream =
        FirebaseFirestore.instance
            .collection('events')
            .where('volunteerIds', arrayContains: userId)
            .where('isActive', isEqualTo: true)
            .where(
              'startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'startTime',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .snapshots();

    // Get marked events
    final markedEventsStream = getMarkedEvents();

    return joinedEventsStream.asyncMap((joinedSnapshot) async {
      final joinedEvents =
          joinedSnapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();

      // Get marked event IDs
      final markedEventIds = await markedEventsStream.first;

      if (markedEventIds.isEmpty) {
        return {'joined': joinedEvents, 'marked': <EventModel>[]};
      }

      // Get marked events details within date range
      final markedEventsSnapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where(FieldPath.documentId, whereIn: markedEventIds)
              .where('isActive', isEqualTo: true)
              .where(
                'startTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'startTime',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .get();

      final markedEvents =
          markedEventsSnapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .where(
                (event) => !joinedEvents.any((joined) => joined.id == event.id),
              )
              .toList();

      return {'joined': joinedEvents, 'marked': markedEvents};
    });
  }
}
