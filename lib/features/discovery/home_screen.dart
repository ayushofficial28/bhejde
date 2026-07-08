import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the files we just created
import '../../core/permission_service.dart';
import 'nearby_controller.dart';
import 'nearby_state.dart';

// Notice this is a ConsumerWidget, not a StatelessWidget!
// This is what allows the screen to plug into Riverpod.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. THE EYES: We watch the blueprint. Anytime it changes, this screen rebuilds.
    final state = ref.watch(nearbyControllerProvider);
    
    // 2. THE HANDS: We grab the controller so we can press the buttons (start/stop).
    final controller = ref.read(nearbyControllerProvider.notifier);

    ref.listen<NearbyState>(nearbyControllerProvider, (previous, next) {
      if (previous?.status != ConnectionStatus.connected && 
          next.status == ConnectionStatus.connected) {
            
        // Trigger the screen transition!
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TransferScreen(),
          ),
        );
    }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('BhejDe', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              
              if (state.status == ConnectionStatus.idle) ...[
                const Icon(Icons.share, size: 100, color: Colors.blue),
                const SizedBox(height: 20),
                const Text("Ready to share offline", style: TextStyle(fontSize: 18)),
              ] 
              
              else if (state.status == ConnectionStatus.discovering) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text("Scanning for nearby devices...", style: TextStyle(fontSize: 18)),
                
                // Show the devices we found
                if (state.discoveredPeers.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.discoveredPeers.length,
                      itemBuilder: (context, index) {
                        String endpointId = state.discoveredPeers.keys.elementAt(index);
                        String deviceName = state.discoveredPeers.values.elementAt(index);
                        
                        return ListTile(
                          leading: const Icon(Icons.phone_android),
                          title: Text(deviceName),
                          subtitle: const Text("Tap to connect"),
                          onTap: () {
                            
                           controller.initiateConnection(endpointId);
                          },
                        );
                      },
                    ),
                  )
              ]

              else if (state.status == ConnectionStatus.advertising) ...[
                const CircularProgressIndicator(color: Colors.green),
                const SizedBox(height: 20),
                const Text("Waiting for sender to connect...", style: TextStyle(fontSize: 18)),
              ]
              
              else if (state.status == ConnectionStatus.waiting) ...[
                const CircularProgressIndicator(color: Colors.orange),
                const SizedBox(height: 20),
                Text("Incoming connection from ${state.pendingEndpointName}...", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        controller.acceptConnection();
                      },
                      child: const Text("Accept"),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        controller.rejectConnection();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Reject"),
                    ),
                  ],
                ),
              ],


              const Spacer(),

              // ==========================================
              // THE BUTTONS: Triggering the permissions and hardware
              // ==========================================
              
              if (state.status == ConnectionStatus.idle) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // SEND BUTTON
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text("SEND"),
                      onPressed: () async {
                        bool granted = await PermissionService.requestPermissions();
                        if (granted) {
                          controller.startDiscovery();
                        } else {
                          if(context.mounted){
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Permissions required to scan!')),
                            );
                          }
                        }
                      },
                    ),

                    // RECEIVE BUTTON
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text("RECEIVE"),
                      onPressed: () async {
                        bool granted = await PermissionService.requestPermissions();
                        if (granted) {
                          controller.startAdvertising();
                        } else {
                          if(context.mounted){
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Permissions required to receive!')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ] else ...[
                // CANCEL BUTTON (Shows up when scanning/advertising)
                TextButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text("Cancel", style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    controller.stopAll();
                  },
                )
              ],
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transferring Files"),
      ),
      body: const Center(
        child: Text("File transfer in progress..."),
      ),
    );
  }
}