import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:qrcodegenerator/models/bank_info.dart';
import 'package:qrcodegenerator/models/wifi_info.dart';

class FoundCodeScreen extends StatefulWidget {
  final Object value;
  final Function() screenClosed;
  WifiInfo? wifiInfo;
  final ctx;
  BankInfo? bankInfo;

  FoundCodeScreen({
    Key? key,
    required this.value,
    required this.screenClosed,
    this.wifiInfo,
    this.bankInfo,
    this.ctx,
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
        ScaffoldMessenger.of(widget.ctx).showSnackBar(
          const SnackBar(content: Text("Image saved to gallery")),
        );
      } else {
        ScaffoldMessenger.of(widget.ctx).showSnackBar(
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
      return null;
    }
  }

  void shareCode() async {
    try {
      await Share.share(widget.value.toString());
    } catch (e) {
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
        height: MediaQuery.of(context).size.height,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
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
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
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
                      widget.wifiInfo!.password!.isNotEmpty ||
                              widget.wifiInfo!.password != ''
                          ? Column(
                              children: [
                                SelectableText(
                                  "SSID: ${widget.wifiInfo!.ssid}",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SelectableText(
                                  "Password: ${widget.wifiInfo!.password}",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Security: ${widget.wifiInfo!.authenticationType}",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            )
                          : widget.value.toString().contains('https:')
                              ? SelectableText(
                                  widget.value.toString(),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  onTap: () async {
                                    final uri = widget.value.toString();

                                    if (await canLaunchUrl(Uri.parse(uri))) {
                                      await launchUrl(Uri.parse(uri));
                                    } else {
                                      ScaffoldMessenger.of(widget.ctx)
                                          .showSnackBar(const SnackBar(
                                              content: Text("Invalid url! ")));
                                    }
                                  },
                                )
                              : widget.bankInfo!.accountNumber != "" ||
                                      widget.bankInfo!.accountNumber!.isNotEmpty
                                  ? ListView(
                                      shrinkWrap: true,
                                      children: [
                                        SelectableText(
                                          "Ac-No. : ${widget.bankInfo!.accountNumber}",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SelectableText(
                                          "Account-Name: ${widget.bankInfo!.accountName}",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          "Account-Type: ${widget.bankInfo!.accountType}",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    )
                                  : SelectableText(
                                      widget.value.toString(),
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
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
                      widget.wifiInfo!.password!.isNotEmpty
                          ? copyToClipboard(
                              widget.wifiInfo!.password.toString())
                          : widget.bankInfo!.accountNumber!.isNotEmpty
                              ? copyToClipboard(
                                  widget.bankInfo!.accountNumber!.toString())
                              : copyToClipboard(widget.value.toString());
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
      ),
    );
  }
}
