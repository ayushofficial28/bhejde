import 'package:bhejde/features/transfer/completed_file.dart';
import 'package:bhejde/features/transfer/transfer_controller.dart';
import 'package:bhejde/features/transfer/transfer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class TransferScreen extends ConsumerWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferControllerProvider);
    final controller = ref.read(transferControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.role == TransferRole.sender ? 'Sending...' : 'Receiving...'),
      ),
      body: Column(
        children: [
          // --- 1. PROGRESS HEADER ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  state.status == TransferStatus.transferring 
                      ? 'Files: ${state.filesTransferred} / ${state.totalFiles}'
                      : state.status.name.toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (state.status == TransferStatus.transferring)
                  LinearProgressIndicator(value: state.currentFileProgress),
                const SizedBox(height: 8),
                Text(state.currentFileName),
              ],
            ),
          ),
          
          const Divider(thickness: 2),

          // --- 2. COMPLETED FILES LIST ---
          Expanded(
            child: ListView.builder(
              itemCount: state.completedFiles.length,
              itemBuilder: (context, index) {
                final file = state.completedFiles[index];
                
                return ListTile(
                  leading: Icon(
                    file is CompletedAppFile ? Icons.android : Icons.insert_drive_file,
                    color: file is CompletedAppFile ? Colors.green : Colors.blue,
                  ),
                  title: Text(file.name),
                  subtitle: Text(
                    file.path.split('/').last, 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _buildTrailingWidget(file, state.role, controller),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- TRAILING WIDGET LOGIC ---
  Widget _buildTrailingWidget(CompletedFile file, TransferRole role, TransferController controller) {
    // 1. Senders and Normal Files just get a checkmark
    if (role == TransferRole.sender || file is! CompletedAppFile) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    switch (file.installState) {
      case InstallState.installing:
        return const SizedBox(
          width: 24, 
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
        
      case InstallState.installed:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Installed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            SizedBox(width: 6),
            Icon(Icons.check_circle, color: Colors.green),
          ],
        );
        
      case InstallState.failed:
      case InstallState.pending:
        return ElevatedButton(
          onPressed: () => controller.installApp(file.path),
          style: ElevatedButton.styleFrom(
            backgroundColor: file.installState == InstallState.failed ? Colors.orange : Colors.blue,
          ),
          child: Text(file.installState == InstallState.failed ? 'Retry' : 'Install'),
        );
    }
  }
}