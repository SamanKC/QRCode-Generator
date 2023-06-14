import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../bloc/permission_bloc.dart';
import '../../bloc/permission_event.dart';
import '../../bloc/permission_state.dart';
import '../../constants/app_colors.dart';
import '../about/about_screen.dart';
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

  void _onRefresh() async {
    // monitor network fetch
    await Future.delayed(const Duration(milliseconds: 1000));

    context.read<PermissionBloc>().add(CheckPermissionEvent());
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    await Future.delayed(const Duration(milliseconds: 1000));
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

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

  // Declare the boolean variable to track scanning status
  bool isScanning = false;

// Method to start scanning
  void startScanning() {
    if (!isScanning) {
      isScanning = true;
      // Call the start() method of the scanner here
      cameraController.start();
    }
  }

// Method to stop scanning
  void stopScanning() {
    if (isScanning) {
      isScanning = false;
      // Call the stop() method of the scanner here
      cameraController.stop();
    }
  }

// Method to handle scan completion
  void onScanComplete(String result) {
    // Process the scan result here
    // ...

    // Set isScanning back to false
    isScanning = false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabSelection);
    // checkCameraPermission();
  }

  @override
  void dispose() {
    cameraController.dispose();

    super.dispose();
  }

  // void _handleTabSelection() {
  //   setState(() {
  //     _selectedTabIndex = _tabController!.index;
  //     if (_selectedTabIndex == 1) {
  //       // Second tab is selected, check camera permission
  //       // checkCameraPermission();
  //       // context.read<PermissionBloc>().askPermission();
  //       context.read<PermissionBloc>().add(RequestPermissionEvent());
  //       _initializeMobileScannerController();
  //     } else {
  //       // First tab was unselected, so we need to re-initialize controller
  //       cameraController.dispose();
  //     }
  //   });
  // }

  void _handleTabSelection() {
    setState(() {
      _selectedTabIndex = _tabController!.index;
      if (_selectedTabIndex == 1) {
        // Second tab is selected, check camera permission
        // checkCameraPermission();
        // context.read<PermissionBloc>().askPermission();
        context.read<PermissionBloc>().add(RequestPermissionEvent());
      } else {
        // First tab was unselected, so we need to re-initialize the controller
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

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Text copied to clipboard")),
    );
  }

  Future<void> saveToGallery() async {
    try {
      final qrImageData =
          await _generateQrImageData(_generatedQRCode.toString());
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
      await Share.share(_generatedQRCode.toString());
    } catch (e) {
      print("Error sharing QR code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to share QR code")),
      );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QRCode Generated!'),
                            backgroundColor: Colors.green,
                          ),
                        );
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Generator'),
            Tab(text: 'Scanner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneratorTab(),
          _buildScannerTab(),

          // cameraView(),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        copyToClipboard(_generatedQRCode.toString());
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
                  fontSize: 26.0, fontStyle: FontStyle.italic, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () {
                state is PermissionDeniedState
                    ? context.read<PermissionBloc>().add(CheckPermissionEvent())
                    : state is PermissionPermanentlyDeniedState
                        ? openAppSettings()
                        : state is PermissionGrantedState;
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _foundCode(BarcodeCapture barcode) {
    ///open screen
    if (!_screenOpened) {
      final code = barcode.barcodes[0].rawValue ?? "No code available";

      _screenOpened = true;

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => FoundCodeScreen(
                    value: code,
                    screenClosed: _screenWasClosed,
                  )));
    }
  }

  void _screenWasClosed() {
    _screenOpened = false;
  }

  Widget scanCamera() {
    return Expanded(
      child: Column(
        children: [
          Flexible(
            // height: MediaQuery.of(context).size.height / 2,
            child: MobileScanner(
              controller: cameraController,
              fit: BoxFit.cover,
              onDetect: _foundCode,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: Colors.deepOrange,
              child: Column(
                children: [
                  Slider(
                    value: _zoomFactor,
                    onChanged: (value) {
                      setState(() {
                        _zoomFactor = value;
                        cameraController.setZoomScale(value);
                      });
                    },
                  ),
                  Row(
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
                        onPressed: () => cameraController.toggleTorch(),
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: isStarted
                            ? const Icon(Icons.stop)
                            : const Icon(Icons.play_arrow),
                        iconSize: 32.0,
                        onPressed: () => setState(() {
                          isStarted
                              ? cameraController.stop()
                              : cameraController.start();
                          isStarted = !isStarted;
                        }),
                      ),
                      Center(
                        child: SizedBox(
                          // width: MediaQuery.of(context).size.width - 200,
                          height: 40,
                          child: FittedBox(
                            child: Text(
                              'Scan',
                              overflow: TextOverflow.fade,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.image),
                        iconSize: 28.0,
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          // Pick an image
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            if (await cameraController
                                .analyzeImage(image.path)) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('QRCode found!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No QRCode found!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        color: Colors.white,
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
