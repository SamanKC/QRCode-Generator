import 'package:permission_handler/permission_handler.dart';

class CameraPermissionHelper {
  static Future<PermissionStatus> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status;
  }

  static Future<PermissionStatus> checkCameraPermission() async {
    final permissionStatus = await Permission.camera.status;
    return permissionStatus;
  }
}
