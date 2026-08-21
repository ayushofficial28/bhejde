import 'package:bhejde/features/transfer/transfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhejde/features/discovery/nearby_controller.dart';
import 'package:bhejde/features/discovery/nearby_state.dart';
import 'package:bhejde/features/file_selection/selection_provider.dart';
import 'package:bhejde/features/transfer/transfer_controller.dart';

class DiscoveryModal extends ConsumerStatefulWidget {
  const DiscoveryModal({super.key});

  @override
  ConsumerState<DiscoveryModal> createState() => _DiscoveryModalState();
}

class _DiscoveryModalState extends ConsumerState<DiscoveryModal> {
  bool _isPreparingFiles = true;
  List<String> _pathsToSend = [];

  @override
  void initState() {
    super.initState();
    _prepareFilesAndStartDiscovery();
  }

  Future<void> _prepareFilesAndStartDiscovery() async {
    ref.read(nearbyControllerProvider.notifier).startDiscovery();
    _pathsToSend = await ref.read(selectedFilesProvider.notifier).getFinalPathsForTransfer();
    
    if (mounted) {
      setState(() {
        _isPreparingFiles = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyControllerProvider);
    final controller = ref.read(nearbyControllerProvider.notifier);

    // Listen for a successful connection (Logic preserved exactly)
    ref.listen<NearbyState>(nearbyControllerProvider, (previous, next) {
      if (previous?.status != ConnectionStatus.connected && 
          next.status == ConnectionStatus.connected) {
            
        ref.read(transferControllerProvider.notifier).sendFiles(
          next.connectedEndpointId!, 
          _pathsToSend, // Use the extracted paths
        );

        controller.stopAll(); 

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TransferScreen()),
        );
      }
    });

    // --- UI ENHANCEMENTS START HERE ---
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        await ref.read(nearbyControllerProvider.notifier).stopAll();

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            const Text(
              "Select Receiver",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            
            // Dynamic Status Card
            if (_isPreparingFiles) ...[
              _buildStatusCard(context, "Preparing files...", Icons.folder_zip_rounded, Colors.purple),
            ] else if (state.status == ConnectionStatus.discovering) ...[
              _buildStatusCard(context, "Scanning for nearby devices...", Icons.radar_rounded, Theme.of(context).colorScheme.primary),
            ] else if (state.status == ConnectionStatus.connecting) ...[
              _buildStatusCard(context, "Connecting to ${state.pendingEndpointName}...", Icons.link_rounded, Colors.orange),
            ],
      
            const SizedBox(height: 16),
            
            // The List of Available Devices
            if (!_isPreparingFiles)
              Expanded(
                child: state.discoveredPeers.isEmpty
                    ? Center(
                        child: Text(
                          "Make sure the receiver is visible",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.discoveredPeers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          String endpointId = state.discoveredPeers.keys.elementAt(index);
                          String deviceName = state.discoveredPeers.values.elementAt(index);
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.phone_android_rounded, 
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                deviceName, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                "Tap to connect",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                              onTap: () {
                                controller.initiateConnection(endpointId);
                              },
                            ),
                          );
                        },
                      ),
              ),
            
            const SizedBox(height: 16),
      
            // Cancel Button
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    controller.stopAll();
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- UI HELPER METHOD ---
  Widget _buildStatusCard(BuildContext context, String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withOpacity(0.8), // Adjusted for better text contrast
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Icon(icon, color: color.withOpacity(0.5)),
        ],
      ),
    );
  }
}