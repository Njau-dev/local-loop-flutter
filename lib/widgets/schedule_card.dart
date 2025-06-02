import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String room;
  final String instructor;
  final Color color;

  const ScheduleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.room,
    required this.instructor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        room,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        instructor,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // Handle more options
              },
              icon: const Icon(Icons.more_vert, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
