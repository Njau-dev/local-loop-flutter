// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../models/event_model.dart';

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
  String _sortBy = 'Date';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Environment',
    'Community',
    'Education',
    'Health',
    'Animals',
    'Emergency',
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
          Row(
            children: [
              const Text(
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
          Text(
            '${_getFilteredEvents().length} opportunities available',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
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
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildFilterDropdown(
                  'Category',
                  _selectedCategory,
                  _categories,
                  (value) => setState(() => _selectedCategory = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Sort by',
                  _sortBy,
                  _sortOptions,
                  (value) => setState(() => _sortBy = value!),
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  child: Text(option, style: const TextStyle(fontSize: 14)),
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
          Text(
            '${_getFilteredEvents().length} Events',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final filteredEvents = _getFilteredEvents();

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
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: Colors.grey),
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
  }

  Widget _buildGridView(List<EventModel> events) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
    return Container(
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(event.icon, color: event.color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              event.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              event.subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '2.5 km away',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _joinEvent(event),
                style: ElevatedButton.styleFrom(
                  backgroundColor: event.color,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Join',
                  style: TextStyle(fontSize: 12, color: Colors.white),
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
      margin: const EdgeInsets.only(bottom: 12),
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
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: event.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(event.icon, color: event.color, size: 24),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(event.subtitle),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '2.5 km away',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '3 hours',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _joinEvent(event),
          style: ElevatedButton.styleFrom(
            backgroundColor: event.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Join', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  List<EventModel> _getFilteredEvents() {
    List<EventModel> events = _getAllEvents();

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      events =
          events.where((event) {
            return event.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                event.subtitle.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      events =
          events.where((event) {
            return _getEventCategory(event) == _selectedCategory;
          }).toList();
    }

    // Sort events
    switch (_sortBy) {
      case 'Date':
        // events.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Distance':
        // events.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 'Popularity':
        // events.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
      case 'Duration':
        // events.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }

    return events;
  }

  String _getEventCategory(EventModel event) {
    // Map events to categories based on their type
    switch (event.title) {
      case 'Beach Cleanup':
      case 'Tree Planting':
        return 'Environment';
      case 'Food Bank Support':
      case 'Community Garden':
        return 'Community';
      case 'Tutoring Kids':
      case 'Library Help':
        return 'Education';
      case 'Elder Care Visit':
      case 'Hospital Support':
        return 'Health';
      case 'Animal Rescue':
      case 'Pet Shelter':
        return 'Animals';
      case 'Disaster Relief':
      case 'Emergency Response':
        return 'Emergency';
      default:
        return 'Community';
    }
  }

  List<EventModel> _getAllEvents() {
    return [
      EventModel(
        id: '1',
        title: 'Food Bank Support',
        description: 'Help distribute meals to families in need',
        category: 'community',
        color: Colors.orange,
        icon: Icons.restaurant,
        startTime: DateTime(2025, 6, 6, 10, 0),
        endTime: DateTime(2025, 6, 6, 14, 0),
        location: 'Downtown Center',
        locationLatitude: -1.2921,
        locationLongitude: 36.8219,
        organizerId: 'org1',
        organizerName: 'Helping Hands',
        createdAt: DateTime(2025, 6, 1, 9, 0),
      ),
      EventModel(
        id: '2',
        title: 'Beach Cleanup',
        description: 'Environmental conservation effort',
        category: 'environment',
        color: Colors.blue,
        icon: Icons.eco,
        startTime: DateTime(2025, 6, 8, 8, 0),
        endTime: DateTime(2025, 6, 8, 12, 0),
        location: 'Sunny Beach',
        locationLatitude: -1.3000,
        locationLongitude: 36.8000,
        organizerId: 'org2',
        organizerName: 'Green Earth',
        createdAt: DateTime(2025, 6, 2, 10, 0),
      ),
      EventModel(
        id: '3',
        title: 'Elder Care Visit',
        description: 'Spend time with seniors at care homes',
        category: 'health',
        color: Colors.purple,
        icon: Icons.elderly,
        startTime: DateTime(2025, 6, 10, 15, 0),
        endTime: DateTime(2025, 6, 10, 18, 0),
        location: 'Sunrise Care Home',
        locationLatitude: -1.2950,
        locationLongitude: 36.8100,
        organizerId: 'org3',
        organizerName: 'Care & Share',
        createdAt: DateTime(2025, 6, 3, 11, 0),
      ),
      EventModel(
        id: '4',
        title: 'Animal Rescue',
        description: 'Help at local animal shelter',
        category: 'animals',
        color: Colors.brown,
        icon: Icons.pets,
        startTime: DateTime(2025, 6, 12, 9, 0),
        endTime: DateTime(2025, 6, 12, 13, 0),
        location: 'City Animal Shelter',
        locationLatitude: -1.3100,
        locationLongitude: 36.8300,
        organizerId: 'org4',
        organizerName: 'Animal Friends',
        createdAt: DateTime(2025, 6, 4, 12, 0),
      ),
      EventModel(
        id: '5',
        title: 'Tree Planting',
        description: 'City-wide reforestation initiative',
        category: 'environment',
        color: Colors.green,
        icon: Icons.park,
        startTime: DateTime(2025, 6, 15, 7, 0),
        endTime: DateTime(2025, 6, 15, 11, 0),
        location: 'Karura Forest',
        locationLatitude: -1.3500,
        locationLongitude: 36.9000,
        organizerId: 'org5',
        organizerName: 'Green Kenya',
        createdAt: DateTime(2025, 6, 5, 13, 0),
      ),
      EventModel(
        id: '6',
        title: 'Tutoring Kids',
        description: 'Educational support for underprivileged children',
        category: 'education',
        color: Colors.indigo,
        icon: Icons.school,
        startTime: DateTime(2025, 6, 18, 14, 0),
        endTime: DateTime(2025, 6, 18, 17, 0),
        location: 'Community Library',
        locationLatitude: -1.3200,
        locationLongitude: 36.8500,
        organizerId: 'org6',
        organizerName: 'Bright Minds',
        createdAt: DateTime(2025, 6, 6, 14, 0),
      ),
      EventModel(
        id: '7',
        title: 'Community Garden',
        description: 'Help maintain local community garden',
        category: 'community',
        color: Colors.lightGreen,
        icon: Icons.local_florist,
        startTime: DateTime(2025, 6, 20, 10, 0),
        endTime: DateTime(2025, 6, 20, 13, 0),
        location: 'Greenfield Estate',
        locationLatitude: -1.3300,
        locationLongitude: 36.8600,
        organizerId: 'org7',
        organizerName: 'Urban Growers',
        createdAt: DateTime(2025, 6, 7, 15, 0),
      ),
      EventModel(
        id: '8',
        title: 'Hospital Support',
        description: 'Assist patients and medical staff',
        category: 'health',
        color: Colors.red,
        icon: Icons.local_hospital,
        startTime: DateTime(2025, 6, 22, 8, 0),
        endTime: DateTime(2025, 6, 22, 12, 0),
        location: 'City Hospital',
        locationLatitude: -1.3400,
        locationLongitude: 36.8700,
        organizerId: 'org8',
        organizerName: 'Health First',
        createdAt: DateTime(2025, 6, 8, 16, 0),
      ),
      EventModel(
        id: '9',
        title: 'Library Help',
        description: 'Organize books and help visitors',
        category: 'education',
        color: Colors.teal,
        icon: Icons.library_books,
        startTime: DateTime(2025, 6, 25, 13, 0),
        endTime: DateTime(2025, 6, 25, 16, 0),
        location: 'Central Library',
        locationLatitude: -1.3500,
        locationLongitude: 36.8800,
        organizerId: 'org9',
        organizerName: 'Book Buddies',
        createdAt: DateTime(2025, 6, 9, 17, 0),
      ),
      EventModel(
        id: '10',
        title: 'Disaster Relief',
        description: 'Emergency response and support',
        category: 'emergency',
        color: Colors.deepOrange,
        icon: Icons.emergency,
        startTime: DateTime(2025, 6, 28, 6, 0),
        endTime: DateTime(2025, 6, 28, 18, 0),
        location: 'Various Locations',
        locationLatitude: -1.3600,
        locationLongitude: 36.8900,
        organizerId: 'org10',
        organizerName: 'Relief Kenya',
        createdAt: DateTime(2025, 6, 10, 18, 0),
      ),
    ];
  }

  void _joinEvent(EventModel event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Join ${event.title}'),
          content: Text(
            'Are you sure you want to join this volunteer event?\n\n${event.subtitle}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully joined ${event.title}!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: event.color),
              child: const Text('Join', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
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
