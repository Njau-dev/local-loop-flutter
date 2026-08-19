import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../models/event_model.dart';

class QRShareService {
  static Future<void> shareQRCode(
    BuildContext context,
    EventModel event,
    List<int> pngBytes, // Pass the QR as bytes
  ) async {
    try {
      final blob = html.Blob([pngBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor =
          html.AnchorElement(href: url)
            ..download = 'qr_code_${event.id}.png'
            ..style.display = 'none';

      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('QR code downloaded!')));
    } catch (e) {
      debugPrint('Error sharing QR code (web): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
