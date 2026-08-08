import 'package:bhejde/features/transfer/transfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhejde/features/discovery/nearby_controller.dart';
import 'package:bhejde/features/discovery/nearby_state.dart';
import 'package:bhejde/features/file_selection/selection_provider.dart';
import 'package:bhejde/features/transfer/transfer_controller.dart';
// import 'package:bhejde/features/transfer/transfer_screen.dart';

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

    // Listen for a successful connection
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Receiver",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          
          if (_isPreparingFiles) ...[
            const Center(child: CircularProgressIndicator(color: Colors.purple)),
            const SizedBox(height: 10),
            const Center(child: Text("Preparing files for transfer...")),
          ] 
          
          else if (state.status == ConnectionStatus.discovering) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 10),
            const Center(child: Text("Scanning for nearby devices...")),
          ]
          else if (state.status == ConnectionStatus.connecting) ...[
            const Center(child: CircularProgressIndicator(color: Colors.orange)),
            const SizedBox(height: 10),
            Center(child: Text("Connecting to ${state.pendingEndpointName}...")),
          ],

          const SizedBox(height: 20),
          
          // The List of Available Devices
          if (!_isPreparingFiles)
            Expanded(
              child: ListView.builder(
                itemCount: state.discoveredPeers.length,
                itemBuilder: (context, index) {
                  String endpointId = state.discoveredPeers.keys.elementAt(index);
                  String deviceName = state.discoveredPeers.values.elementAt(index);
                  
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Tap to connect"),
                      trailing: const Icon(Icons.send, color: Colors.blue),
                      onTap: () {
                        controller.initiateConnection(endpointId);
                      },
                    ),
                  );
                },
              ),
            ),
          
          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                controller.stopAll();
                Navigator.pop(context);
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}