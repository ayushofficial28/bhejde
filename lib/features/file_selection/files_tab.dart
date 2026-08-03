import 'dart:io';
import 'package:bhejde/features/file_selection/file_manager_provider.dart';
import 'package:bhejde/features/file_selection/selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';


class FilesTab extends ConsumerStatefulWidget {
  const FilesTab({super.key});

  @override
  ConsumerState<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends ConsumerState<FilesTab> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Request All Files Access (Android 11+)
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      
      // 2. Request standard storage (Fallback for Android 10 and below)
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      // 3. Initialize the provider to scan for SD cards and internal storage
      ref.read(fileManagerProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmState = ref.watch(fileManagerProvider);
    final selectedFilesList = ref.watch(selectedFilesProvider);

    return PopScope(
      canPop: fmState.currentDirectory == null,
      onPopInvoked: (didPop) {
        if (!didPop) {
          ref.read(fileManagerProvider.notifier).goBack();
        }
      },
      child: fmState.isLoading && fmState.entities.isEmpty && fmState.storageRoots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(fmState, selectedFilesList),
    );
  }

  Widget _buildContent(FileManagerState fmState, List<dynamic> selectedFilesList) {
    // 1. Show the Storage Drives (Internal + SD Card)
    if (fmState.currentDirectory == null) {
      
      // EMPTY STATE: If no drives are found, show this instead of a blank screen
      if (fmState.storageRoots.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No storage drives found.\nPlease ensure "All Files Access" is granted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await Permission.manageExternalStorage.request();
                  ref.read(fileManagerProvider.notifier).init();
                },
                child: const Text('Grant Permission'),
              )
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: fmState.storageRoots.length,
        itemBuilder: (context, index) {
          final root = fmState.storageRoots[index];
          final isInternal = root.path.contains('emulated');
          
          return ListTile(
            leading: Icon(
              isInternal ? Icons.smartphone : Icons.sd_storage,
              color: isInternal ? Colors.blue : Colors.teal,
              size: 32,
            ),
            title: Text(isInternal ? 'Internal Storage' : 'SD Card'),
            subtitle: Text(root.path),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(fileManagerProvider.notifier).openDirectory(root),
          );
        },
      );
    }

    // 2. Show Files and Folders inside a selected drive
    return Column(
      children: [
        // Breadcrumb Header
        Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.centerLeft,
          color: Colors.grey.shade200,
          child: Text(
            fmState.currentDirectory!.path.replaceAll('/storage/emulated/0', 'Internal Storage'),
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Progress indicator for large folders loading asynchronously
        if (fmState.isLoading) const LinearProgressIndicator(),

        // File List
        Expanded(
          child: fmState.entities.isEmpty && !fmState.isLoading
              ? const Center(child: Text('Folder is empty'))
              : ListView.builder(
                  itemCount: fmState.entities.length,
                  itemBuilder: (context, index) {
                    final entity = fmState.entities[index];
                    final isFolder = entity is Directory;
                    final name = entity.path.split('/').last;

                    final isSelected = selectedFilesList.any((item) => item.id == entity.path);

                    return ListTile(
                      leading: Icon(
                        isFolder ? Icons.folder : Icons.insert_drive_file,
                        color: isFolder ? Colors.orange : Colors.blue,
                        size: 32,
                      ),
                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: isFolder 
                          ? const Icon(Icons.chevron_right, color: Colors.grey)
                          : (isSelected
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : const Icon(Icons.radio_button_unchecked, color: Colors.grey)),
                      onTap: () {
                        if (isFolder) {
                          ref.read(fileManagerProvider.notifier).openDirectory(entity);
                        } else {
                          final item = SelectedItem(id: entity.path, path: entity.path);
                          ref.read(selectedFilesProvider.notifier).toggleFileSelection(item);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}