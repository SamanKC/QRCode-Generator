import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qrcodegenerator/models/bank_info.dart';
import 'package:qrcodegenerator/models/wifi_info.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wifi_iot/wifi_iot.dart';

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
    this.ctx,
    this.bankInfo,
    this.wifiInfo,
  }) : super(key: key);

  @override
  State<FoundCodeScreen> createState() => _FoundCodeScreenState();
}

class _FoundCodeScreenState extends State<FoundCodeScreen> {
  bool hasdata = false;

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

  bool _isConnecting = false;
  void connectToWifi() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      await WiFiForIoTPlugin.connect(widget.wifiInfo!.ssid!,
          password: widget.wifiInfo!.password, security: NetworkSecurity.WPA);
      if (!mounted) return;
    } catch (e) {
      log('Failed to connect to Wi-Fi: $e');
    }

    setState(() {
      _isConnecting = false;
    });
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
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
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
                      widget.wifiInfo!.password!.isNotEmpty ||
                              widget.wifiInfo!.password != ''
                          ? Column(
                              children: [
                                SelectableText(
                                  "SSID: ${widget.wifiInfo!.ssid}",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Colors.blue, // Customize the text color
                                  ),
                                ),
                                const SizedBox(
                                    height: 16), // Add spacing between elements
                                SelectableText(
                                  "Password: ${widget.wifiInfo!.password}",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .green, // Customize the text color
                                  ),
                                ),
                                const SizedBox(
                                    height: 16), // Add spacing between elements
                                Text(
                                  "Security: ${widget.wifiInfo!.authenticationType}",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .deepOrange, // Customize the text color
                                  ),
                                ),
                                // ElevatedButton(
                                //   onPressed: _isConnecting ? null : connectToWifi,
                                //   child: _isConnecting
                                //       ? CircularProgressIndicator()
                                //       : Text('Connect to Wi-Fi'),
                                // ),
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
                                    log(uri);

                                    if (await canLaunchUrl(Uri.parse(uri))) {
                                      log(uri);
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
                                          "AccountNumber: ${widget.bankInfo!.accountNumber}",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(
                                            height:
                                                16), // Add spacing between elements
                                        SelectableText(
                                          "AccountName: ${widget.bankInfo!.accountName}",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors
                                                .green, // Customize the text color
                                          ),
                                        ),
                                        const SizedBox(
                                            height:
                                                16), // Add spacing between elements
                                        Text(
                                          "AccountType: ${widget.bankInfo!.accountType}",
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        // ElevatedButton(
                                        //   onPressed: _isConnecting ? null : connectToWifi,
                                        //   child: _isConnecting
                                        //       ? CircularProgressIndicator()
                                        //       : Text('Connect to Wi-Fi'),
                                        // ),
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
