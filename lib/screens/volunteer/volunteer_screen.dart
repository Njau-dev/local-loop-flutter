// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/schedule_card.dart';
import '../../models/event_model.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00664F),
        automaticallyImplyLeading: false,
      ),
      body: _buildMainContent(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(children: [_buildHeroSection(), _buildContentSection()]),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 320,
      color: const Color(0xFF00664F),
      child: Stack(
        children: [
          // Background image (faint, low contrast, blended)
          Positioned.fill(
            left: 0,
            top: 20,
            child: Image.asset(
              'assets/images/volunteer_background.png',
              fit: BoxFit.contain,
            ),
          ),

          // Full-width overlay image (center of attention)
          Positioned.fill(
            left: 120,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Image.asset(
                'assets/images/volunteer_overlay.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.image, size: 100, color: Colors.white24),
                  );
                },
              ),
            ),
          ),

          // Logout button (top-right with semi-transparent background)
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _showLogoutDialog,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Stats at the bottom left
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                _buildStatCard('12', 'Events Joined'),
                const SizedBox(width: 16),
                _buildStatCard('48', 'Hours Volunteered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventsSection(),
            const SizedBox(height: 32),
            _buildScheduleSection(),
            const SizedBox(height: 100), // Bottom padding for nav
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/volunteer/events');
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const Text(
          'Find volunteer opportunities near you',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildEventCards(),
      ],
    );
  }

  Widget _buildEventCards() {
    final events = _getDummyEvents();
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == events.length - 1 ? 0 : 16,
            ),
            child: _buildVolunteerEventCard(events[index]),
          );
        },
      ),
    );
  }

  Widget _buildVolunteerEventCard(EventModel event) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(event.icon, color: event.color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              event.subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Join Now',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Commitments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Text(
          'Your scheduled volunteer activities',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ScheduleCard(
          title: 'Food Distribution',
          subtitle: 'Community Kitchen - Downtown',
          time: '10:30 - 14:30',
          room: 'Main Hall',
          instructor: 'Sarah Johnson (Coordinator)',
          color: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 12),
        ScheduleCard(
          title: 'Tree Planting',
          subtitle: 'City Park Environmental Drive',
          time: '08:00 - 12:00',
          room: 'Central Park',
          instructor: 'Mike Davis (Lead Volunteer)',
          color: const Color(0xFF2196F3),
        ),
      ],
    );
  }

  List<EventModel> _getDummyEvents() {
    final now = DateTime.now();
    return [
      EventModel(
        id: '1',
        title: 'Food Bank Support',
        description: 'Help distribute meals to families in need',
        category: 'community',
        color: Colors.orange,
        icon: Icons.restaurant,
        startTime: now.add(const Duration(days: 1, hours: 2)),
        endTime: now.add(const Duration(days: 1, hours: 6)),
        location: 'Downtown Center',
        locationLatitude: 37.7749,
        locationLongitude: -122.4194,
        organizerId: 'org1',
        organizerName: 'Helping Hands',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      EventModel(
        id: '2',
        title: 'Beach Cleanup',
        description: 'Environmental conservation effort',
        category: 'environment',
        color: Colors.blue,
        icon: Icons.eco,
        startTime: now.add(const Duration(days: 2, hours: 1)),
        endTime: now.add(const Duration(days: 2, hours: 5)),
        location: 'Sunny Beach',
        locationLatitude: 34.0522,
        locationLongitude: -118.2437,
        organizerId: 'org2',
        organizerName: 'Green Earth',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      EventModel(
        id: '3',
        title: 'Elder Care Visit',
        description: 'Spend time with seniors at care homes',
        category: 'health',
        color: Colors.purple,
        icon: Icons.elderly,
        startTime: now.add(const Duration(days: 3, hours: 3)),
        endTime: now.add(const Duration(days: 3, hours: 6)),
        location: 'Sunrise Care Home',
        locationLatitude: 2.1940,
        locationLongitude: -8.2437,
        organizerId: 'org3',
        organizerName: 'Care & Share',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      EventModel(
        id: '4',
        title: 'Shelter Support',
        description: 'Assist at local homeless shelter',
        category: 'community',
        color: Colors.red,
        icon: Icons.home,
        startTime: now.add(const Duration(days: 4, hours: 2)),
        endTime: now.add(const Duration(days: 4, hours: 7)),
        location: 'Hope Shelter',
        locationLatitude: 30.3042,
        locationLongitude: -97.7521,
        organizerId: 'org4',
        organizerName: 'Shelter Aid',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      EventModel(
        id: '5',
        title: 'Animal Rescue',
        description: 'Help at animal shelter',
        category: 'animals',
        color: Colors.brown,
        icon: Icons.pets,
        startTime: now.add(const Duration(days: 5, hours: 1)),
        endTime: now.add(const Duration(days: 5, hours: 4)),
        location: 'City Animal Shelter',
        locationLatitude: 40.7128,
        locationLongitude: -74.0060,
        organizerId: 'org5',
        organizerName: 'Animal Friends',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home
        Navigator.pushNamed(context, '/volunteer');
        break;
      case 1:
        Navigator.pushNamed(context, '/volunteer/events');
        break;
      case 2:
        Navigator.pushNamed(context, '/volunteer/schedule');
        break;
      case 3:
        Navigator.pushNamed(context, '/volunteer/profile');
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await Provider.of<AuthService>(
                    context,
                    listen: false,
                  ).signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error logging out. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
