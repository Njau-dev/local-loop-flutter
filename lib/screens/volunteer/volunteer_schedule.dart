// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../models/schedule_model.dart';

class VolunteerSchedule extends StatefulWidget {
  const VolunteerSchedule({super.key});

  @override
  State<VolunteerSchedule> createState() => _VolunteerScheduleState();
}

class _VolunteerScheduleState extends State<VolunteerSchedule> {
  int _currentNavIndex = 2;
  DateTime _selectedDate = DateTime.now();
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Today',
            style: TextStyle(
              color: Colors.teal[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
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

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
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
            );
          }).toList(),
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
                  'Course',
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: _getScheduleForDate(_selectedDate).length,
                itemBuilder: (context, index) {
                  final schedule = _getScheduleForDate(_selectedDate)[index];
                  return _buildScheduleItem(schedule);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(ScheduleModel schedule) {
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
                  schedule.startTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  schedule.endTime,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Course card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: schedule.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: schedule.color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        schedule.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: schedule.color,
                        ),
                      ),
                      Icon(Icons.more_horiz, color: Colors.grey[400], size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule.subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                      Text(
                        schedule.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: AssetImage(schedule.instructorImage),
                        onBackgroundImageError: (_, __) {},
                        child:
                            schedule.instructorImage.isEmpty
                                ? Text(
                                  schedule.instructor[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        schedule.instructor,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  List<DateTime> _getWeekDays(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  List<ScheduleModel> _getScheduleForDate(DateTime date) {
    // Mock data - replace with actual data fetching logic
    return [
      ScheduleModel(
        id: '1',
        title: 'Mathematics',
        subtitle: 'Chapter 1: Introduction',
        startTime: '11:35',
        endTime: '13:05',
        location: 'Room B-205',
        instructor: 'Brooklyn Williamson',
        instructorImage: '',
        color: const Color(0xFF48CAE4),
        date: date,
      ),
      ScheduleModel(
        id: '2',
        title: 'Biology',
        subtitle: 'Chapter 3: Animal Kingdom',
        startTime: '13:15',
        endTime: '14:45',
        location: 'Room 2-168',
        instructor: 'Julie Watson',
        instructorImage: '',
        color: Colors.grey,
        date: date,
      ),
      ScheduleModel(
        id: '3',
        title: 'Geography',
        subtitle: 'Chapter 2: Economy USA',
        startTime: '15:10',
        endTime: '16:40',
        location: 'Room 1-403',
        instructor: 'Jenny Alexander',
        instructorImage: '',
        color: Colors.grey,
        date: date,
      ),
    ];
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
