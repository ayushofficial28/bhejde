import 'package:bhejde/features/file_selection/file_selection_screen.dart';
import 'package:bhejde/features/transfer/transfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:apks_manager/apks_manager.dart';

import '../../core/permission_service.dart';
import 'nearby_controller.dart';
import 'nearby_state.dart';
import 'device_name_provider.dart'; // 👉 Import our new provider

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nearbyControllerProvider);
    final controller = ref.read(nearbyControllerProvider.notifier);
    final currentDeviceName = ref.watch(deviceNameProvider); 

    ref.listen<NearbyState>(nearbyControllerProvider, (previous, next) {
      if (previous?.status != ConnectionStatus.connected &&
          next.status == ConnectionStatus.connected) {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => TransferScreen()));
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      
      appBar: AppBar(
        title: const Text(
          'BhejDe',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              accountName: Text(
                currentDeviceName, // 👉 Display the dynamic name
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text("Ready to connect"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Change Device Name'),
              onTap: () {
                Navigator.pop(context); 
                _showEditNameDialog(context, ref);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.install_mobile_rounded),
              title: const Text('Install APK'),
              onTap: () {
                Navigator.pop(context);
                _handleInstallApp(context);
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Container(
                  width: 240, // 👉 Increased size so the tagline is readable
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40), // Slightly larger curve for a bigger image
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2), // Slightly stronger shadow
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      'assets/splash/splash.png', // 👉 Pointing to the full image
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              Text(
                _getSubtitleText(state.status),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(flex: 3),

              if (state.status == ConnectionStatus.idle) ...[
                _buildActionButtons(context, controller, ref),
              ] else if (state.status == ConnectionStatus.advertising) ...[
                _buildLoadingCard(context, "Waiting for sender to connect...", Icons.wifi_tethering),
              ] else if (state.status == ConnectionStatus.waiting) ...[
                _buildWaitingUI(state, controller),
              ],

              const Spacer(flex: 2),

              if (state.status != ConnectionStatus.idle)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text(
                      "Cancel Connection",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      controller.stopAll();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER METHODS ---

  String _getSubtitleText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.discovering:
        return "Scanning nearby...";
      case ConnectionStatus.advertising:
        return "Visible to nearby devices";
      case ConnectionStatus.waiting:
        return "Incoming connection";
      default:
        return "";
    }
  }

  Widget _buildActionButtons(BuildContext context, dynamic controller, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            minimumSize: const Size(double.infinity, 70), 
            shape: const StadiumBorder(), 
            elevation: 4,
          ),
          icon: const Icon(Icons.arrow_upward_rounded, size: 28),
          label: const Text(
            "SEND",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          onPressed: () async {
            bool granted = await PermissionService.requestPermissions();
            if (!granted) {
              if (context.mounted) _showSnackBar(context, 'Permissions required!', isError: true);
              return;
            }
            
            // 👉 Smart fetch: Get real name now that permissions are granted!
            ref.read(deviceNameProvider.notifier).refreshHardwareName();

            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FileSelectionScreen()),
              );
            }
          },
        ),
        
        const SizedBox(height: 20), 
        
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            minimumSize: const Size(double.infinity, 70),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          icon: const Icon(Icons.arrow_downward_rounded, size: 28),
          label: const Text(
            "RECEIVE",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          onPressed: () async {
            bool granted = await PermissionService.requestPermissions();
            if (!granted) {
              if (context.mounted) _showSnackBar(context, 'Permissions required!', isError: true);
              return;
            }

            // 👉 Smart fetch: Get real name now that permissions are granted!
            ref.read(deviceNameProvider.notifier).refreshHardwareName();

            bool hardwareReady = await controller.checkHardwareRadios();
            if (!hardwareReady) {
              if (context.mounted) {
                _showSnackBar(context, 'Turn on Wi-Fi, Bluetooth, and Location!', isError: true);
              }
              return;
            }
            controller.startAdvertising();
          },
        ),
      ],
    );
  }

  // Widget _buildDiscoveringUI(NearbyState state, dynamic controller, BuildContext context) {
  //   return Container(
  //     constraints: const BoxConstraints(maxHeight: 250),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(24),
  //       boxShadow: [
  //         BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
  //       ],
  //     ),
  //     child: state.discoveredPeers.isEmpty
  //         ? const Padding(
  //             padding: EdgeInsets.all(32.0),
  //             child: Column(
  //               children: [
  //                 CircularProgressIndicator(),
  //                 SizedBox(height: 24),
  //                 Text("Looking for devices..."),
  //               ],
  //             ),
  //           )
  //         : ListView.separated(
  //             shrinkWrap: true,
  //             itemCount: state.discoveredPeers.length,
  //             separatorBuilder: (context, index) => const Divider(height: 1),
  //             itemBuilder: (context, index) {
  //               String endpointId = state.discoveredPeers.keys.elementAt(index);
  //               String deviceName = state.discoveredPeers.values.elementAt(index);

  //               return ListTile(
  //                 contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  //                 leading: CircleAvatar(
  //                   backgroundColor: Theme.of(context).colorScheme.primaryContainer,
  //                   child: Icon(Icons.phone_android, color: Theme.of(context).colorScheme.primary),
  //                 ),
  //                 title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
  //                 subtitle: const Text("Tap to connect"),
  //                 trailing: const Icon(Icons.chevron_right_rounded),
  //                 onTap: () => controller.initiateConnection(endpointId),
  //               );
  //             },
  //           ),
  //   );
  // }

  Widget _buildLoadingCard(BuildContext context, String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 70, height: 70,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            ],
          ),
          const SizedBox(height: 24),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildWaitingUI(NearbyState state, dynamic controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.compare_arrows_rounded, size: 50, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            "${state.pendingEndpointName} wants to connect",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.rejectConnection(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Reject"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => controller.acceptConnection(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Accept"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- DIALOGS & INSTALLATION METHODS ---

  void _showEditNameDialog(BuildContext context, WidgetRef ref) {
    final currentName = ref.read(deviceNameProvider);
    final textController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Device Name"),
          content: TextField(
            controller: textController,
            decoration:  InputDecoration(
              hintText: currentName,
              border: OutlineInputBorder(),
            ),
            maxLength: 20, 
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                ref.read(deviceNameProvider.notifier).updateName(textController.text);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleInstallApp(BuildContext context) async {
    try {
      // 1. Open Native File Picker with Custom Extensions
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk', 'apks', 'xapk', 'bhejde'],
      );

      // 2. Check if user canceled the picker
      if (result == null || result.files.single.path == null) {
        return; 
      }

      final path = result.files.single.path!;

      // 3. Show feedback that installation is starting
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Preparing installation... Please wait.'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      // 4. Pass to your package
      final success = await ApksManager.installBundle(path);

      // 5. Show Success/Failure UI
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Installation completed successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Installation failed or was cancelled.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error installing bundle: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message), 
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
  }
}