// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_loop/models/user_model.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _eventsCollection => _firestore.collection('events');

  // Create a new event
  Future<String> createEvent(EventModel event) async {
    try {
      final docRef = await _eventsCollection.add(event.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Get all active events
  Stream<List<EventModel>> getAllEvents() {
    try {
    return _eventsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('startTime', descending: false)
        .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs.map((doc) {
                try {
                  return EventModel.fromFirestore(doc);
                } catch (e, stackTrace) {
                  debugPrint('Error parsing event document: $e');
                  debugPrint(stackTrace.toString());
                  rethrow;
                }
              }).toList();
            } catch (e, stackTrace) {
              debugPrint('Error mapping snapshot: $e');
              debugPrint(stackTrace.toString());
              rethrow;
            }
          });
    } catch (e, stackTrace) {
      debugPrint('Error in getAllEvents: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  // Get events by category
  Stream<List<EventModel>> getEventsByCategory(String category) {
    return _eventsCollection
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => EventModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get events created by specific organizer (NGO)
  Stream<List<EventModel>> getEventsByOrganizer(String organizerId) {
    try {
      return _eventsCollection
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              try {
                return EventModel.fromFirestore(doc);
              } catch (e) {
                print('Error parsing event: $e');
                rethrow;
              }
            }).toList();
          });
    } catch (e) {
      print('Error in getEventsByOrganizer: $e');
      rethrow;
    }
  }

  // Get single event by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get event: $e');
    }
  }

  // Update event
  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _eventsCollection.doc(eventId).update(updates);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete event (soft delete by setting isActive to false)
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Join event as volunteer
  Future<void> joinEvent(String eventId, String volunteerId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(_eventsCollection.doc(eventId));

        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }

        final eventData = eventDoc.data() as Map<String, dynamic>;
        final List<String> volunteerIds = List<String>.from(
          eventData['volunteerIds'] ?? [],
        );
        final int currentVolunteers = eventData['currentVolunteers'] ?? 0;
        final int maxVolunteers = eventData['maxVolunteers'] ?? 50;

        // Check if already joined
        if (volunteerIds.contains(volunteerId)) {
          throw Exception('Already joined this event');
        }

        // Check if event is full
        if (currentVolunteers >= maxVolunteers) {
          throw Exception('Event is full');
        }

        // Add volunteer
        volunteerIds.add(volunteerId);

        transaction.update(_eventsCollection.doc(eventId), {
          'volunteerIds': volunteerIds,
          'currentVolunteers': volunteerIds.length,
        });
      });
    } catch (e) {
      throw Exception('Failed to join event: $e');
    }
  }

  // Leave event as volunteer
  Future<void> leaveEvent(String eventId, String volunteerId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(_eventsCollection.doc(eventId));

        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }

        final eventData = eventDoc.data() as Map<String, dynamic>;
        final List<String> volunteerIds = List<String>.from(
          eventData['volunteerIds'] ?? [],
        );

        // Remove volunteer
        volunteerIds.remove(volunteerId);

        transaction.update(_eventsCollection.doc(eventId), {
          'volunteerIds': volunteerIds,
          'currentVolunteers': volunteerIds.length,
        });
      });
    } catch (e) {
      throw Exception('Failed to leave event: $e');
    }
  }

  // Get events joined by volunteer
  Stream<List<EventModel>> getJoinedEvents(String volunteerId) {
    return _eventsCollection
        .where('volunteerIds', arrayContains: volunteerId)
        .where('isActive', isEqualTo: true)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => EventModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Search events
  Stream<List<EventModel>> searchEvents(String query) {
    return _eventsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => EventModel.fromFirestore(doc))
                  .where(
                    (event) =>
                        event.title.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        event.description.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        event.location.toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                  )
                  .toList(),
        );
  }

  // Get upcoming events (next 7 days)
  Stream<List<EventModel>> getUpcomingEvents() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return _eventsCollection
        .where('isActive', isEqualTo: true)
        .where('startTime', isGreaterThan: Timestamp.fromDate(now))
        .where('startTime', isLessThan: Timestamp.fromDate(nextWeek))
        .orderBy('startTime', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => EventModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get NGO events for a date range
  Stream<List<EventModel>> getNgoEventsForDateRange(
    String ngoId,
    DateTime start,
    DateTime end,
  ) {
    return _eventsCollection
        .where('organizerId', isEqualTo: ngoId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => EventModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get NGO events for a specific date
  Stream<List<EventModel>> getNgoEventsForDate(String ngoId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getNgoEventsForDateRange(ngoId, start, end);
  }

  // Get event attendance count
  Future<int> getEventAttendanceCount(String eventId) async {
    final doc = await _eventsCollection.doc(eventId).get();
    if (!doc.exists) return 0;
    final data = doc.data() as Map<String, dynamic>;
    final List volunteerIds = data['volunteerIds'] ?? [];
    return volunteerIds.length;
  }

  // Cancel event (set isActive to false)
  Future<void> cancelEvent(String eventId) async {
    await _eventsCollection.doc(eventId).update({'isActive': false});
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get joined volunteers for an event
Stream<List<UserModel>> getJoinedVolunteers(String eventId) {
    return _firestore.collection('events').doc(eventId)
      .snapshots()
      .asyncMap((
      eventSnapshot,
    ) async {
      final data = eventSnapshot.data();
      if (data == null || data['volunteerIds'] == null) return <UserModel>[];

      final List volunteerIds = data['volunteerIds'];
      if (volunteerIds.isEmpty) return <UserModel>[];

      final usersSnapshot =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: volunteerIds)
              .get();

      return usersSnapshot.docs
          .map((doc) => UserModel.fromDocument(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<EventModel>> getEventsByCreator(String creatorId) {
    return _firestore
        .collection('events')
        .where('createdBy', isEqualTo: creatorId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => EventModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get all volunteers who joined an event (fetch user data for each volunteerId)
  Future<List<UserModel>> getEventVolunteers(String eventId) async {
    try {
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) return [];
      final data = eventDoc.data() as Map<String, dynamic>;
      final List<String> volunteerIds = List<String>.from(
        data['volunteerIds'] ?? [],
      );
      if (volunteerIds.isEmpty) return [];
      // Fetch user data for each volunteerId
      final userDocs =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: volunteerIds)
              .get();
      return userDocs.docs
          .map((doc) => UserModel.fromDocument(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching event volunteers: $e');
      return [];
    }
  }

}
