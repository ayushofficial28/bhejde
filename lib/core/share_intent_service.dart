import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/file_selection/selection_provider.dart';

class ShareIntentService {
  static Future<List<SharedMediaFile>> getInitialFiles() async {
    return await ReceiveSharingIntent.instance.getInitialMedia();
  }

  static void reset() {
    ReceiveSharingIntent.instance.reset();
  }

  static void addToSelection(
    WidgetRef ref,
    List<SharedMediaFile> files,
  ) {
    final notifier = ref.read(selectedFilesProvider.notifier);

    for (final file in files) {
      notifier.toggleFileSelection(
        SelectedItem(
          id: file.path,
          path: file.path,
          appName: null,
        ),
      );
    }
  }
}