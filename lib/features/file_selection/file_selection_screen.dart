import 'package:bhejde/features/file_selection/selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileSelectionScreen extends ConsumerWidget {
  const FileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFiles = ref.watch(selectedFilesProvider);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Files to Share'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Apps'),
              Tab(text: 'Photos'),
              Tab(text: 'Videos'),
              Tab(text: 'Documents'),
              Tab(text: 'Files'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            
          ],
        ),
        floatingActionButton: selectedFiles.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () {
                  print("Ready to send ${selectedFiles.length} files!");
                },
                icon: const Icon(Icons.send),
                label: Text("Send (${selectedFiles.length})"),
              )
            : null,
      ),
    );
  }
}
