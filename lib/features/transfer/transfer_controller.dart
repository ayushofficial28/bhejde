import 'dart:convert';
import 'dart:typed_data'; // Needed for Uint8List
import 'package:bhejde/core/file_service.dart';
import 'package:bhejde/features/discovery/nearby_controller.dart';
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
      for(String path in filePaths) {
        String fileName = path.split('/').last;
        fileManifest.add(fileName);
      }
      
      String jsonString = jsonEncode({"type": "MANIFEST", "files": fileManifest});
      
      // 2. Ask NearbyController to send the bytes
      await ref.read(nearbyControllerProvider.notifier)
               .sendBytes(endpointId, Uint8List.fromList(utf8.encode(jsonString)));

      // 3. Ask NearbyController to send the files
      for (String path in filePaths) {
        String fileName = path.split('/').last;
        state = state.copyWith(currentFileName: fileName);

        int payloadId = await ref.read(nearbyControllerProvider.notifier)
                                 .sendFile(endpointId, path);
        _activePayloads[payloadId] = fileName;
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

  void markFileCompleted(int payloadId) {
    if(state.role == TransferRole.receiver) {
      if (_activePayloads.containsKey(payloadId) && _payloadCachePaths.containsKey(payloadId)) {
        String fileName = _activePayloads[payloadId]!;
        String cachePath = _payloadCachePaths[payloadId]!;

        // Fire the save operation! (We don't need to await it, let it run in the background)
        FileService.moveFileToDownloads(cachePath, fileName);
      }
      _activePayloads.remove(payloadId);
      _payloadCachePaths.remove(payloadId);
    }
    
    int updatedCount = state.filesTransferred + 1;
    
    if (updatedCount > state.totalFiles) {
      state = state.copyWith(
        status: TransferStatus.completed,
        currentFileProgress: 1.0,
        filesTransferred: state.totalFiles,
      );
    } else {
      state = state.copyWith(
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
}

final transferControllerProvider = NotifierProvider<TransferController, TransferState>(() {
  return TransferController();
});