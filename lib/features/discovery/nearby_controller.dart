import 'dart:typed_data';
import 'device_name_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:bhejde/features/discovery/nearby_state.dart';
import 'package:bhejde/features/transfer/transfer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

final nearbyControllerProvider =
    StateNotifierProvider<NearbyController, NearbyState>((ref) {
      return NearbyController(ref);
    });

class NearbyController extends StateNotifier<NearbyState> {
  final Ref ref;
  NearbyController(this.ref) : super(NearbyState());
  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;

  Future<void> startDiscovery() async {
    String username = ref.read(deviceNameProvider);
    state = state.copyWith(
      status: ConnectionStatus.discovering,
      discoveredPeers: {},
    );
    try {
      print('started discovery');
      await Nearby().startDiscovery(
        username,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          final updatedPeers = Map<String, String>.from(state.discoveredPeers);
          updatedPeers[id] = name;
          state = state.copyWith(discoveredPeers: updatedPeers);
        },
        onEndpointLost: (id) {
          final updatedPeers = Map<String, String>.from(state.discoveredPeers);
          updatedPeers.remove(id);
          state = state.copyWith(discoveredPeers: updatedPeers);
        },
      );
    } catch (e) {
      state = state.copyWith(status: ConnectionStatus.error);
    }
  }

  Future<void> startAdvertising() async {
    String username = ref.read(deviceNameProvider); 
    state = state.copyWith(status: ConnectionStatus.advertising);
    try {
      await Nearby().startAdvertising(
        username,
        strategy,
        onConnectionInitiated: (id, name) {
          print('started advertising');
          state = state.copyWith(
            pendingEndpointId: id,
            pendingEndpointName: name.endpointName,
            status: ConnectionStatus.waiting,
          );
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            state = state.copyWith(status: ConnectionStatus.connected,
              connectedEndpointId: id,
              pendingEndpointId: null,
              pendingEndpointName: null,
            );
          } else {
            state = state.copyWith(status: ConnectionStatus.idle,
              pendingEndpointId: null,
              pendingEndpointName: null,
            );
          }
        },
        onDisconnected: (id) {
          state = state.copyWith(
            connectedEndpointId: null,
            status: ConnectionStatus.idle,
            pendingEndpointId: null,
            pendingEndpointName: null,
            discoveredPeers: {}
          );
        },
      );
    } catch (e) {
      state = state.copyWith(status: ConnectionStatus.error);
    }
  }

  Future<void> acceptConnection() async {
    if (state.pendingEndpointId != null) {
      try {
        await Nearby().acceptConnection(
          state.pendingEndpointId!,
          onPayLoadRecieved: _onPayloadReceived,
          onPayloadTransferUpdate: _onPayloadUpdate,
        );
        state = state.copyWith(
          status: ConnectionStatus.connected,
          connectedEndpointId: state.pendingEndpointId,
          pendingEndpointId: null,
          pendingEndpointName: null,
        );
      } catch (e) {
        state = state.copyWith(
          status: ConnectionStatus.error,
          pendingEndpointId: null,
          pendingEndpointName: null,
        );
      }
    }
  }

  Future<void> rejectConnection() async {
    if (state.pendingEndpointId != null) {
      try {
        await Nearby().rejectConnection(state.pendingEndpointId!);
        state = state.copyWith(
          pendingEndpointId: null,
          pendingEndpointName: null,
          status: ConnectionStatus.advertising,
        );
      } catch (e) {
        state = state.copyWith(
          status: ConnectionStatus.error,
          pendingEndpointId: null,
          pendingEndpointName: null,
        );
      }
    }
  }

  Future<void> initiateConnection(String endpointId) async {
    String username = ref.read(deviceNameProvider);
    String endpointName = state.discoveredPeers[endpointId] ?? "Unknown";
    state = state.copyWith(
      status: ConnectionStatus.connecting,
      pendingEndpointId: endpointId,
      pendingEndpointName: endpointName,
    );
    try {
      state = state.copyWith(status: ConnectionStatus.connecting);
      await Nearby().requestConnection(
        username,
        endpointId,
        onConnectionInitiated: (id, name) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: _onPayloadReceived,
            onPayloadTransferUpdate: _onPayloadUpdate,
          );
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            state = state.copyWith(
              status: ConnectionStatus.connected,
              connectedEndpointId: id,
              pendingEndpointId: null,
              pendingEndpointName: null,
            );
          } else {
            state = state.copyWith(status: ConnectionStatus.idle,
              pendingEndpointId: null,
              pendingEndpointName: null,
            );
          }
        },
        onDisconnected: (id) {
          state = state.copyWith(
            connectedEndpointId: null,
            status: ConnectionStatus.idle,
            pendingEndpointId: null,
            pendingEndpointName: null,
            discoveredPeers: {},
          );
        },
      );
    } catch (e) {
      state = state.copyWith(status: ConnectionStatus.error,
        pendingEndpointId: null,
        pendingEndpointName: null,
      );
    }
  }

  Future<void> stopAll() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints(); 

    state = state.copyWith(
      status: ConnectionStatus.idle, 
      discoveredPeers: {},
      connectedEndpointId: null, 
      pendingEndpointId: null,   
      pendingEndpointName: null, 
    );
  }

  Future<void> stopDiscovery() async {
    try {
      await Nearby().stopDiscovery();
    } catch (e) {
      state = state.copyWith(status: ConnectionStatus.error);
    }
  }

  @override
  void dispose() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    state = state.copyWith(
      status: ConnectionStatus.idle, 
      discoveredPeers: {},
      connectedEndpointId: null, 
      pendingEndpointId: null,   
      pendingEndpointName: null, 
    );
    super.dispose();
  }

  void Function(String, Payload)
  get _onPayloadReceived => (String endid, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      ref
          .read(transferControllerProvider.notifier)
          .handleManifestBytes(payload.bytes!);
    } else if (payload.type == PayloadType.FILE) {
      String cachePath = payload.uri ?? payload.filePath ?? '';

      ref
          .read(transferControllerProvider.notifier)
          .handleIncomingFile(payload.id, cachePath);
      //ref.read(transferControllerProvider.notifier).handleIncomingFile(payload.id);
    }
  };

  void Function(String, PayloadTransferUpdate) get _onPayloadUpdate =>
      (String endid, PayloadTransferUpdate update) {
        if (update.status == PayloadStatus.IN_PROGRESS) {
          ref
              .read(transferControllerProvider.notifier)
              .updateProgress(update.bytesTransferred, update.totalBytes);
        } else if (update.status == PayloadStatus.SUCCESS) {
          ref
              .read(transferControllerProvider.notifier)
              .markFileCompleted(update.id);
        } else if (update.status == PayloadStatus.FAILURE) {
          ref
              .read(transferControllerProvider.notifier)
              .markTransferError("Failed to transfer file");
        }
      };

  Future<void> sendBytes(String endpointId, Uint8List bytes) async {
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  Future<int> sendFile(String endpointId, String filePath) async {
    return await Nearby().sendFilePayload(endpointId, filePath);
  }

  Future<bool> checkHardwareRadios() async {
    // 1. Guard Location (Requires permission_handler)
    if (!await Permission.location.serviceStatus.isEnabled) {
      const AndroidIntent intent = AndroidIntent(
        action: 'action_location_source_settings',
      );
      await intent.launch();
      return false;
    }

    // 2. Guard Bluetooth (Requires permission_handler)
    if (!await Permission.bluetooth.serviceStatus.isEnabled) {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.bluetooth.adapter.action.REQUEST_ENABLE',
      );
      await intent.launch();
      return false;
    }

    // 3. Guard Wi-Fi (Requires wifi_iot)
    bool isWifiOn = await WiFiForIoTPlugin.isEnabled();
    if (!isWifiOn) {
      // Slides up the beautiful Android 10+ Wi-Fi bottom sheet
      const AndroidIntent wifiIntent = AndroidIntent(
        action: 'android.settings.panel.action.WIFI',
      );
      await wifiIntent.launch();
      return false;
    }

    // If you reach this line, all 3 chips are receiving power!
    return true;
  }
}
