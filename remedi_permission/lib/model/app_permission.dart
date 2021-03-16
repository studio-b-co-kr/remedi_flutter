import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermission {
  final Widget icon;
  final String title;
  final String description;
  final bool mandatory;
  final PermissionPlatform platform;
  final Permission permission;
  final String errorDescription;

  AppPermission(
    this.permission, {
    this.icon,
    this.title,
    this.description,
    this.errorDescription,
    this.platform = PermissionPlatform.both,
    this.mandatory = false,
  })  : assert(permission != null),
        assert(!mandatory ||
            (mandatory &&
                (errorDescription != null && errorDescription.isNotEmpty)));
}

extension PermissionEx on AppPermission {
  Future<bool> get isError async => mandatory && !await permission.isGranted;

  Future<bool> get isGranted async => await permission.isGranted;

  Future<PermissionStatus> get status async => await permission.status;
}

enum PermissionPlatform {
  ios,
  android,
  both,
}
