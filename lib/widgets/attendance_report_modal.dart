import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../services/event_service.dart';
import '../services/attendance_service.dart';

class AttendanceReportModal extends StatelessWidget {
  final String eventId;
  final EventService eventService;
  final AttendanceService attendanceService;

  const AttendanceReportModal({
    super.key,
    required this.eventId,
    required this.eventService,
    required this.attendanceService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Report',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(),

          // Stats section
          _buildStatsSection(),

          // Attendance list
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: eventService.getJoinedVolunteers(eventId),
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
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading attendance data',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final volunteers = snapshot.data ?? [];

                if (volunteers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No volunteers registered',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: volunteers.length,
                  itemBuilder: (context, index) {
                    final volunteer = volunteers[index];
                    return _buildAttendanceItem(context, volunteer);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<List<UserModel>>(
      stream: eventService.getJoinedVolunteers(eventId),
      builder: (context, volunteersSnapshot) {
        if (!volunteersSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final totalVolunteers = volunteersSnapshot.data!.length;

        return StreamBuilder<List<AttendanceModel>>(
          stream: attendanceService.getEventAttendance(eventId),
          builder: (context, attendanceSnapshot) {
            final attendedCount = attendanceSnapshot.data?.length ?? 0;
            final attendanceRate =
                totalVolunteers > 0
                    ? (attendedCount / totalVolunteers * 100).round()
                    : 0;

            return Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00664F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00664F).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Registered',
                    totalVolunteers.toString(),
                    Icons.people,
                  ),
                  _buildStatItem(
                    'Attended',
                    attendedCount.toString(),
                    Icons.check_circle,
                  ),
                  _buildStatItem('Rate', '$attendanceRate%', Icons.analytics),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00664F), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00664F),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAttendanceItem(BuildContext context, UserModel volunteer) {
    return StreamBuilder<List<AttendanceModel>>(
      stream: attendanceService.getEventAttendance(eventId),
      builder: (context, attendanceSnapshot) {
        final attendanceList = attendanceSnapshot.data ?? [];
        final hasAttended = attendanceList.any(
          (attendance) => attendance.volunteerId == volunteer.uid,
        );

        final attendanceRecord = attendanceList.firstWhere(
          (attendance) => attendance.volunteerId == volunteer.uid,
          orElse:
              () => AttendanceModel(
                id: '',
                eventId: eventId,
                volunteerId: volunteer.uid,
                volunteerName: volunteer.username ?? 'Volunteer',
                volunteerEmail: volunteer.email,
                signInTime: DateTime.now(),
                status: AttendanceStatus.absent,
                totalHours: 0,
                createdAt: DateTime.now(),
              ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasAttended ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasAttended ? Colors.green[200]! : Colors.red[200]!,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 25,
                backgroundColor: hasAttended ? Colors.green : Colors.red,
                child: Text(
                  volunteer.username!.isNotEmpty
                      ? volunteer.username![0].toUpperCase()
                      : 'V',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Volunteer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteer.username ?? 'Volunteer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      volunteer.email,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (hasAttended) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Checked in: ${_formatTime(attendanceRecord.signInTime ?? DateTime.now())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Status and action
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: hasAttended ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      hasAttended ? 'Present' : 'Absent',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (!hasAttended) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap:
                          () => _sendReminderNotification(context, volunteer),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Remind',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _sendReminderNotification(BuildContext context, UserModel volunteer) {
    // TODO: Implement notification sending
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder sent to ${volunteer.username}'),
        backgroundColor: const Color(0xFF00664F),
      ),
    );
  }
}
