import 'package:flutter_riverpod/legacy.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:apks_manager/apks_manager.dart';

class SelectedFileNotifier extends StateNotifier<List<SelectedItem>> {
  SelectedFileNotifier() : super([]);

  void toggleFileSelection(SelectedItem item) {
    // 1. Check if an item with this exact ID is already in the cart
    final isAlreadySelected = state.any((existingItem) => existingItem.id == item.id);

    if (isAlreadySelected) {
      // 2. If it exists, remove it by keeping everything that DOES NOT match the ID
      state = state.where((existingItem) => existingItem.id != item.id).toList();
    } else {
      // 3. If it doesn't exist, add it to the end of the list
      state = [...state, item];
    }
  }

  // Call this only when the user clicks the final "Send" button!
  Future<List<String>> getFinalPathsForTransfer() async {
    List<String> finalPaths = [];
    
    for (var item in state) {
      if (item.path != null) {
        if(item.path!.endsWith('.apk') && item.appName!=null){
          final app=await ApksManager.createBundle(baseApkPath: item.path!, appName: item.appName!, extension: 'bhejde');
          if(app!=null){
            finalPaths.add(app);
          }
        }
        else{
          finalPaths.add(item.path!);
        }
      } else if (item.asset != null) {
        // It's a Photo. We wait for the OS to give us the real hard drive path.
        final rawFile = await item.asset!.file;
        if (rawFile != null) {
          finalPaths.add(rawFile.path);
        }
      }
    }
    
    return finalPaths;
  }
}

final selectedFilesProvider = StateNotifierProvider<SelectedFileNotifier, List<SelectedItem>>((ref) {
  return SelectedFileNotifier();
});


class SelectedItem {
  final String id;           // The unique identifier (app package name, file path, or asset ID)
  final String? path;        // The physical hard drive path (if instantly available)
  final AssetEntity? asset;  // The photo database object (if it's a photo)
  final String? appName;

  SelectedItem({
    required this.id,
    this.path,
    this.asset,
    this.appName
  });
}