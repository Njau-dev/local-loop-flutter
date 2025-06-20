// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:local_loop/services/profile_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/schedule_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/schedule_card.dart';
import '../../models/event_model.dart';
import '../../models/volunteer_schedule_model.dart';
import '../../models/volunteer_profile_model.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  int _currentNavIndex = 0;
  final EventService _eventService = EventService();
  final ScheduleService _scheduleService = ScheduleService();
  final ProfileService _profileService = ProfileService();
  List<EventModel> _availableEvents = [];
  List<ScheduleModel> _commitments = [];
  bool _isLoading = true;
  VolunteerProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadStatsAndData();
    _loadProfile();
  }

  Future<void> _loadStatsAndData() async {
    setState(() {
      _isLoading = true;
    });
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    // Load available events (active and not yet started)
    final now = DateTime.now();
    final eventsSnapshot = await _eventService.getAllEvents().first;
    final availableEvents =
        eventsSnapshot
            .where((e) => e.isActive && e.startTime.isAfter(now))
            .toList();
    // Load commitments (user's schedule)
    final scheduleSnapshot =
        await _scheduleService.getUserSchedule(userId).first;
    setState(() {
      _availableEvents = availableEvents;
      _commitments = scheduleSnapshot;
      _isLoading = false;
    });
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final profile = await _profileService.getVolunteerProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading profile: $e');
    }
  }

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

          // Stats at the bottom left (use real data from profile)
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                _buildStatCard(
                  _profile?.eventsJoined.toString() ?? '-',
                  'Events Joined',
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  _profile?.totalHours.toString() ?? '-',
                  'Hours Volunteered',
                ),
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
            const SizedBox(height: 100),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      height: 180,
      child:
          _availableEvents.isEmpty
              ? const Center(child: Text('No available events'))
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableEvents.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == _availableEvents.length - 1 ? 0 : 16,
                    ),
                    child: _buildVolunteerEventCard(_availableEvents[index]),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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
        _commitments.isEmpty
            ? const Text('No upcoming commitments')
            : Column(
              children:
                  _commitments
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                entry.key == _commitments.length - 1 ? 0 : 16,
                          ),
                          child: ScheduleCard(
                            title: entry.value.title,
                            subtitle: entry.value.subtitle,
                            time:
                                entry.value.startTime +
                                ' - ' +
                                entry.value.endTime,
                            room: entry.value.location,
                            instructor: entry.value.organizer,
                            color: entry.value.color,
                          ),
                        ),
                      )
                      .toList(),
            ),
      ],
    );
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
                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                try {
                  await authService.signOut();
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
