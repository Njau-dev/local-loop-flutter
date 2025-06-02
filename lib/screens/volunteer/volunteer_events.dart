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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
        subtitle: 'Help distribute meals to families in need',
        color: Colors.orange,
        icon: Icons.restaurant,
      ),
      EventModel(
        id: '2',
        title: 'Beach Cleanup',
        subtitle: 'Environmental conservation effort',
        color: Colors.blue,
        icon: Icons.eco,
      ),
      EventModel(
        id: '3',
        title: 'Elder Care Visit',
        subtitle: 'Spend time with seniors at care homes',
        color: Colors.purple,
        icon: Icons.elderly,
      ),
      EventModel(
        id: '4',
        title: 'Animal Rescue',
        subtitle: 'Help at local animal shelter',
        color: Colors.brown,
        icon: Icons.pets,
      ),
      EventModel(
        id: '5',
        title: 'Tree Planting',
        subtitle: 'City-wide reforestation initiative',
        color: Colors.green,
        icon: Icons.park,
      ),
      EventModel(
        id: '6',
        title: 'Tutoring Kids',
        subtitle: 'Educational support for underprivileged children',
        color: Colors.indigo,
        icon: Icons.school,
      ),
      EventModel(
        id: '7',
        title: 'Community Garden',
        subtitle: 'Help maintain local community garden',
        color: Colors.lightGreen,
        icon: Icons.local_florist,
      ),
      EventModel(
        id: '8',
        title: 'Hospital Support',
        subtitle: 'Assist patients and medical staff',
        color: Colors.red,
        icon: Icons.local_hospital,
      ),
      EventModel(
        id: '9',
        title: 'Library Help',
        subtitle: 'Organize books and help visitors',
        color: Colors.teal,
        icon: Icons.library_books,
      ),
      EventModel(
        id: '10',
        title: 'Disaster Relief',
        subtitle: 'Emergency response and support',
        color: Colors.deepOrange,
        icon: Icons.emergency,
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
        Navigator.pushReplacementNamed(context, '/schedule');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
