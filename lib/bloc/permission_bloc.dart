import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrcodegenerator/bloc/permission_event.dart';
import 'package:qrcodegenerator/bloc/permission_state.dart';
import 'package:qrcodegenerator/helpers/camera_permission_helper.dart';

class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  PermissionBloc() : super(CheckingPermissionState()) {
    on<RequestPermissionEvent>(_handleRequestPermission);
    on<CheckPermissionEvent>(_handleCheckPermission);
  }

  askPermission() async {
    await CameraPermissionHelper.requestCameraPermission();
  }

  void _handleRequestPermission(
      RequestPermissionEvent event, Emitter<PermissionState> emit) async {
    try {
      PermissionStatus status =
          await CameraPermissionHelper.requestCameraPermission();
      log(status.toString());
      if (status.isGranted) {
        emit(PermissionGrantedState());
      } else if (status.isDenied) {
        emit(PermissionDeniedState(
            deniedMessage:
                "Grant camera permission to capture QRCodes. Tap 'Allow' to enable camera functionality!"));
        await askPermission();
      } else if (status.isPermanentlyDenied) {
        emit(PermissionPermanentlyDeniedState(
            permanentlyDeniedMessage:
                "Grant camera permission to capture QRCodes. Tap 'Allow' to enable camera functionality!"));
      }
    } catch (e) {
      log(e.toString());
      emit(PermissionErrorsState(errorMessage: "Something went wrong!"));
    }
  }

  void _handleCheckPermission(
      CheckPermissionEvent event, Emitter<PermissionState> emit) async {
    try {
      final status = await CameraPermissionHelper.checkCameraPermission();

      if (status.isGranted) {
        emit(PermissionGrantedState());
      } else if (status.isDenied) {
        emit(PermissionDeniedState(
            deniedMessage:
                "Grant camera permission to capture QRCodes. Tap 'Allow' to enable camera functionality!"));
        await askPermission();
      } else if (status.isPermanentlyDenied) {
        emit(PermissionPermanentlyDeniedState(
            permanentlyDeniedMessage:
                "Grant camera permission to capture QRCodes. Tap 'Allow' to enable camera functionality!"));
      }
    } catch (e) {
      log(e.toString());
      emit(PermissionErrorsState(errorMessage: "Something went wrong!"));
    }
  }
}
