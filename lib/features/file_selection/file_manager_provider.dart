import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class FileManagerState {
  final Directory? currentDirectory;
  final List<Directory> storageRoots;
  final List<FileSystemEntity> entities;
  final bool isLoading;

  FileManagerState({
    this.currentDirectory,
    this.storageRoots = const [],
    this.entities = const [],
    this.isLoading = false,
  });

  FileManagerState copyWith({
    Directory? currentDirectory,
    List<Directory>? storageRoots,
    List<FileSystemEntity>? entities,
    bool? isLoading,
    bool clearCurrentDir = false,
  }) {
    return FileManagerState(
      currentDirectory: clearCurrentDir ? null : (currentDirectory ?? this.currentDirectory),
      storageRoots: storageRoots ?? this.storageRoots,
      entities: entities ?? this.entities,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FileManagerNotifier extends Notifier<FileManagerState> {
  @override
  FileManagerState build() {
    return FileManagerState(isLoading: true);
  }

  Future<void> init() async {
    List<Directory> roots = [];

    try {
      // 1. Ask the native Android OS for all mounted storage volumes
      final directories = await getExternalStorageDirectories();
      
      if (directories != null) {
        for (var dir in directories) {
          // dir.path will look like: /storage/emulated/0/Android/data/...
          // or for SD cards: /storage/1A2B-3C4D/Android/data/...
          
          // 2. Chop off the app-specific part to get the absolute root of the drive
          final rootPath = dir.path.split('/Android/')[0];
          
          // 3. Prevent duplicate roots just in case
          if (!roots.any((r) => r.path == rootPath)) {
            roots.add(Directory(rootPath));
          }
        }
      }
    } catch (e) {
      print('Native storage query failed: $e');
    }

    // Fallback just in case the OS returns nothing
    if (roots.isEmpty) {
      roots.add(Directory('/storage/emulated/0'));
    }

    state = state.copyWith(
      storageRoots: roots,
      clearCurrentDir: true,
      isLoading: false,
    );
  }

  Future<void> openDirectory(Directory dir) async {
    state = state.copyWith(isLoading: true, currentDirectory: dir);

    try {
      // Use asynchronous list() instead of listSync() to prevent UI freezing
      final List<FileSystemEntity> allEntities = await dir.list().toList();

      // Filter out hidden files and restricted Android folders
      final filteredContents = allEntities.where((entity) {
        final name = entity.path.split('/').last;
        
        // Hide hidden files/folders
        if (name.startsWith('.')) return false; 
        
        // Block restricted Android 11+ folders
        if (entity is Directory) {
          if (entity.path.endsWith('Android/data') || entity.path.endsWith('Android/obb')) {
            return false;
          }
        }
        return true;
      }).toList();

      // Sort: Folders first, then Files, alphabetically
      filteredContents.sort((a, b) {
        final aIsFolder = a is Directory;
        final bIsFolder = b is Directory;
        if (aIsFolder && !bIsFolder) return -1;
        if (!aIsFolder && bIsFolder) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      state = state.copyWith(entities: filteredContents, isLoading: false);
    } catch (e) {
      state = state.copyWith(entities: [], isLoading: false);
    }
  }

  bool goBack() {
    if (state.currentDirectory == null) return false; 

    // If at the root of a drive, go back to drive selection
    if (state.storageRoots.any((root) => root.path == state.currentDirectory!.path)) {
      state = state.copyWith(clearCurrentDir: true, entities: []);
      return true;
    }

    // Go up one folder
    openDirectory(state.currentDirectory!.parent);
    return true;
  }
}

final fileManagerProvider = NotifierProvider<FileManagerNotifier, FileManagerState>(
  FileManagerNotifier.new,
);