enum PaymentType {
  cash,
  card,
  prepaid;

  static PaymentType fromStorage(String? raw) {
    switch (raw) {
      case 'card':
        return PaymentType.card;
      case 'prepaid':
        return PaymentType.prepaid;
      case 'cash':
      default:
        return PaymentType.cash;
    }
  }

  String toStorage() {
    switch (this) {
      case PaymentType.cash:
        return 'cash';
      case PaymentType.card:
        return 'card';
      case PaymentType.prepaid:
        return 'prepaid';
    }
  }
}
