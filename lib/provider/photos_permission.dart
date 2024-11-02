import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotosPermission extends ChangeNotifier {
  bool _photoPermissionGranted = false;
  // bool _storagePermissionPermanentlyDenied = false;

  bool get isPermissionGranted => _photoPermissionGranted;
  // bool get storagePermissionPermanentlyDenied =>
  // _storagePermissionPermanentlyDenied;

  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();

    if (status.isGranted) {
      _photoPermissionGranted = true;
      // _storagePermissionPermanentlyDenied = false;
      // } else if (status.isPermanentlyDenied) {
      //   _storagePermissionGranted = false;
      //   _storagePermissionPermanentlyDenied = true;
      //   openAppSettings();
    } else {
      _photoPermissionGranted = false;
      // _storagePermissionPermanentlyDenied = false;
    }

    notifyListeners();
    return _photoPermissionGranted;
  }

  Future<void> checkPhotoPermission() async {
    final status = await Permission.photos.status;

    _photoPermissionGranted = status.isGranted;
    // _storagePermissionPermanentlyDenied = status.isPermanentlyDenied;

    notifyListeners();
  }
}
