import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transfer_state.dart';
import 'transfer_controller.dart';

class TransferScreen extends ConsumerWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Listen to the transfer state
    final state = ref.watch(transferControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.role == TransferRole.sender ? 'Sending Files' : 'Receiving Files'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: _buildTransferContent(state),
          ),
        ),
      ),
    );
  }

  // 2. A helper method to show the right UI based on the exact status
  Widget _buildTransferContent(TransferState state) {
    switch (state.status) {
      case TransferStatus.preparing:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Preparing ${state.totalFiles} files...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        );

      case TransferStatus.transferring:
        // Calculate the current file number (e.g., File 2 of 5)
        int currentFileNumber = state.filesTransferred + 1;
        // Prevent it from showing "File 6 of 5" for a split second at the end
        if (currentFileNumber > state.totalFiles) currentFileNumber = state.totalFiles;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_copy_outlined, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'File $currentFileNumber of ${state.totalFiles}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.currentFileName ?? 'Transferring...',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // The Progress Bar
            LinearProgressIndicator(
              value: state.currentFileProgress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            
            // The Percentage Text
            Text(
              '${(state.currentFileProgress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        );

      case TransferStatus.completed:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Successfully transferred ${state.filesTransferred} files!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case TransferStatus.error:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Transfer Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
            ),
          ],
        );

      default:
        return const Text('Waiting for transfer to begin...');
    }
  }
}