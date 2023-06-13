import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';

class FoundCodeScreen extends StatefulWidget {
  final Object value;
  final Function() screenClosed;

  const FoundCodeScreen({
    Key? key,
    required this.value,
    required this.screenClosed,
  }) : super(key: key);

  @override
  State<FoundCodeScreen> createState() => _FoundCodeScreenState();
}

class _FoundCodeScreenState extends State<FoundCodeScreen> {
  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Text copied to clipboard")),
    );
  }

  Future<void> saveToGallery() async {
    try {
      final qrImageData = await _generateQrImageData(widget.value.toString());
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(qrImageData!),
        quality: 100,
        name: "QR_Code_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );
      if (result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image saved to gallery")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save image")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save image")),
      );
    }
  }

  Future<Uint8List?> _generateQrImageData(data) async {
    try {
      final qrCode = await QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
        dataModuleStyle: const QrDataModuleStyle(
          color: Colors.white,
          dataModuleShape: QrDataModuleShape.square,
        ),
        eyeStyle:
            const QrEyeStyle(color: Colors.white, eyeShape: QrEyeShape.square),
      ).toImageData(200);
      return qrCode!.buffer.asUint8List();
    } catch (e) {
      print("Error generating QR code: $e");
      return null;
    }
  }

  void shareCode() async {
    try {
      await Share.share(widget.value.toString());
    } catch (e) {
      print("Error sharing QR code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to share QR code")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Found Code"),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        leading: IconButton(
          onPressed: () {
            widget.screenClosed();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Scanned Code:",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    QrImageView(
                      backgroundColor: Colors.white,
                      data: widget.value.toString(),
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.value.toString(),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    copyToClipboard(widget.value.toString());
                  },
                  icon: const Icon(Icons.copy),
                ),
                IconButton(
                  onPressed: saveToGallery,
                  icon: const Icon(Icons.save),
                ),
                IconButton(
                  onPressed: shareCode,
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
