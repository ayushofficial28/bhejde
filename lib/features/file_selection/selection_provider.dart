import 'package:flutter_riverpod/legacy.dart';

class SelectedFileNotifier extends StateNotifier<List<String>> {
  SelectedFileNotifier() : super([]);

  void toggleFileSelection(String filePath) {
    if (state.contains(filePath)) {
      state = state.where((path) => path != filePath).toList();
    } else {
      state = [...state, filePath];
    }
  }
  
}

StateNotifierProvider<SelectedFileNotifier, List<String>> selectedFilesProvider =
    StateNotifierProvider<SelectedFileNotifier, List<String>>((ref) {
  return SelectedFileNotifier();
});