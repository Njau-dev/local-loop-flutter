import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/event_model.dart';

class QRShareService {
  static Future<void> shareQRCode(
    BuildContext context,
    EventModel event,
    String qrData,
    GlobalKey qrKey,
  ) async {
    try {
      // Capture QR code as image
      final boundary =
          qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not capture QR code');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${event.id}.png');
      await file.writeAsBytes(pngBytes);

      // Share the QR code
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

      // Clean up temporary file
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
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

// Add this widget for generating shareable QR codes
class ShareableQRWidget extends StatelessWidget {
  final String qrData;
  final EventModel event;
  final GlobalKey qrKey;

  const ShareableQRWidget({
    super.key,
    required this.qrData,
    required this.event,
    required this.qrKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: qrKey,
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Event Check-in',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00664F),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              '${_formatDateTime(event.startTime)} - ${_formatDateTime(event.endTime)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
              foregroundColor: Colors.black,
            ),
            const SizedBox(height: 20),
            Text(
              'Scan to check in',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
