import 'package:permission_handler/permission_handler.dart';
import 'package:remedi_permission/model/app_permission.dart';
import 'package:stacked_mvvm/stacked_mvvm.dart';

abstract class IPermissionListRepository extends IRepository {
  final List<AppPermission> permissions;

  IPermissionListRepository({required this.permissions})
      : assert(permissions.isNotEmpty);

  Future init();

  Future<Map<Permission, PermissionStatus>> requestAll();

  bool get hasError;

  Future<bool> get isAllGranted;
}
