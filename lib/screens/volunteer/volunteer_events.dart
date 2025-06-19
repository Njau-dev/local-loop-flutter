// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class VolunteerEvents extends StatefulWidget {
  const VolunteerEvents({super.key});

  @override
  State<VolunteerEvents> createState() => _VolunteerEventsState();
}

class _VolunteerEventsState extends State<VolunteerEvents> {
  int _currentNavIndex = 1;
  bool _isGridView = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _sortBy = 'Date';
  final TextEditingController _searchController = TextEditingController();
  final EventService _eventService = EventService();

  final List<String> _categories = [
    'All',
    'Environment',
    'Community',
    'Education',
    'Health',
    'Animals',
    'Emergency',
  ];

  final List<String> _statusOptions = [
    'All',
    'Active',
    'Ongoing',
    'Inactive',
    'Cancelled',
  ];

  final List<String> _sortOptions = [
    'Date',
    'Distance',
    'Popularity',
    'Duration',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00664F),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            _buildViewToggle(),
            Expanded(child: _buildEventsList()),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF00664F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Volunteer Events',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<EventModel>>(
            stream: _eventService.getAllEvents(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.length : 0;
              return Text(
                '$count opportunities available',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search events...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: _buildFilterDropdown(
                    'Category',
                    _selectedCategory,
                    _categories,
                    (value) => setState(() => _selectedCategory = value!),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: _buildFilterDropdown(
                    'Status',
                    _selectedStatus,
                    _statusOptions,
                    (value) => setState(() => _selectedStatus = value!),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: _buildFilterDropdown(
                    'Sort by',
                    _sortBy,
                    _sortOptions,
                    (value) => setState(() => _sortBy = value!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items:
              options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<List<EventModel>>(
            stream: _eventService.getAllEvents(),
            builder: (context, snapshot) {
              final filteredEvents = _getFilteredEvents(snapshot.data ?? []);
              return Text(
                '${filteredEvents.length} Events',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  Icons.grid_view,
                  _isGridView,
                  () => setState(() => _isGridView = true),
                ),
                _buildToggleButton(
                  Icons.list,
                  !_isGridView,
                  () => setState(() => _isGridView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFF00664F) : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return StreamBuilder<List<EventModel>>(
      stream: _eventService.getAllEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00664F)),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading events:\n${snapshot.error}',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];
        final filteredEvents = _getFilteredEvents(events);

        if (filteredEvents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No events found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              _isGridView
                  ? _buildGridView(filteredEvents)
                  : _buildListView(filteredEvents),
        );
      },
    );
}

  Widget _buildGridView(List<EventModel> events) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
        childAspectRatio: MediaQuery.of(context).size.width < 400 ? 0.75 : 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) => _buildEventCard(events[index]),
    );
  }

  Widget _buildListView(List<EventModel> events) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: events.length,
      itemBuilder: (context, index) => _buildEventListTile(events[index]),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: isSmallScreen ? 35 : 40,
              width: isSmallScreen ? 35 : 40,
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                event.icon,
                color: event.color,
                size: isSmallScreen ? 18 : 20,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              event.title,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              event.subtitle,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 11,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            _buildStatusBadge(event),
            SizedBox(height: isSmallScreen ? 4 : 6),
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 28 : 32,
              child: ElevatedButton(
                onPressed: () => _navigateToEventDetails(event.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00664F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventListTile(EventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: event.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(event.icon, color: event.color, size: 22),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              event.subtitle,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            _buildStatusBadge(event),
          ],
        ),
        trailing: SizedBox(
          width: 80,
          height: 32,
          child: ElevatedButton(
            onPressed: () => _navigateToEventDetails(event.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00664F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'View',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(EventModel event) {
    final now = DateTime.now();
    String status;
    Color statusColor;

    if (!event.isActive) {
      status = 'Cancelled';
      statusColor = Colors.red;
    } else if (now.isAfter(event.endTime)) {
      status = 'Inactive';
      statusColor = Colors.grey;
    } else if (now.isAfter(event.startTime) && now.isBefore(event.endTime)) {
      status = 'Ongoing';
      statusColor = Colors.orange;
    } else {
      status = 'Active';
      statusColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<EventModel> _getFilteredEvents(List<EventModel> events) {
    List<EventModel> filteredEvents = List.from(events);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredEvents =
          filteredEvents.where((event) {
            return event.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                event.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                event.location.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filteredEvents =
          filteredEvents.where((event) {
            return _getEventCategory(event) == _selectedCategory;
          }).toList();
    }

    // Filter by status
    if (_selectedStatus != 'All') {
      final now = DateTime.now();
      filteredEvents =
          filteredEvents.where((event) {
            switch (_selectedStatus) {
              case 'Active':
                return event.isActive && now.isBefore(event.startTime);
              case 'Ongoing':
                return event.isActive &&
                    now.isAfter(event.startTime) &&
                    now.isBefore(event.endTime);
              case 'Inactive':
                return event.isActive && now.isAfter(event.endTime);
              case 'Cancelled':
                return !event.isActive;
              default:
                return true;
            }
          }).toList();
    }

    // Sort events
    switch (_sortBy) {
      case 'Date':
        filteredEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case 'Distance':
        // For now, sort randomly since we don't have user location
        filteredEvents.shuffle();
        break;
      case 'Popularity':
        filteredEvents.sort(
          (a, b) => b.currentVolunteers.compareTo(a.currentVolunteers),
        );
        break;
      case 'Duration':
        filteredEvents.sort((a, b) {
          final aDuration = a.endTime.difference(a.startTime).inHours;
          final bDuration = b.endTime.difference(b.startTime).inHours;
          return aDuration.compareTo(bDuration);
        });
        break;
    }

    return filteredEvents;
  }

  String _getEventCategory(EventModel event) {
    // Map events to categories based on their category field
    final categoryMap = {
      'environment': 'Environment',
      'community': 'Community',
      'education': 'Education',
      'health': 'Health',
      'animals': 'Animals',
      'emergency': 'Emergency',
    };
    
    return categoryMap[event.category] ?? 'Community';
  }

  void _navigateToEventDetails(String eventId) {
    Navigator.pushNamed(
      context,
      '/volunteer/event-details',
      arguments: eventId,
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/volunteer');
        break;
      case 1:
        // Already on events screen
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/volunteer/schedule');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/volunteer/profile');
        break;
    }
  }
}
