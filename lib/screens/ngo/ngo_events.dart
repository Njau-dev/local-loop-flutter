import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class NgoEventsScreen extends StatefulWidget {
  const NgoEventsScreen({super.key});

  @override
  State<NgoEventsScreen> createState() => _NgoEventsScreenState();
}

class _NgoEventsScreenState extends State<NgoEventsScreen> {
  int _currentNavIndex = 1;
  bool _isGridView = true;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _sortBy = 'Date';
  final TextEditingController _searchController = TextEditingController();
  final EventService _eventService = EventService();

  final List<String> _statusOptions = [
    'All',
    'Active',
    'Draft',
    'Completed',
    'Cancelled',
  ];

  final List<String> _sortOptions = ['Date', 'Title', 'Volunteers', 'Created'];

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/ngo/create-event'),
        backgroundColor: const Color(0xFF00664F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Event',
          style: TextStyle(color: Colors.white),
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
      color: Color(0xFF00664F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'My Events',
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
            stream: _getFilteredEventsStream(),
            builder: (context, snapshot) {
              final events = snapshot.data ?? [];
              final activeCount = events.where((e) => e.isActive).length;
              final totalVolunteers = events.fold<int>(
                0,
                (sum, e) => sum + e.currentVolunteers,
              );

              return Row(
                children: [
                  _buildStatChip('$activeCount Active', Icons.event_available),
                  const SizedBox(width: 12),
                  _buildStatChip('$totalVolunteers Volunteers', Icons.people),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
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
                hintText: 'Search your events...',
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
                  'Status',
                  _selectedStatus,
                  _statusOptions,
                  (value) => setState(() => _selectedStatus = value!),
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
          StreamBuilder<List<EventModel>>(
            stream: _getFilteredEventsStream(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.length : 0;
              return Text(
                '$count Events',
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
      stream: _getFilteredEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00664F)),
          );
        }

        if (snapshot.hasError) {
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

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No events found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first volunteer event',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.pushNamed(context, '/ngo/create-event'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00664F),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _isGridView ? _buildGridView(events) : _buildListView(events),
        );
      },
    );
  }

  Widget _buildGridView(List<EventModel> events) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
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
    // final isCompleted = event.endTime.isBefore(DateTime.now());
    final progressPercent =
        event.maxVolunteers > 0
            ? (event.currentVolunteers / event.maxVolunteers).clamp(0.0, 1.0)
            : 0.0;

    return GestureDetector(
      onTap: () => _navigateToEventDetails(event),
      child: Container(
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
              // Header with icon and status
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: event.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(event.icon, color: event.color, size: 20),
                  ),
                  const Spacer(),
                  _buildStatusChip(event),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                event.subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.currentVolunteers}/${event.maxVolunteers} volunteers',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(event.color),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _navigateToEventDetails(event),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.color,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                  // const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventListTile(EventModel event) {
    // final isCompleted = event.endTime.isBefore(DateTime.now());
    final progressPercent =
        event.maxVolunteers > 0
            ? (event.currentVolunteers / event.maxVolunteers).clamp(0.0, 1.0)
            : 0.0;

    return GestureDetector(
      onTap: () => _navigateToEventDetails(event),
      child: Container(
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
          title: Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusChip(event),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(event.subtitle),
              const SizedBox(height: 8),

              // Progress
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event.currentVolunteers}/${event.maxVolunteers} volunteers',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progressPercent,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            event.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${(progressPercent * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, event),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View Details'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit Event')),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(EventModel event) {
    final now = DateTime.now();
    String status;
    Color statusColor;

    if (!event.isActive) {
      status = 'Inactive';
      statusColor = Colors.grey;
    } else if (event.endTime.isBefore(now)) {
      status = 'Completed';
      statusColor = Colors.green;
    } else if (event.startTime.isBefore(now)) {
      status = 'Live';
      statusColor = Colors.orange;
    } else {
      status = 'Upcoming';
      statusColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<EventModel>> _getFilteredEventsStream() {
    final currentUserId = _eventService.getCurrentUserId();
    if (currentUserId == null) return Stream.value([]);

    Stream<List<EventModel>> eventsStream;

    // Get events created by this NGO
    if (_searchQuery.isNotEmpty) {
      eventsStream = _eventService.searchEvents(_searchQuery);
    } else {
      eventsStream = _eventService.getEventsByOrganizer(currentUserId);
    }

    return eventsStream.map((events) {
      // Filter by current user's events only
      List<EventModel> filteredEvents =
          events.where((event) => event.organizerId == currentUserId).toList();

      // Apply status filter
      if (_selectedStatus != 'All') {
        final now = DateTime.now();
        filteredEvents =
            filteredEvents.where((event) {
              switch (_selectedStatus) {
                case 'Active':
                  return event.isActive && event.endTime.isAfter(now);
                case 'Draft':
                  return !event.isActive;
                case 'Completed':
                  return event.endTime.isBefore(now);
                case 'Cancelled':
                  return !event.isActive;
                default:
                  return true;
              }
            }).toList();
      }

      // Apply sorting
      switch (_sortBy) {
        case 'Date':
          filteredEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
          break;
        case 'Title':
          filteredEvents.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'Volunteers':
          filteredEvents.sort(
            (a, b) => b.currentVolunteers.compareTo(a.currentVolunteers),
          );
          break;
        case 'Created':
          filteredEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }

      return filteredEvents;
    });
  }

  void _navigateToEventDetails(EventModel event) {
    Navigator.pushNamed(context, '/ngo/event-details', arguments: event.id);
  }

  void _handleMenuAction(String action, EventModel event) {
    switch (action) {
      case 'view':
        _navigateToEventDetails(event);
        break;
      case 'duplicate':
        _duplicateEvent(event);
        break;
      case 'delete':
        _showDeleteConfirmation(event);
        break;
    }
  }

  void _duplicateEvent(EventModel event) {
    // Navigate to create event with pre-filled data
    Navigator.pushNamed(context, '/ngo/create-event', arguments: event);
  }

  void _showDeleteConfirmation(EventModel event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: Text(
            'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _eventService.deleteEvent(event.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete event: ${e.toString()}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
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
        Navigator.pushReplacementNamed(context, '/ngo');
        break;
      case 1:
        // Already on events screen
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/ngo/schedule');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/ngo/profile');
        break;
    }
  }
}
