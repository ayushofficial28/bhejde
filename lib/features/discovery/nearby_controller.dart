import 'package:bhejde/features/discovery/nearby_state.dart';
import 'package:device_name/device_name.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nearby_connections/nearby_connections.dart';


final nearbyControllerProvider =
    StateNotifierProvider<NearbyController, NearbyState>((ref) {
  return NearbyController();
});

class NearbyController extends StateNotifier<NearbyState> {
  NearbyController() : super(NearbyState());
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
        onPayLoadRecieved: (endid, payload) {
          // Handle received payload
        },
        onPayloadTransferUpdate: (endid, update) {
          // Handle payload transfer updates
        },
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
    String username = "BhejDe_Sender";      //TODO: Add the take username and pass it here
    try {
      await Nearby().requestConnection(
        username,
        endpointId,
        onConnectionInitiated: (id, name) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endid, payload) {
              // Handle received payload
            },
            onPayloadTransferUpdate: (endid, update) {
              // Handle payload transfer updates
            },
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

  Future<void> stopAll() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
  }

  @override
  void dispose() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    super.dispose();
  }

  
}