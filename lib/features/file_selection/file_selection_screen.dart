import 'package:bhejde/core/permission_service.dart';
import 'package:bhejde/features/discovery/discovery_modal.dart';
import 'package:bhejde/features/discovery/nearby_controller.dart';
//import 'package:bhejde/features/file_selection/apps_tab.dart';
import 'package:bhejde/features/file_selection/document_tab.dart';
import 'package:bhejde/features/file_selection/files_tab.dart';
import 'package:bhejde/features/file_selection/photo_tab.dart';
import 'package:bhejde/features/file_selection/selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhejde/features/file_selection/video_tab.dart';

class FileSelectionScreen extends ConsumerWidget {
  const FileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFiles = ref.watch(selectedFilesProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Files to Share'),
          bottom: const TabBar(
            tabAlignment: TabAlignment.center,
            isScrollable: true,
            tabs: [
              //Tab(text: 'Apps'),
              Tab(text: 'Photos'),
              Tab(text: 'Videos'),
              Tab(text: 'Documents'),
              Tab(text: 'Files'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            //AppsTab(),
            PhotosTab(), // Placeholder for Photos
            VideosTab(), // Placeholder for Videos
            DocumentsTab(), // Placeholder for Documents
            FilesTab(), // Placeholder for Files
          ],
        ),
        floatingActionButton: selectedFiles.isNotEmpty
    ? FloatingActionButton.extended(
        onPressed: () async {
          // 1. Check App Permissions first
          bool granted = await PermissionService.requestPermissions();
          if (!granted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permissions required to send!')),
              );
            }
            return; // Stop execution
          }

          // 2. Check Physical GPS Hardware 
          // (Assuming you have access to your controller here like in the Receive button)
          bool hardwareReady = await ref.read(nearbyControllerProvider.notifier).checkHardwareRadios();
          if (!hardwareReady) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wi-Fi, Bluetooth and Location must be turned on to connect!')),
              );
            }
            return; // Stop execution
          }

          // 3. All clear! Open the Discovery Modal
          if (context.mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              builder: (context) => const DiscoveryModal(),
            );
          }
        },
        icon: const Icon(Icons.send),
        label: Text("Send (${selectedFiles.length})"),
      )
    : null,
      ),
    );
  }
}
