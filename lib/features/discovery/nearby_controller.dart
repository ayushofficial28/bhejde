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
          state.discoveredPeers[id] = name;
          state = state.copyWith(discoveredPeers: state.discoveredPeers);
        },
        onEndpointLost: (id) {
          state.discoveredPeers.remove(id);
          state = state.copyWith(discoveredPeers: state.discoveredPeers);
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
          
          //TODO: Write the handshake logic
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
}