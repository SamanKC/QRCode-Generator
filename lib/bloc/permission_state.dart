abstract class PermissionState {}

class CheckingPermissionState extends PermissionState {}

class PermissionGrantedState extends PermissionState {}

class PermissionDeniedState extends PermissionState {
   final String deniedMessage;

  PermissionDeniedState({required this.deniedMessage});
}

class PermissionPermanentlyDeniedState extends PermissionState {
   final String permanentlyDeniedMessage;

  PermissionPermanentlyDeniedState({required this.permanentlyDeniedMessage});
}

class PermissionErrorsState extends PermissionState {
  final String errorMessage;

  PermissionErrorsState({required this.errorMessage});
}
