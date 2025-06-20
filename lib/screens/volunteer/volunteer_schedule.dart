// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/schedule_service.dart';

class VolunteerSchedule extends StatefulWidget {
  const VolunteerSchedule({super.key});

  @override
  State<VolunteerSchedule> createState() => _VolunteerScheduleState();
}

class _VolunteerScheduleState extends State<VolunteerSchedule> {
  int _currentNavIndex = 2;
  DateTime _selectedDate = DateTime.now();
  final PageController _pageController = PageController();
  final EventService _eventService = EventService();
  final ScheduleService _scheduleService = ScheduleService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track events with dots
  Map<DateTime, bool> _eventDays = {};

  @override
  void initState() {
    super.initState();
    _loadEventDays();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


void _loadEventDays() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Get current month range
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    // Load events for the current month to mark days with dots
    _scheduleService.getEventsForDateRange(startOfMonth, endOfMonth).listen((
      eventsMap,
    ) {
      final Map<DateTime, bool> eventDays = {};

      // Mark days with joined events
      for (final event in eventsMap['joined'] ?? []) {
        final eventDate = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );
        eventDays[eventDate] = true;
      }

      // Mark days with marked events
      for (final event in eventsMap['marked'] ?? []) {
        final eventDate = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );
        eventDays[eventDate] = true;
      }

      if (mounted) {
        setState(() {
          _eventDays = eventDays;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00664F), // Green primary color
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
      ),
      body: SafeArea(
        child: Column(
          children: [_buildCalendarSection(), _buildScheduleList()],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 20),
          _buildWeekDays(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedDate.day.toString(),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
                height: 1.0,
              ),
            ),
            Text(
              _getFormattedDate(_selectedDate),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _showCalendarModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00664F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: const Color(0xFF00664F),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today',
                  style: TextStyle(
                    color: const Color(0xFF00664F),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    final weekDays = _getWeekDays(_selectedDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          weekDays.map((date) {
            final isSelected = _isSameDay(date, _selectedDate);
            final isToday = _isSameDay(date, DateTime.now());
            final hasEvents =
                _eventDays[DateTime(date.year, date.month, date.day)] ?? false;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFFFF6B35)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected
                                    ? Colors.white
                                    : isToday
                                    ? const Color(0xFFFF6B35)
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    if (hasEvents)
                      Positioned(
                        top: 2,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00664F),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  void _showCalendarModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildCalendarModal(),
    );
  }

  Widget _buildCalendarModal() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getMonthYear(currentMonth),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedDate = DateTime.now();
                  });
                },
                child: const Text('Today'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Calendar grid
          Expanded(child: _buildCalendarGrid(currentMonth)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth + startingWeekday - 1,
      itemBuilder: (context, index) {
        if (index < startingWeekday - 1) {
          return Container(); // Empty cells for days before month starts
        }

        final day = index - startingWeekday + 2;
        final date = DateTime(month.year, month.month, day);
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        final hasEvents = _eventDays[date] ?? false;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFFFF6B35)
                            : isToday
                            ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : isToday
                                ? const Color(0xFFFF6B35)
                                : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (hasEvents)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00664F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleList() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 60),
                const Text(
                  'Event',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Icon(Icons.menu, color: Colors.grey[400], size: 20),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildEventsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return _buildEmptyState('Please log in to view your schedule');
    }

    return StreamBuilder<Map<String, List<EventModel>>>(
      stream: _scheduleService.getEventsForDate(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            'Error loading events: ${snapshot.error.toString()}',
          );
        }

        final eventsMap = snapshot.data ?? {'joined': [], 'marked': []};
        final joinedEvents = eventsMap['joined'] ?? [];
        final markedEvents = eventsMap['marked'] ?? [];
        final allEvents = [...joinedEvents, ...markedEvents];

        if (allEvents.isEmpty) {
          return _buildEmptyState('No events scheduled for this day');
        }

        // Sort events by start time
        allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: allEvents.length,
          itemBuilder: (context, index) {
            final event = allEvents[index];
            final isJoined = joinedEvents.contains(event);
            return _buildEventItem(event, isJoined);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/volunteer/events');
            },
            icon: const Icon(Icons.explore, color: Colors.white),
            label: const Text(
              'Browse Events',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(EventModel event, bool isJoined) {
    final isOngoing = _isEventOngoing(event);
    final isUpcoming = _isEventUpcoming(event);
    final isPast = _isEventPast(event);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(event.startTime),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isOngoing
                            ? const Color(0xFFFF6B35)
                            : isPast
                            ? Colors.grey[500]
                            : Colors.black87,
                  ),
                ),
                Text(
                  _formatTime(event.endTime),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Event card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: isPast ? 0.05 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: event.color.withValues(alpha: isPast ? 0.1 : 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isPast ? Colors.grey[600] : event.color,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOngoing)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Live',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (isPast)
                            Icon(
                              Icons.check_circle,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          if (isUpcoming)
                            Icon(
                              Icons.access_time,
                              color: event.color,
                              size: 20,
                            ),
                          const SizedBox(width: 8),
                          // Action menu button
                          GestureDetector(
                            onTap: () => _showEventOptions(event, isJoined),
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isPast ? Colors.grey[500] : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: event.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          EventCategories.getCategory(event.category)['name'],
                          style: TextStyle(
                            fontSize: 10,
                            color: event.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isJoined)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00664F,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Marked',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF00664F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: event.color.withValues(alpha: 0.2),
                        child: Text(
                          event.organizerName.isNotEmpty
                              ? event.organizerName[0].toUpperCase()
                              : 'O',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: event.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.organizerName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${event.currentVolunteers}/${event.maxVolunteers}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventOptions(EventModel event, bool isJoined) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                if (isJoined) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF00664F),
                    ),
                    title: const Text('View Details'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/volunteer/event-details',
                        arguments: event.id,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Leave Event'),
                    onTap: () {
                      Navigator.pop(context);
                      _leaveEvent(event);
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(
                      Icons.person_add,
                      color: Color(0xFF00664F),
                    ),
                    title: const Text('Join Event'),
                    onTap: () {
                      Navigator.pop(context);
                      _joinEvent(event);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.bookmark_remove,
                      color: Colors.orange,
                    ),
                    title: const Text('Remove from Calendar'),
                    onTap: () {
                      Navigator.pop(context);
                      _removeFromCalendar(event);
                    },
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.blue),
                  title: const Text('Share Event'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareEvent(event);
                  },
                ),
              ],
            ),
      ),
    );
  }

  void _joinEvent(EventModel event) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _eventService.joinEvent(event.id, currentUserId);
      await _scheduleService.removeFromCalendar(event.id);
      await _scheduleService.scheduleEventNotification(event);
      _loadEventDays(); // Refresh event days
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Joined ${event.title}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to join event: $e')));
    }
  }

  void _leaveEvent(EventModel event) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _eventService.leaveEvent(event.id, currentUserId);
      _loadEventDays(); // Refresh event days
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Left ${event.title}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to leave event: $e')));
    }
  }

  void _removeFromCalendar(EventModel event) async {
    try {
      await _scheduleService.removeFromCalendar(event.id);
      _loadEventDays(); // Refresh event days
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${event.title} from calendar')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove from calendar: $e')),
      );
    }
  }

  void _shareEvent(EventModel event) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  String _getFormattedDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${weekdays[date.weekday - 1]}\n${months[date.month - 1]} ${date.year}';
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isEventOngoing(EventModel event) {
    final now = DateTime.now();
    return now.isAfter(event.startTime) && now.isBefore(event.endTime);
  }

  bool _isEventUpcoming(EventModel event) {
    final now = DateTime.now();
    return now.isBefore(event.startTime);
  }

  bool _isEventPast(EventModel event) {
    final now = DateTime.now();
    return now.isAfter(event.endTime);
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final hourString = hour.toString().padLeft(2, '0');
    final minuteString = minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
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
        Navigator.pushReplacementNamed(context, '/volunteer/events');
        break;
      case 2:
        // Already on schedule screen
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/volunteer/profile');
        break;
    }
  }
}
