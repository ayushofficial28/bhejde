import 'package:flutter_device_name/flutter_device_name.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final deviceNameProvider = StateNotifierProvider<DeviceNameNotifier, String>((ref) {
  return DeviceNameNotifier();
});

class DeviceNameNotifier extends StateNotifier<String> {
  DeviceNameNotifier() : super("BhejDe Device") {
    _initName();
  }

  Future<void> _initName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('custom_device_name');
    
    if (savedName != null && savedName.isNotEmpty) {
      state = savedName;
    } else {
      await refreshHardwareName();
    }
  }

  // Called manually after permissions are granted
  Future<void> refreshHardwareName() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('custom_device_name')) return;

    try {
      final plugin = DeviceName();
      final nativeName = await plugin.getName(); 
      
      if (nativeName != null && nativeName.isNotEmpty) {
        state = nativeName; 
        await prefs.setString('custom_device_name', state); 
      }
    } catch (e) {
      // Fails silently if permissions aren't granted yet
    }
  }

  Future<void> updateName(String newName) async {
    if (newName.trim().isEmpty) return;
    
    state = newName.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_device_name', state);
  }
}