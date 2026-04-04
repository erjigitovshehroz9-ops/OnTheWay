enum DeliverySpeed {
  fast,
  relaxed,
  custom;

  static DeliverySpeed fromStorage(String? raw) {
    switch (raw) {
      case 'relaxed':
        return DeliverySpeed.relaxed;
      case 'custom':
        return DeliverySpeed.custom;
      case 'fast':
      default:
        return DeliverySpeed.fast;
    }
  }

  String toStorage() {
    switch (this) {
      case DeliverySpeed.fast:
        return 'fast';
      case DeliverySpeed.relaxed:
        return 'relaxed';
      case DeliverySpeed.custom:
        return 'custom';
    }
  }
}
