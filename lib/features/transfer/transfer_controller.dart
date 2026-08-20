import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Needed for Uint8List
import 'package:apks_manager/apks_manager.dart';
import 'package:bhejde/core/file_service.dart';
import 'package:bhejde/features/discovery/nearby_controller.dart';
import 'package:bhejde/features/transfer/completed_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transfer_state.dart';

class TransferController extends Notifier<TransferState> {
  final Map<int, String> _activePayloads = {};
  final List<String> _incomingFileQueue = [];
  final Map<int, String> _payloadCachePaths = {};

  @override
  TransferState build() {
    return TransferState();
  }

  // ==========================================
  // SENDER LOGIC
  // ==========================================
  Future<void> sendFiles(String endpointId, List<String> filePaths) async {
    state = state.copyWith(
      role: TransferRole.sender,
      status: TransferStatus.preparing,
      totalFiles: filePaths.length,
      filesTransferred: 0,
    );

    try {
      // 1. Prepare JSON Manifest
      List<String> fileManifest = [];
      for (String path in filePaths) {
        String fileName = path.split('/').last;
        fileManifest.add(fileName);
      }

      String jsonString = jsonEncode({
        "type": "MANIFEST",
        "files": fileManifest,
      });

      // 2. Ask NearbyController to send the bytes
      await ref
          .read(nearbyControllerProvider.notifier)
          .sendBytes(endpointId, Uint8List.fromList(utf8.encode(jsonString)));

      // 3. Ask NearbyController to send the files
      for (String path in filePaths) {
        String fileName = path.split('/').last;
        state = state.copyWith(currentFileName: fileName);

        int payloadId = await ref
            .read(nearbyControllerProvider.notifier)
            .sendFile(endpointId, path);
        _activePayloads[payloadId] = fileName;

        _payloadCachePaths[payloadId] = path;
      }
    } catch (e) {
      markTransferError(e.toString());
    }
  }

  // ==========================================
  // RECEIVER LOGIC
  // ==========================================
  void handleManifestBytes(Uint8List bytes) {
    try {
      String jsonString = utf8.decode(bytes);
      Map<String, dynamic> data = jsonDecode(jsonString);

      if (data['type'] == 'MANIFEST') {
        List<dynamic> files = data['files'];

        _incomingFileQueue.clear();
        for (var fileData in files) {
          _incomingFileQueue.add(fileData.toString());
        }

        state = state.copyWith(
          role: TransferRole.receiver,
          status: TransferStatus.preparing,
          totalFiles: _incomingFileQueue.length,
          filesTransferred: 0,
        );
      }
    } catch (e) {
      print("Failed to parse JSON: $e");
    }
  }

  void handleIncomingFile(int payloadId, String cachedPath) {
    String expectedFileName = 'Unknown_File';
    if (_incomingFileQueue.isNotEmpty) {
      expectedFileName = _incomingFileQueue.removeAt(0);
    }

    _activePayloads[payloadId] = expectedFileName;
    _payloadCachePaths[payloadId] = cachedPath;
    state = state.copyWith(
      status: TransferStatus.transferring,
      currentFileName: expectedFileName,
    );
  }

  // ==========================================
  // PROGRESS LOGIC
  // ==========================================
  void updateProgress(int transferred, int total) {
    double progress = transferred / total;
    state = state.copyWith(
      status: TransferStatus.transferring,
      currentFileProgress: progress,
    );
  }

  void markFileCompleted(int payloadId) async {
    // Safety check: ensure payload exists
    if (!_activePayloads.containsKey(payloadId) || !_payloadCachePaths.containsKey(payloadId)) {
      return;
    }

    String fileName = _activePayloads[payloadId]!;
    String cachePath = _payloadCachePaths[payloadId]!;
    String finalDisplayPath = cachePath;

    // --- 1. HANDLE FILE OPERATIONS ---
    if (state.role == TransferRole.receiver) {
      // Receiver moves file from cache to Downloads
      finalDisplayPath = await FileService.moveFileToDownloads(
        cachePath,
        fileName,
      );
    } else if (state.role == TransferRole.sender) {
      // Sender cleans up temporary bundle files
      if (fileName.endsWith('.bhejde')) {
        final tempFile = File(cachePath);
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    }

    // --- 2. CREATE COMPLETED FILE OBJECT (For BOTH Sender & Receiver) ---
    final isAppFile = fileName.endsWith('.bhejde') ||
        fileName.endsWith('.apk') ||
        fileName.endsWith('.apks') ||
        fileName.endsWith('.xapk');

    CompletedFile newFile = isAppFile
        ? CompletedAppFile(name: fileName, path: finalDisplayPath)
        : CompletedFile(name: fileName, path: finalDisplayPath);

    // --- 3. CLEANUP TRACKING MAPS ---
    _activePayloads.remove(payloadId);
    _payloadCachePaths.remove(payloadId);

    // --- 4. UPDATE STATE & PROGRESS ---
    int updatedCount = state.filesTransferred + 1;

    if (updatedCount >= state.totalFiles) { 
      state = state.copyWith(
        completedFiles: List.from(state.completedFiles)..add(newFile), 
        status: TransferStatus.completed,
        currentFileProgress: 1.0,
        filesTransferred: updatedCount,
      );
    } else {
      state = state.copyWith(
        completedFiles: List.from(state.completedFiles)..add(newFile), 
        filesTransferred: updatedCount,
        currentFileProgress: 0.0,
      );
    }
  }

  void markTransferError(String errorMessage) {
    state = state.copyWith(
      status: TransferStatus.error,
      errorMessage: errorMessage,
    );
  }

  Future<void> installApp(String filePath) async {
    _updateFileInstallState(filePath, InstallState.installing);

    bool success = await ApksManager.installBundle(filePath);

    _updateFileInstallState(
      filePath,
      success ? InstallState.installed : InstallState.failed,
    );
  }

  void _updateFileInstallState(String targetPath, InstallState newState) {
    final updatedList = state.completedFiles.map((file) {
      if (file is CompletedAppFile && file.path == targetPath) {
        return file.copyWith(installState: newState);
      }
      return file;
    }).toList();

    state = state.copyWith(completedFiles: updatedList);
  }
}

final transferControllerProvider =
    NotifierProvider<TransferController, TransferState>(() {
      return TransferController();
    });
