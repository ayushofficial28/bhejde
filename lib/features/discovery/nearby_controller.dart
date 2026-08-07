import 'dart:typed_data';

import 'package:bhejde/features/discovery/nearby_state.dart';
import 'package:bhejde/features/transfer/transfer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nearby_connections/nearby_connections.dart';


final nearbyControllerProvider =
    StateNotifierProvider<NearbyController, NearbyState>((ref) {
  return NearbyController(ref);
});

class NearbyController extends StateNotifier<NearbyState> {
  final Ref ref;
  NearbyController(this.ref) : super(NearbyState());
   final Strategy strategy = Strategy.P2P_POINT_TO_POINT;


   Future<void> startDiscovery() async {
    String username = "BhejDe_Sender";      //TODO: Add the take username and pass it here
    state = state.copyWith(status: ConnectionStatus.discovering);
    try {
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
    String username = "BhejDe_Receiver";      //TODO: Add the take username and pass it here
    state = state.copyWith(status: ConnectionStatus.advertising);
    try {
      await Nearby().startAdvertising(
        username,
        strategy,
        onConnectionInitiated: (id, name) {
          
          state = state.copyWith(
            pendingEndpointId: id,
            pendingEndpointName: name.endpointName,
            status: ConnectionStatus.waiting,
          );
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            state = state.copyWith(status: ConnectionStatus.connected);
          } else {
            state = state.copyWith(status: ConnectionStatus.idle);
          }
        },
        onDisconnected: (id) {
          state = state.copyWith(connectedEndpointId: null, status: ConnectionStatus.idle);
        },
      );
    } catch (e) {
      state = state.copyWith(status: ConnectionStatus.error);
    }
   }

   Future<void> acceptConnection() async {
    if (state.pendingEndpointId != null) {
      try{
      await Nearby().acceptConnection(
        state.pendingEndpointId!,
        onPayLoadRecieved: _onPayloadReceived,
        onPayloadTransferUpdate: _onPayloadUpdate
      );
      state = state.copyWith(
          status: ConnectionStatus.connected, 
          connectedEndpointId: state.pendingEndpointId,
          pendingEndpointId: null, 
          pendingEndpointName: null
        );
      } catch (e) {
        state = state.copyWith(status: ConnectionStatus.error, pendingEndpointId: null, pendingEndpointName: null);
      }
    }
   }

   Future<void> rejectConnection() async {
    if (state.pendingEndpointId != null) {
      try{
      await Nearby().rejectConnection(state.pendingEndpointId!);
      state = state.copyWith(pendingEndpointId: null, pendingEndpointName: null, status: ConnectionStatus.advertising);
      } catch (e) {
        state = state.copyWith(status: ConnectionStatus.error, pendingEndpointId: null, pendingEndpointName: null);
      }
    }
   }

   Future<void> initiateConnection(String endpointId) async {
    String username = "BhejDe_Sender";      
    try {
      state = state.copyWith(status: ConnectionStatus.connecting);
      await Nearby().requestConnection(
        username,
        endpointId,
        onConnectionInitiated: (id, name) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: _onPayloadReceived,
            onPayloadTransferUpdate: _onPayloadUpdate
          );
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            state = state.copyWith(status: ConnectionStatus.connected, connectedEndpointId: id);
          } else {
            state = state.copyWith(status: ConnectionStatus.idle);
          }
        },
        onDisconnected: (id) {
          state = state.copyWith(connectedEndpointId: null, status: ConnectionStatus.idle);
        },
      );
    } catch (e) {
      state = state.copyWith(status: ConnectionStatus.error);
    }
   }

  Future<void> stopAll() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    state = state.copyWith(status: ConnectionStatus.idle, discoveredPeers: {});
  }

  Future<void> stopDiscovery() async {
    try{
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
    super.dispose();
  }

  void Function(String, Payload) get _onPayloadReceived => (String endid, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      ref.read(transferControllerProvider.notifier).handleManifestBytes(payload.bytes!);
    } else if (payload.type == PayloadType.FILE) {
      ref.read(transferControllerProvider.notifier).handleIncomingFile(payload.id);
    }
  };

  void Function(String, PayloadTransferUpdate) get _onPayloadUpdate => (String endid, PayloadTransferUpdate update) {
    if (update.status == PayloadStatus.IN_PROGRESS) {
      ref.read(transferControllerProvider.notifier).updateProgress(update.bytesTransferred, update.totalBytes);
    } else if (update.status == PayloadStatus.SUCCESS) {
      ref.read(transferControllerProvider.notifier).markFileCompleted(update.id);
    } else if (update.status == PayloadStatus.FAILURE) {
      ref.read(transferControllerProvider.notifier).markTransferError("Failed to transfer file");
    }
  };

  Future<void> sendBytes(String endpointId, Uint8List bytes) async {
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  Future<int> sendFile(String endpointId, String filePath) async {
    return await Nearby().sendFilePayload(endpointId, filePath);
  }
}