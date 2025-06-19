// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/volunteer_profile_model.dart';
import '../models/ngo_profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user location (city, country) using geocoding, fallback to coordinates if not found
  Future<String> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location not available';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return 'Location not available';
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city =
            (place.locality != null && place.locality!.isNotEmpty)
                ? place.locality!
                : ((place.subAdministrativeArea != null &&
                        place.subAdministrativeArea!.isNotEmpty)
                    ? place.subAdministrativeArea!
                    : '');
        final country =
            (place.country != null && place.country!.isNotEmpty)
                ? place.country!
                : '';
        if (city.isNotEmpty && country.isNotEmpty) {
          return '$city, $country';
        } else if (country.isNotEmpty) {
          return country;
        }
      }
      // Fallback to coordinates if no placemark found
      return 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      debugPrint('Error getting location: $e');
      return 'Location not available';
    }
  }

  // Get user profile data
  Future<VolunteerProfileModel?> getVolunteerProfile() async {
    try {
      if (currentUserId == null) return null;

      // Get user data
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();

      if (!userDoc.exists) return null;

      final userData = UserModel.fromDocument(currentUserId!, userDoc.data()!);

      // Get joined events
      final joinedEventsQuery =
          await _firestore
              .collection('events')
              .where('volunteerIds', arrayContains: currentUserId)
              .where('isActive', isEqualTo: true)
              .get();

      final joinedEvents =
          joinedEventsQuery.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();

      // Calculate total hours (assuming each event is 3 hours on average)
      // You can modify this based on your event duration field if available
      final totalHours = joinedEvents.length * 3;

      // Get location
      final location = await _getCurrentLocation();

      // Calculate badges based on event categories
      final badges = _calculateBadges(joinedEvents);

      // Get recent activities
      final recentActivities = _getRecentActivities(joinedEvents);

      return VolunteerProfileModel(
        id: currentUserId!,
        name: userData.username ?? 'Volunteer',
        title: _getUserTitle(userData.role),
        email: userData.email,
        location: location,
        totalHours: totalHours,
        eventsJoined: joinedEvents.length,
        badges: badges, // Changed from skills to badges
        recentActivities: recentActivities,
      );
    } catch (e) {
      print('Error getting volunteer profile: $e');
      return null;
    }
  }

  // Calculate badges based on event categories
  List<ProfileBadge> _calculateBadges(List<EventModel> events) {
    final categoryCount = <String, int>{};

    // Count events per category
    for (final event in events) {
      categoryCount[event.category] = (categoryCount[event.category] ?? 0) + 1;
    }

    // Create badges for categories with 3+ events
    final badges = <ProfileBadge>[];
    categoryCount.forEach((category, count) {
      if (count >= 3) {
        badges.add(
          ProfileBadge(
            name: _getBadgeName(category),
            icon: _getCategoryIcon(category),
            category: category,
            eventCount: count,
          ),
        );
      }
    });

    return badges;
  }

  // Get badge name based on category
  String _getBadgeName(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return 'Education Champion';
      case 'environment':
        return 'Eco Warrior';
      case 'healthcare':
        return 'Health Advocate';
      case 'community':
        return 'Community Builder';
      case 'disaster relief':
        return 'Crisis Responder';
      case 'animal welfare':
        return 'Animal Guardian';
      case 'food security':
        return 'Hunger Fighter';
      default:
        return '${category} Specialist';
    }
  }

  // Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return Icons.school;
      case 'environment':
        return Icons.eco;
      case 'healthcare':
        return Icons.health_and_safety;
      case 'community':
        return Icons.groups;
      case 'disaster relief':
        return Icons.emergency;
      case 'animal welfare':
        return Icons.pets;
      case 'food security':
        return Icons.restaurant;
      default:
        return Icons.volunteer_activism;
    }
  }

  // Get user title based on role
  String _getUserTitle(String role) {
    switch (role.toLowerCase()) {
      case 'volunteer':
        return 'Community Volunteer';
      case 'ngo':
        return 'NGO Representative';
      case 'admin':
        return 'Platform Administrator';
      default:
        return 'Community Member';
    }
  }

  // Get recent activities from completed events
  List<Map<String, dynamic>> _getRecentActivities(List<EventModel> events) {
    // Sort events by end time, most recent first
    final sortedEvents = List<EventModel>.from(events)
      ..sort((a, b) => b.endTime.compareTo(a.endTime));

    // Take the 3 most recent completed events
    final recentEvents =
        sortedEvents
            .where((event) => event.endTime.isBefore(DateTime.now()))
            .take(3)
            .toList();

    return recentEvents.map((event) {
      return {
        'title': 'Completed ${event.title}',
        'subtitle':
            event.description.length > 50
                ? '${event.description.substring(0, 50)}...'
                : event.description,
        'time': _getTimeAgo(event.endTime),
        'icon': _getCategoryIcon(event.category),
        'color': event.color,
      };
    }).toList();
  }

  // Get time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Future<VolunteerProfileModel?> getVolunteerProfileById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Try to get username, fallback to email prefix if missing
        final name =
            data['username'] ??
            (data['email'] != null
                ? (data['email'] as String).split('@')[0]
                : 'Volunteer');
        return VolunteerProfileModel(
          id: userId,
          name: name,
          email: data['email'] ?? '',
          title:
              data['role'] != null
                  ? _getUserTitle(data['role'])
                  : 'Community Member',
          location: data['location'] ?? '',
          totalHours: data['totalHours'] ?? 0,
          eventsJoined: data['eventsJoined'] ?? 0,
          badges: [], // You can fetch badges if needed
          recentActivities: [], // You can fetch activities if needed
        );
      }
      return null;
    } catch (e) {
      print('Error getting volunteer profile: $e');
      return null;
    }
  }

  // Stream for real-time profile updates
  Stream<VolunteerProfileModel?> getVolunteerProfileStream() {
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((_) async => await getVolunteerProfile());
  }

  // Update user profile
  Future<void> updateUserProfile({String? username, String? location}) async {
    if (currentUserId == null) throw Exception('User not logged in');

    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (location != null) updates['location'] = location;

      await _firestore.collection('users').doc(currentUserId).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get NGO profile data
  Future<NgoProfileModel?> getNgoProfile() async {
    try {
      if (currentUserId == null) return null;
      // Get user data
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return null;
      final userData = UserModel.fromDocument(currentUserId!, userDoc.data()!);
      // Get all events created by this user (NGO)
      final eventsQuery =
          await _firestore
              .collection('events')
              .where('organizerId', isEqualTo: currentUserId)
              .get();
      final events =
          eventsQuery.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      // Location: get current location (city, country)
      final location = await _getCurrentLocation();
      // Active events: count of events that are active
      final activeEvents = events.where((e) => e.isActive).length;
      // Total volunteers: sum of all volunteers joined for all events
      final totalVolunteers = events.fold<int>(
        0,
        (sum, e) => sum + e.currentVolunteers,
      );
      // Focus areas: unique categories of events created
      final focusAreas = events.map((e) => e.category).toSet().toList();
      // Recent activities: all events created by this user (can limit to last N if needed)
      final recentActivities =
          events
              .map(
                (e) => {
                  'title': e.title,
                  'category': e.category,
                  'startTime': e.startTime.toIso8601String(),
                  'endTime': e.endTime.toIso8601String(),
                  'location': e.location,
                  'isActive': e.isActive,
                },
              )
              .toList();
      // Established date: createdAt from user model
      final establishedDate = userData.createdAt ?? DateTime.now();
      return NgoProfileModel(
        id: userData.uid,
        username: userData.username ?? userData.email.split('@')[0],
        location: location,
        activeEvents: activeEvents,
        totalVolunteers: totalVolunteers,
        focusAreas: focusAreas,
        recentActivities: recentActivities,
        establishedDate: establishedDate,
      );
    } catch (e) {
      print('Error getting NGO profile: $e');
      return null;
    }
  }
}
