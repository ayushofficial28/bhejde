enum ConnectionStatus { 
  idle, 
  discovering,   // Sender is scanning for devices
  advertising,   // Receiver is waiting to be found
  connecting,    // Devices are shaking hands
  connected,     // Handshake successful, ready to send files
  transferring,  // Active file transfer in progress
  error          // Connection dropped or failed
}

class NearbyState {
  final ConnectionStatus status;
  final Map<String, String> discoveredPeers; 
  final String? connectedEndpointId;
  final double transferProgress;

  NearbyState({
    this.status = ConnectionStatus.idle,
    this.discoveredPeers = const {},
    this.connectedEndpointId,
    this.transferProgress = 0.0,
  });

  NearbyState copyWith({
    ConnectionStatus? status,
    Map<String, String>? discoveredPeers,
    String? connectedEndpointId,
    double? transferProgress,
  }) {
    return NearbyState(
      status: status ?? this.status,
      discoveredPeers: discoveredPeers ?? this.discoveredPeers,
      connectedEndpointId: connectedEndpointId ?? this.connectedEndpointId,
      transferProgress: transferProgress ?? this.transferProgress,
    );
  }
}