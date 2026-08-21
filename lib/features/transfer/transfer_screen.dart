import 'package:bhejde/features/transfer/completed_file.dart';
import 'package:bhejde/features/transfer/transfer_controller.dart';
import 'package:bhejde/features/transfer/transfer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhejde/features/discovery/nearby_controller.dart'; // 👉 Added to access stopAll()

class TransferScreen extends ConsumerWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferControllerProvider);
    final controller = ref.read(transferControllerProvider.notifier);

    // 👉 Intercept the hardware/gesture back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        await ref.read(nearbyControllerProvider.notifier).endConnection();
        
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            state.role == TransferRole.sender ? 'Sending Files' : 'Receiving Files',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          // 👉 Custom on-screen back button
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              await ref.read(nearbyControllerProvider.notifier).endConnection();
              
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ),
        body: Column(
          children: [
            // --- 1. PREMIUM PROGRESS CARD ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.status == TransferStatus.transferring
                              ? 'Transferring...'
                              : state.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${state.filesTransferred} / ${state.totalFiles}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Animated Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: state.status == TransferStatus.transferring ? state.currentFileProgress : 1.0,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Current File Name
                    Text(
                      state.currentFileName.isEmpty ? "Waiting..." : state.currentFileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- 2. COMPLETED FILES LIST ---
            Expanded(
              child: state.completedFiles.isEmpty
                  ? Center(
                      child: Text(
                        "No files completed yet",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: state.completedFiles.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final file = state.completedFiles[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: file is CompletedAppFile 
                                    ? Colors.green.withOpacity(0.1) 
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                file is CompletedAppFile ? Icons.android_rounded : Icons.insert_drive_file_rounded,
                                color: file is CompletedAppFile ? Colors.green : Colors.blue,
                              ),
                            ),
                            title: Text(
                              file.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              file.path.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            trailing: _buildTrailingWidget(file, state.role, controller, context),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TRAILING WIDGET LOGIC ---
  Widget _buildTrailingWidget(CompletedFile file, TransferRole role, TransferController controller, BuildContext context) {
    if (role == TransferRole.sender || file is! CompletedAppFile) {
      return const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28);
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
            SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, color: Colors.green),
          ],
        );

      case InstallState.failed:
      case InstallState.pending:
        return FilledButton.tonal(
          onPressed: () => controller.installApp(file.path),
          style: FilledButton.styleFrom(
            backgroundColor: file.installState == InstallState.failed 
                ? Colors.red.withOpacity(0.1) 
                : Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: file.installState == InstallState.failed 
                ? Colors.red 
                : Theme.of(context).colorScheme.primary,
            shape: const StadiumBorder(),
          ),
          child: Text(file.installState == InstallState.failed ? 'Retry' : 'Install'),
        );
    }
  }
}