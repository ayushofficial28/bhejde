import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false; 
    
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final int sdkInt = androidInfo.version.sdkInt;

    Map<Permission, PermissionStatus> statuses;

    if (sdkInt >= 33) {
      // Android 13+ (API 33+) 
      // Requires Nearby Wi-Fi Devices explicitly
      statuses = await [
        Permission.location,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.nearbyWifiDevices,
      ].request();
    } else if (sdkInt >= 31) {
      // Android 12 (API 31-32)
      // Relies on granular Bluetooth permissions
      statuses = await [
        Permission.location,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();
    } else {
      // Android 11 and below (API 30 and below)
      // Relies on legacy Location and Bluetooth
      statuses = await [
        Permission.location,
        Permission.bluetooth,
      ].request();
    }
    
    // Check if any of the core networking permissions were denied
    bool corePermissionsGranted = statuses.values.every((status) => status.isGranted);
    if (!corePermissionsGranted) return false;
    print('Requesting permissions for Android...');
    // Handle Storage
    if (sdkInt >= 30) {
      var storageStatus = await Permission.manageExternalStorage.status;
      if (!storageStatus.isGranted) {
        await Permission.manageExternalStorage.request(); 
      }
    } else {
      await [
        Permission.storage,
        Permission.requestInstallPackages,
      ].request();
    }

    return true; 
  }
}