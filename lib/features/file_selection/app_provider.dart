import 'dart:io';

import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appProvider= FutureProvider<List<dynamic>>((ref) async {
  final apps = await FlutterDeviceApps.listApps(includeIcons:true );
  
  final validApps = apps.where((app) {
    // Drop the app if the OS didn't provide a path (e.g., Instant Apps)
    if (app.apkPath == null) return false;
    
    // Check the physical hard drive to ensure the file is actually there
    final file = File(app.apkPath!);
    return file.existsSync();
  }).toList();

  validApps.sort((a, b) => (a.appName ?? '').compareTo(b.appName ?? ''));

  return validApps;
});