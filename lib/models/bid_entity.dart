class BidEntity {
  const BidEntity({
    required this.id,
    required this.jobId,
    required this.courierId,
    required this.amountCents,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String courierId;
  final int amountCents;
  final DateTime createdAt;

  double get amount => amountCents / 100;
}
