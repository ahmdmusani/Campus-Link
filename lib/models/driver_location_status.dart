enum DriverLocationStatus {
  waitingForPermission,
  gpsDisabled,
  connecting,
  sharingLiveLocation,
  connectionLost;

  String get label {
    switch (this) {
      case DriverLocationStatus.waitingForPermission:
        return 'Waiting for Permission';
      case DriverLocationStatus.gpsDisabled:
        return 'GPS Disabled';
      case DriverLocationStatus.connecting:
        return 'Connecting...';
      case DriverLocationStatus.sharingLiveLocation:
        return 'Sharing Live Location';
      case DriverLocationStatus.connectionLost:
        return 'Connection Lost';
    }
  }
}
