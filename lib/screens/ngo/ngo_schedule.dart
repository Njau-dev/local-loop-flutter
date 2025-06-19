// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/schedule_service.dart';

class NgoSchedule extends StatefulWidget {
  const NgoSchedule({super.key});

  @override
  State<NgoSchedule> createState() => _NgoScheduleState();
}

class _NgoScheduleState extends State<NgoSchedule> {
  int _currentNavIndex = 2;
  DateTime _selectedDate = DateTime.now();
  final PageController _pageController = PageController();
  final EventService _eventService = EventService();
  final ScheduleService _scheduleService = ScheduleService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track events with dots
  Map<DateTime, bool> _eventDays = {};

  late Stream<List<EventModel>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _loadEventDays();

    _eventsStream = FirebaseFirestore.instance
        .collection('events')
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => EventModel.fromFirestore(doc))
                  .toList(),
        );
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

    // Load NGO's created events for the current month
    _eventService
        .getNgoEventsForDateRange(currentUserId, startOfMonth, endOfMonth)
        .listen((events) {
          final Map<DateTime, bool> eventDays = {};

          // Mark days with NGO events
          for (final event in events) {
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
        title: const Text(
          'My Events Schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
                  'My Events',
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
      return _buildEmptyState('Please log in to view your events');
    }

    return StreamBuilder<List<EventModel>>(
      stream: _eventService.getNgoEventsForDate(currentUserId, _selectedDate),
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

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return _buildEmptyState('No events scheduled for this day');
        }

        // Sort events by start time
        events.sort((a, b) => a.startTime.compareTo(b.startTime));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventItem(event);
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
          Icon(Icons.event_note_outlined, size: 64, color: Colors.grey[400]),
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
              Navigator.pushReplacementNamed(context, '/ngo/events');
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create Event',
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

  Widget _buildEventItem(EventModel event) {
    final isOngoing = _isEventOngoing(event);
    final isUpcoming = _isEventUpcoming(event);
    final isPast = _isEventPast(event);
    final canShowQR = _canShowQRCode(event);

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
                          if (canShowQR)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00664F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'QR Ready',
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
                            Icon(Icons.schedule, color: event.color, size: 20),
                          const SizedBox(width: 8),
                          // Action menu button
                          GestureDetector(
                            onTap: () => _showEventOptions(event),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00664F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Organizer',
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
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Volunteers: ${event.currentVolunteers}/${event.maxVolunteers}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (isPast)
                        StreamBuilder<int>(
                          stream: Stream.fromFuture(
                            _eventService.getEventAttendanceCount(event.id),
                          ),
                          builder: (context, snapshot) {
                            final attendanceCount = snapshot.data ?? 0;
                            return Text(
                              'Attended: $attendanceCount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
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

  void _showEventOptions(EventModel event) {
    final canShowQR = _canShowQRCode(event);
    final isPast = _isEventPast(event);

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
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF00664F),
                  ),
                  title: const Text('View Event Details'),
                  onTap: () {
                    Navigator.pop(context);
                    _viewEventDetails(event);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: Color(0xFF00664F)),
                  title: const Text('View Joined Volunteers'),
                  onTap: () {
                    Navigator.pop(context);
                    _viewJoinedVolunteers(event);
                  },
                ),
                if (canShowQR)
                  ListTile(
                    leading: const Icon(
                      Icons.qr_code,
                      color: Color(0xFFFF6B35),
                    ),
                    title: const Text('Show Check-in QR Code'),
                    onTap: () {
                      Navigator.pop(context);
                      _showQRCode(event);
                    },
                  ),
                if (isPast || _isEventOngoing(event))
                  ListTile(
                    leading: const Icon(
                      Icons.assignment_turned_in,
                      color: Color(0xFF00664F),
                    ),
                    title: const Text('View Attendance Report'),
                    onTap: () {
                      Navigator.pop(context);
                      _viewAttendanceReport(event);
                    },
                  ),

                if (!isPast)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Cancel Event'),
                    onTap: () {
                      Navigator.pop(context);
                      _cancelEvent(event);
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _showQRCode(EventModel event) {
    final qrData = '${event.id}|${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Check-in QR Code',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Volunteers can scan this QR code to check in',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareQRCode(event, qrData),
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: const Text(
                            'Close',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _viewEventDetails(EventModel event) {
    Navigator.pushNamed(context, '/ngo/event-details', arguments: event);
  }

  void _viewJoinedVolunteers(EventModel event) {
    Navigator.pushNamed(context, '/ngo/joined-volunteers', arguments: event.id);
  }

  void _viewAttendanceReport(EventModel event) {
    Navigator.pushNamed(context, '/ngo/attendance-report', arguments: event.id);
  }

  void _shareQRCode(EventModel event, String qrData) {
    // Implement QR code sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code sharing functionality coming soon'),
      ),
    );
  }

  void _cancelEvent(EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Event'),
            content: Text(
              'Are you sure you want to cancel "${event.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Event'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Cancel Event',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _eventService.cancelEvent(event.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event cancelled successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error cancelling event: $e')));
        }
      }
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthYear(DateTime date) {
    return '${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
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
    return months[month - 1];
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final List<DateTime> weekDays = [];
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    for (int i = 0; i < 7; i++) {
      weekDays.add(startOfWeek.add(Duration(days: i)));
    }
    return weekDays;
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    // Handle navigation
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/ngo');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/ngo/events');
        break;
      case 2:
        // Already on schedule screen
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/ngo/profile');
        break;
    }
  }

  bool _isEventOngoing(EventModel event) {
    final now = DateTime.now();
    return event.startTime.isBefore(now) && event.endTime.isAfter(now);
  }

  bool _isEventUpcoming(EventModel event) {
    final now = DateTime.now();
    return event.startTime.isAfter(now);
  }

  bool _isEventPast(EventModel event) {
    final now = DateTime.now();
    return event.endTime.isBefore(now);
  }

  bool _canShowQRCode(EventModel event) {
    final now = DateTime.now();
    return event.startTime.isBefore(now) && event.endTime.isAfter(now);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
