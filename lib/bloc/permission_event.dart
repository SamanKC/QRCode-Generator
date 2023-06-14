// Define the events
abstract class PermissionEvent {}

class RequestPermissionEvent extends PermissionEvent {}

class CheckPermissionEvent extends PermissionEvent {}
