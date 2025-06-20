// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:local_loop/models/volunteer_profile_model.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/event_service.dart';
import '../../models/ngo_profile_model.dart';
import '../../models/event_model.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/schedule_card.dart';

class NgoScreen extends StatefulWidget {
  const NgoScreen({super.key});

  @override
  State<NgoScreen> createState() => _NgoScreenState();
}

class _NgoScreenState extends State<NgoScreen> {
  int _currentNavIndex = 0;
  NgoProfileModel? _ngoProfile;
  List<EventModel> _ngoEvents = [];
  List<String> _recentVolunteers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNgoData();
  }

  Future<void> _loadNgoData() async {
    setState(() {
      _isLoading = true;
    });

    final profileService = Provider.of<ProfileService>(context, listen: false);
    final eventService = Provider.of<EventService>(context, listen: false);
    final ngoProfile = await profileService.getNgoProfile();
    List<EventModel> ngoEvents = [];
    List<String> recentVolunteers = [];
    if (ngoProfile != null) {
      // Fetch all events for this NGO
      final eventsQuery =
          await eventService.getEventsByOrganizer(ngoProfile.id).first;
      ngoEvents = eventsQuery;
      // Collect up to 5 unique volunteer IDs from all events
      final volunteerSet = <String>{};
      for (final event in ngoEvents) {
        volunteerSet.addAll(event.volunteerIds);
        if (volunteerSet.length >= 5) break;
      }
      recentVolunteers = volunteerSet.take(5).toList();
    }
    setState(() {
      _ngoProfile = ngoProfile;
      _ngoEvents = ngoEvents;
      _recentVolunteers = recentVolunteers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00664F),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
      ),
      backgroundColor: Colors.grey[50],
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

          // Stats at the bottom left (using real data)
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                _buildStatCard(
                  _isLoading
                      ? '-'
                      : _ngoProfile?.activeEvents.toString() ?? '-',
                  'Active Events',
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  _isLoading
                      ? '-'
                      : _ngoProfile?.totalVolunteers.toString() ?? '-',
                  'Total Volunteers',
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
            _buildQuickActionsSection(),
            const SizedBox(height: 32),
            _buildActiveEventsSection(),
            const SizedBox(height: 32),
            _buildVolunteerManagementSection(),
            const SizedBox(height: 100), // Bottom padding for nav
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Text(
          'Manage your organization efficiently',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildQuickActionCards(),
      ],
    );
  }

  Widget _buildQuickActionCards() {
    final actions = _getQuickActions();
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == actions.length - 1 ? 0 : 16,
            ),
            child: _buildQuickActionCard(actions[index]),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionCard(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: () {
        // Navigate to respective screens
        Navigator.pushNamed(context, action['route']);
      },
      child: Container(
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
                  color: action['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action['icon'], color: action['color'], size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                action['title'],
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
                action['subtitle'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    action['action'],
                    style: const TextStyle(
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
      ),
    );
  }

  Widget _buildActiveEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/ngo/events');
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
          'Monitor your ongoing volunteer events',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildActiveEventsList(),
      ],
    );
  }

  Widget _buildActiveEventsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ngoEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'No active events yet. Create your first event!',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children:
          _ngoEvents.take(3).map((event) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ScheduleCard(
                title: event.title,
                subtitle: event.subtitle,
                time:
                    '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                room: '${event.currentVolunteers} Volunteers Registered',
                instructor:
                    event.organizerName.isNotEmpty
                        ? event.organizerName
                        : 'Event Coordinator',
                color: event.color,
              ),
            );
          }).toList(),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildVolunteerManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Volunteers',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Text(
          'Review and manage volunteer registrations',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildVolunteerCards(),
      ],
    );
  }

  Widget _buildVolunteerCards() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentVolunteers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'No recent volunteers',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children:
          _recentVolunteers
              .map(
                (volunteerId) => FutureBuilder<VolunteerProfileModel?>(
                  future: Provider.of<ProfileService>(
                    context,
                    listen: false,
                  ).getVolunteerProfileById(volunteerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircleAvatar(child: Text('?')),
                        title: Text('Loading...'),
                      );
                    }
                    final profile = snapshot.data;
                    if (profile == null) {
                      return const ListTile(
                        leading: CircleAvatar(child: Text('?')),
                        title: Text('Unknown volunteer'),
                      );
                    }
                    // Use initials as avatar, show username (name) and email
                    return ListTile(
                      leading: CircleAvatar(child: Text(profile.initials)),
                      title: Text(profile.name),
                      subtitle: Text(profile.email),
                    );
                  },
                ),
              )
              .toList(),
    );
  }

  List<Map<String, dynamic>> _getQuickActions() {
    return [
      {
        'title': 'Create Event',
        'subtitle': 'Post new volunteer opportunities',
        'color': Colors.green,
        'icon': Icons.add_circle_outline,
        'action': 'Create Now',
        'route': '/ngo/create-event',
      },
      {
        'title': 'Manage Volunteers',
        'subtitle': 'View and assign volunteer roles',
        'color': Colors.blue,
        'icon': Icons.people_outline,
        'action': 'Manage',
        'route': '/ngo/volunteers',
      },
      {
        'title': 'Event Reports',
        'subtitle': 'Track event performance & impact',
        'color': Colors.purple,
        'icon': Icons.analytics_outlined,
        'action': 'View Reports',
        'route': '/ngo/reports',
      },
      {
        'title': 'Attendance Tracking',
        'subtitle': 'Monitor volunteer check-ins',
        'color': Colors.orange,
        'icon': Icons.fact_check_outlined,
        'action': 'Track Now',
        'route': '/ngo/attendance',
      },
      {
        'title': 'Certificates',
        'subtitle': 'Generate volunteer certificates',
        'color': Colors.teal,
        'icon': Icons.card_membership_outlined,
        'action': 'Generate',
        'route': '/ngo/certificates',
      },
    ];
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home
        Navigator.pushNamed(context, '/ngo');
        break;
      case 1:
        Navigator.pushNamed(context, '/ngo/events');
        break;
      case 2:
        Navigator.pushNamed(context, '/ngo/schedule');
        break;
      case 3:
        Navigator.pushNamed(context, '/ngo/profile');
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
