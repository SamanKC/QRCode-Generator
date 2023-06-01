import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../constants/app_colors.dart';
import '../about/about_screen.dart';

class QRHomePage extends StatefulWidget {
  const QRHomePage({Key? key}) : super(key: key);

  @override
  _QRHomePageState createState() => _QRHomePageState();
}

class _QRHomePageState extends State<QRHomePage> {
  String _generatedQRCode = '';

  void _generateQRCode(String data) {
    setState(() {
      _generatedQRCode = data;
    });
  }

  void _showTextDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController textController = TextEditingController();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter Text',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryColor),
                    ),
                    hintText: 'Enter text here',
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MaterialButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8.0),
                    MaterialButton(
                      child: const Text(
                        'Generate',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                      onPressed: () {
                        String inputText = textController.text;
                        Navigator.pop(context);
                        _generateQRCode(inputText);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
            icon: const Icon(Icons.app_settings_alt_outlined),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double containerSize = constraints.maxWidth * 0.5;
          final double iconSize = constraints.maxWidth * 0.25;
          final double titleFontSize = constraints.maxWidth * 0.06;
          final double subtitleFontSize = constraints.maxWidth * 0.04;
          final double buttonFontSize = constraints.maxWidth * 0.05;
          final double buttonHeight = constraints.maxHeight * 0.05;
          final double buttonBorderWidth = constraints.maxWidth * 0.004;

          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: containerSize,
                    height: containerSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: buttonBorderWidth,
                      ),
                      borderRadius: BorderRadius.circular(containerSize * 0.05),
                    ),
                    child: _generatedQRCode.isNotEmpty
                        ? QrImageView(
                            data: _generatedQRCode,
                            version: QrVersions.auto,
                            size: containerSize,
                          )
                        : Icon(
                            Icons.qr_code_scanner,
                            size: iconSize,
                            color: AppColors.primaryColor,
                          ),
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    'Generate QR Code',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Tap the button below to generate QR codes',
                    style: TextStyle(fontSize: subtitleFontSize),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30.0),
                  OutlinedButton(
                    onPressed: _showTextDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(
                        color: AppColors.primaryColor,
                        width: buttonBorderWidth,
                      ),
                      fixedSize: Size(constraints.maxWidth * 0.5, buttonHeight),
                    ),
                    child: Text(
                      'Generate QR Code',
                      style: TextStyle(fontSize: buttonFontSize),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
