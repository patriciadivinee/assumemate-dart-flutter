import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class StoragePermission extends ChangeNotifier {
  bool _storagePermissionGranted = false;
  // bool _storagePermissionPermanentlyDenied = false;

  bool get isStoragePermissionGranted => _storagePermissionGranted;
  // bool get storagePermissionPermanentlyDenied =>
  // _storagePermissionPermanentlyDenied;

  Future<bool> requestStoragePermission() async {
    final plugin = DeviceInfoPlugin();
    final android = await plugin.androidInfo;

    PermissionStatus status = PermissionStatus.denied;

    if (android.version.sdkInt < 33) {
      status = await Permission.storage.request();
    }
    status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      _storagePermissionGranted = true;
      // _storagePermissionPermanentlyDenied = false;
      // } else if (status.isPermanentlyDenied) {
      //   _storagePermissionGranted = false;
      //   _storagePermissionPermanentlyDenied = true;
      //   openAppSettings();
    } else {
      _storagePermissionGranted = false;
      // _storagePermissionPermanentlyDenied = false;
    }

    notifyListeners();
    return _storagePermissionGranted;
  }

  Future<void> checkStoragePermission() async {
    final status = await Permission.storage.status;

    _storagePermissionGranted = status.isGranted;
    // _storagePermissionPermanentlyDenied = status.isPermanentlyDenied;

    notifyListeners();
  }
}
