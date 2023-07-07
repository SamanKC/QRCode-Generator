import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrcodegenerator/models/bank_info.dart';
import 'package:qrcodegenerator/models/wifi_info.dart';
import 'package:share_plus/share_plus.dart';
import '../../bloc/permission_bloc.dart';
import '../../bloc/permission_event.dart';
import '../../bloc/permission_state.dart';
import '../../constants/app_colors.dart';
import '../about/about_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/custom_snack_bar.dart';
import '../widgets/scanner_error_widgert.dart';
import 'foundcode_screen.dart';

class QRHomePage extends StatefulWidget {
  const QRHomePage({Key? key}) : super(key: key);

  @override
  _QRHomePageState createState() => _QRHomePageState();
}

class _QRHomePageState extends State<QRHomePage>
    with SingleTickerProviderStateMixin {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  String _generatedQRCode = '';
  int _selectedTabIndex = 0;
  TabController? _tabController;
  Barcode? barCode;
  BarcodeCapture? barCodeCapture;
  MobileScannerArguments? arguments;
  bool isStarted = true;
  double _zoomFactor = 0.0;
  bool _screenOpened = false;
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = false;

  void _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    context.read<PermissionBloc>().add(CheckPermissionEvent());
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  void startScanning() {
    if (!isScanning) {
      isScanning = true;
      cameraController.start();
    }
  }

  void stopScanning() {
    if (isScanning) {
      isScanning = false;
      cameraController.stop();
    }
  }

  void onScanComplete(String result) {
    isScanning = false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    setState(() {
      _selectedTabIndex = _tabController!.index;
      if (_selectedTabIndex == 1) {
        context.read<PermissionBloc>().add(RequestPermissionEvent());
      } else {
        if (cameraController != null) {
          cameraController.dispose();
        }
        cameraController = MobileScannerController();
      }
    });
  }

  void _generateQRCode(String data) {
    setState(() {
      _generatedQRCode = data;
    });
  }

  void copyToClipboard(String text, ctx) {
    Clipboard.setData(ClipboardData(text: text));

    CustomSnackbar.show(ctx, 'Text copied to clipboard');
  }

  Future<void> saveToGallery(ctx) async {
    try {
      final qrImageData =
          await _generateQrImageData(_generatedQRCode.toString());
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(qrImageData!),
        quality: 100,
        name: "QR_Code_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );
      if (result['isSuccess']) {
        CustomSnackbar.show(ctx, 'Image saved to gallery');
      } else {
        CustomSnackbar.show(ctx, 'Failed to save image');
      }
    } catch (e) {
      CustomSnackbar.show(ctx, 'Failed to save image');
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

  void shareCode(ctx) async {
    try {
      await Share.share(_generatedQRCode.toString());
    } catch (e) {
      CustomSnackbar.show(ctx, 'Failed to share QR code');
    }
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
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(),
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
                      ),
                      onPressed: () {
                        String inputText = textController.text;
                        Navigator.pop(context);
                        _generateQRCode(inputText);

                        CustomSnackbar.show(context, 'QRCode Generated!',
                            color: Colors.green);
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
        title: const Text(
          'QR Code Generator',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          enableFeedback: true,
          controller: _tabController,
          labelStyle: const TextStyle(fontSize: 16),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.generating_tokens_rounded,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Generator',
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded),
                  SizedBox(width: 5),
                  Text(
                    'Scanner',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneratorTab(),
          _buildScannerTab(),
        ],
      ),
    );
  }

  Widget _buildGeneratorTab() {
    return LayoutBuilder(
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
                      width: buttonBorderWidth,
                    ),
                    borderRadius: BorderRadius.circular(containerSize * 0.05),
                  ),
                  child: _generatedQRCode.isNotEmpty
                      ? QrImageView(
                          backgroundColor: Colors.white,
                          data: _generatedQRCode,
                          version: QrVersions.auto,
                          size: containerSize,
                        )
                      : Icon(
                          Icons.qr_code_scanner,
                          size: iconSize,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(constraints.maxWidth * 0.5, buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Generate QR Code',
                    style: TextStyle(fontSize: buttonFontSize),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        copyToClipboard(_generatedQRCode.toString(), context);
                      },
                      icon: const Icon(Icons.copy),
                    ),
                    IconButton(
                      onPressed: () {
                        saveToGallery(context);
                      },
                      icon: const Icon(Icons.save),
                    ),
                    IconButton(
                      onPressed: () {
                        shareCode(context);
                      },
                      icon: const Icon(Icons.share),
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

  Widget _buildScannerTab() {
    return BlocBuilder<PermissionBloc, PermissionState>(
      builder: (context, state) {
        if (state is PermissionGrantedState) {
          return scanCamera();
        } else if (state is PermissionDeniedState) {
          return _buildPermissionRequiredWidget(state);
        } else if (state is PermissionPermanentlyDeniedState) {
          return _buildPermissionRequiredWidget(state);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildPermissionRequiredWidget(PermissionState state) {
    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: true,
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      header: const WaterDropHeader(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state is PermissionDeniedState
                  ? state.deniedMessage
                  : state is PermissionPermanentlyDeniedState
                      ? state.permanentlyDeniedMessage
                      : "",
              style: const TextStyle(
                fontSize: 26.0,
                fontStyle: FontStyle.italic,
                height: 1.5,
                // color: Colors.black, // Set the text color
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            OutlinedButton(
              style: ElevatedButton.styleFrom(
                // backgroundColor:
                //     Colors.deepOrange, // Set the button background color
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8.0), // Set the button border radius
                ),
              ),
              onPressed: () {
                if (state is PermissionDeniedState) {
                  context.read<PermissionBloc>().add(CheckPermissionEvent());
                } else if (state is PermissionPermanentlyDeniedState) {
                  openAppSettings();
                }
              },
              child: Text(
                state is PermissionGrantedState
                    ? 'Open Settings'
                    : 'Check Permission',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Set the button text color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  WifiInfo extractWifiInfo(String qrCodeData) {
    RegExp wifiPattern = RegExp(
      r'^WIFI:S:([^;]+);T:([^;]+);P:([^;]+);',
      caseSensitive: false,
      multiLine: true,
    );
    if (qrCodeData != '' && qrCodeData.isNotEmpty) {
      try {
        Match? match = wifiPattern.firstMatch(qrCodeData);
        if (match != null) {
          String ssid = match.group(1)!;
          String authenticationType = match.group(2)!;
          String password = match.group(3)!;

          return (WifiInfo(
              ssid: ssid,
              password: password,
              authenticationType: authenticationType));
        } else if (match == null) {
          return (WifiInfo(ssid: "", password: "", authenticationType: ""));
        } else {
          CustomSnackbar.show(context, 'Invalid Wi-Fi QR code');
        }
      } catch (e) {
        CustomSnackbar.show(context, 'Error extracting Wi-Fi password: QR');
      }
    }

    return (WifiInfo(ssid: "", password: "", authenticationType: ""));
  }

  BankInfo extractBankInfo(String qrCodeData) {
    RegExp bankInfoRegex = RegExp(
        r'{"accountNumber":"(.+?)","accountName":"(.+?)","bankCode":"(.+?)","accountType":"(.+?)"}',
        caseSensitive: false,
        multiLine: true);

    if (qrCodeData != '' && qrCodeData.isNotEmpty) {
      try {
        Match? match = bankInfoRegex.firstMatch(qrCodeData);
        if (match != null) {
          String? accountNumber = match.group(1)!;
          String? accountName = match.group(2)!;
          // String? bankCode = match.group(3)!;
          String? accountType = match.group(4)!;

          return (BankInfo(
              accountNumber: accountNumber,
              accountName: accountName,
              accountType: accountType));
        } else if (match == null) {
          return (BankInfo(
              accountName: "", accountNumber: "", accountType: ""));
        } else {
          CustomSnackbar.show(context, 'Invalid QR');
        }
      } catch (e) {
        CustomSnackbar.show(context, 'Error extracting bank info: QR');
      }
    }

    return (BankInfo(accountName: "", accountNumber: "", accountType: ""));
  }

  void _foundCode(BarcodeCapture barcode) {
    WifiInfo? wifiInfo;

    BankInfo? bankInfo;

    if (!_screenOpened) {
      final code = barcode.barcodes[0].rawValue ?? "No code available";

      _screenOpened = true;

      wifiInfo = extractWifiInfo(code.toString());

      bankInfo = extractBankInfo(code.toString());

      CustomSnackbar.show(context, 'QRCode Generated!', color: Colors.green);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoundCodeScreen(
            value: code,
            ctx: context,
            bankInfo: bankInfo,
            wifiInfo: wifiInfo,
            screenClosed: _screenWasClosed,
          ),
        ),
      );
    }
  }

  void _screenWasClosed() {
    _screenOpened = false;
  }

  void _startOrStop(ctx) {
    try {
      if (isStarted) {
        cameraController.stop();
      } else {
        cameraController.start();
      }
      setState(() {
        isStarted = !isStarted;
      });
    } on Exception catch (e) {
      CustomSnackbar.show(ctx, 'Something went wrong! $e', color: Colors.red);
    }
  }

  Widget scanCamera() {
    return Column(
      children: [
        Flexible(
          child: MobileScanner(
            controller: cameraController,
            fit: BoxFit.cover,
            onDetect: _foundCode,
            errorBuilder: (context, error, child) {
              return ScannerErrorWidget(error: error);
            },
          ),
        ),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.black, // Set the background color
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 5.0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                color: Colors.white,
                icon: ValueListenableBuilder(
                  valueListenable: cameraController.torchState,
                  builder: (context, state, child) {
                    if (state == null) {
                      return const Icon(
                        Icons.flash_off,
                        color: Colors.grey,
                      );
                    }
                    switch (state) {
                      case TorchState.off:
                        return const Icon(
                          Icons.flash_off,
                          color: Colors.grey,
                        );
                      case TorchState.on:
                        return const Icon(
                          Icons.flash_on,
                          color: Colors.yellow,
                        );
                    }
                  },
                ),
                iconSize: 32.0,
                onPressed: () {
                  if (isStarted) {
                    cameraController.toggleTorch();
                  }
                },
              ),
              IconButton(
                icon: isStarted
                    ? const Icon(Icons.stop)
                    : const Icon(Icons.play_arrow),
                iconSize: 32.0,
                onPressed: () {
                  _startOrStop(context);
                },
                color: Colors.white, // Set the button color
              ),
              const Center(
                child: SizedBox(
                  height: 40,
                  child: FittedBox(
                    child: Text(
                      'Scan',
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        color: Colors.white, // Set the text color
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.image),
                iconSize: 28.0,
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    if (await cameraController.analyzeImage(image.path)) {
                      if (!mounted) return;
                    } else {
                      if (!mounted) return;

                      CustomSnackbar.show(context, 'No QRCode found!',
                          color: Colors.red);
                    }
                  }
                },
                color: Colors.white, // Set the button color
              ),
              IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: cameraController.cameraFacingState,
                  builder: (context, state, child) {
                    if (state == null) {
                      return const Icon(Icons.camera_front);
                    }
                    switch (state) {
                      case CameraFacing.front:
                        return const Icon(Icons.camera_front);
                      case CameraFacing.back:
                        return const Icon(Icons.camera_rear);
                    }
                  },
                ),
                iconSize: 32.0,
                onPressed: () => cameraController.switchCamera(),
                color: Colors.white, // Set the button color
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    cameraController.dispose();

    super.dispose();
  }
}
