import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event_model.dart';

class QRShareService {
  static Future<void> shareQRCode(
    BuildContext context,
    EventModel event,
    Uint8List pngBytes, // Pass the QR as bytes
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${event.id}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '''
🎉 Event Check-in QR Code

📅 Event: ${event.title}
🕐 Time: ${_formatDateTime(event.startTime)} - ${_formatDateTime(event.endTime)}
📍 Location: ${event.location}

Volunteers can scan this QR code to check in for the event.

#VolunteerWork #EventCheckIn
        ''',
        subject: 'Check-in QR Code for ${event.title}',
      );

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error sharing QR code (mobile): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
