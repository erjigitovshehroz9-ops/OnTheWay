/// Server `notification_events.type` va FCM `data.type` bilan mos kelishi kerak.
enum PushNotificationType {
  newMatchingOrder('new_matching_order'),
  auctionStarted('auction_started'),
  /// Birinchi kuryer auksionga kirganda (sender).
  auctionCourierJoined('auction_courier_joined'),
  auctionOutbid('auction_outbid'),
  auctionWon('auction_won'),
  auctionLost('auction_lost'),
  winnerSelected('winner_selected'),
  orderPickedUp('order_picked_up'),
  orderDelivered('order_delivered'),
  orderCompleted('order_completed'),
  feedbackReminder('feedback_reminder'),
  complaintCreated('complaint_created'),
  lowRatingAlert('low_rating_alert'),
  /// Admin: potentsial muammo buyurtmalari (kelajakda).
  orderRiskAlert('order_risk_alert'),
  unknown('unknown');

  const PushNotificationType(this.storageValue);
  final String storageValue;

  static PushNotificationType fromRaw(String? raw) {
    final s = raw?.trim().toLowerCase() ?? '';
    if (s.isEmpty) return PushNotificationType.unknown;
    for (final v in PushNotificationType.values) {
      if (v.storageValue == s) return v;
    }
    return PushNotificationType.unknown;
  }
}
