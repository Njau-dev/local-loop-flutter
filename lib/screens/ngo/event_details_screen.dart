import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final EventService _eventService = EventService();
  EventModel? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _eventService.getEventById(widget.eventId);
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF00664F),
          foregroundColor: Colors.white,
          title: const Text('Event Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00664F)),
        ),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF00664F),
          foregroundColor: Colors.white,
          title: const Text('Event Details'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Event not found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventInfo(),
                  const SizedBox(height: 24),
                  _buildScheduleInfo(),
                  const SizedBox(height: 24),
                  _buildLocationInfo(),
                  const SizedBox(height: 24),
                  _buildVolunteerInfo(),
                  const SizedBox(height: 24),
                  _buildOrganizerInfo(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _event!.color,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _event!.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_event!.color, _event!.color.withValues(alpha: 0.8)],
            ),
          ),
          child: Center(
            child: Icon(
              _event!.icon,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editEvent();
                break;
              case 'delete':
                _showDeleteDialog();
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Edit Event'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Event'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _event!.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  EventCategories.getCategory(_event!.category)['name'],
                  style: TextStyle(
                    color: _event!.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _event!.isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _event!.isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _event!.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final duration = _event!.endTime.difference(_event!.startTime);
    final durationText = '${duration.inHours}h ${duration.inMinutes % 60}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start: ${dateFormat.format(_event!.startTime)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timeFormat.format(_event!.startTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_available, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'End: ${dateFormat.format(_event!.endTime)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timeFormat.format(_event!.endTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Text(
                'Duration: $durationText',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _event!.location,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Open maps or location
              },
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _event!.color,
                side: BorderSide(color: _event!.color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerInfo() {
    final progress =
        _event!.maxVolunteers > 0
            ? _event!.currentVolunteers / _event!.maxVolunteers
            : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Volunteers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Text(
                '${_event!.currentVolunteers}/${_event!.maxVolunteers}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _event!.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_event!.color),
          ),
          const SizedBox(height: 12),
          Text(
            progress >= 1.0
                ? 'Event is full!'
                : '${_event!.maxVolunteers - _event!.currentVolunteers} spots remaining',
            style: TextStyle(
              fontSize: 12,
              color: progress >= 1.0 ? Colors.red : Colors.grey[600],
            ),
          ),
          if (_event!.volunteerIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Show volunteer list
                _showVolunteerList();
              },
              icon: const Icon(Icons.people),
              label: const Text('View Volunteers'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _event!.color,
                side: BorderSide(color: _event!.color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrganizerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Organizer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _event!.color.withValues(alpha: 0.1),
                child: Icon(_event!.icon, color: _event!.color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _event!.organizerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Event created ${DateFormat('MMM dd, yyyy').format(_event!.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action button (Join/Leave)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _event!.isActive ? _toggleVolunteerStatus : null,
            icon: Icon(
              _event!.volunteerIds.contains(
                    'current_user_id',
                  ) // Replace with actual user ID check
                  ? Icons.check_circle
                  : Icons.volunteer_activism,
            ),
            label: Text(
              _event!.volunteerIds.contains(
                    'current_user_id',
                  ) // Replace with actual user ID check
                  ? 'Leave Event'
                  : 'Join as Volunteer',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _event!.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareEvent,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _event!.color,
                  side: BorderSide(color: _event!.color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addToCalendar,
                icon: const Icon(Icons.calendar_month),
                label: const Text('Add to Calendar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _event!.color,
                  side: BorderSide(color: _event!.color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  void _editEvent() {
    // Navigate to edit event screen
    Navigator.pushNamed(context, '/edit-event', arguments: _event!.id);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Event'),
            content: const Text(
              'Are you sure you want to delete this event? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _deleteEvent();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteEvent() async {
    try {
      await _eventService.deleteEvent(_event!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVolunteerList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Volunteers (${_event!.currentVolunteers})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _event!.volunteerIds.length,
                          itemBuilder: (context, index) {
                            final volunteerId = _event!.volunteerIds[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _event!.color.withValues(
                                  alpha: 0.1,
                                ),
                                child: Text(
                                  volunteerId.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: _event!.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                'Volunteer ${index + 1}',
                              ), // Replace with actual volunteer name
                              subtitle: Text('ID: $volunteerId'),
                              trailing: const Icon(Icons.person),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _toggleVolunteerStatus() async {
    try {
      const currentUserId = 'current_user_id'; // Replace with actual user ID

      if (_event!.volunteerIds.contains(currentUserId)) {
        // Leave event
        await _eventService.leaveEvent(_event!.id, currentUserId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have left the event'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Join event
        if (_event!.currentVolunteers >= _event!.maxVolunteers) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Event is full!'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await _eventService.joinEvent(_event!.id, currentUserId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have joined the event!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Reload event data
      _loadEvent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update volunteer status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareEvent() {
    // Implement share functionality
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Share Event'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Copy Link'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Copy event link to clipboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text('Share via Message'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Open messaging app
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Share via Email'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Open email app
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _addToCalendar() {
    // Implement add to calendar functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calendar integration coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
