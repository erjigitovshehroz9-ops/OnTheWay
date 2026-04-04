/// Mahalliy SQLite dan yig‘ilgan admin operatsion ko‘rsatkichlar.
class AdminOperationalSnapshot {
  const AdminOperationalSnapshot({
    required this.usersTotal,
    required this.senders,
    required this.couriers,
    required this.jobsTotal,
    required this.jobsPosted,
    required this.jobsAuctionLive,
    required this.jobsAssigned,
    required this.jobsPickedUp,
    required this.jobsDelivered,
    required this.jobsCompleted,
    required this.jobsCancelled,
    required this.blockedUsers,
    required this.orderFeedbackTotal,
    required this.orderFeedbackAvgRating,
    required this.orderFeedbackComplaints,
    required this.orderFeedbackPraises,
    required this.legacyComplaints,
    required this.auctionsTouchedCount,
    required this.avgAuctionBidCount,
    required this.avgFinalDiscountCents,
    required this.activeDeliveryTrackingCount,
    required this.topComplaintUserIds,
    required this.topCourierRatings,
    required this.usersByRegion,
    required this.jobsByRegion,
    required this.usersByDistrict,
    required this.jobsByDistrict,
  });

  final int usersTotal;
  final int senders;
  final int couriers;
  final int jobsTotal;
  final int jobsPosted;
  final int jobsAuctionLive;
  final int jobsAssigned;
  final int jobsPickedUp;
  final int jobsDelivered;
  final int jobsCompleted;
  final int jobsCancelled;
  final int blockedUsers;

  final int orderFeedbackTotal;
  final double orderFeedbackAvgRating;
  final int orderFeedbackComplaints;
  final int orderFeedbackPraises;
  final int legacyComplaints;

  final int auctionsTouchedCount;
  final double avgAuctionBidCount;
  final double avgFinalDiscountCents;
  final int activeDeliveryTrackingCount;

  final List<({String userId, int count})> topComplaintUserIds;
  final List<({String userId, double rating})> topCourierRatings;

  final List<({String code, int count})> usersByRegion;
  final List<({String code, int count})> jobsByRegion;
  final List<({String code, int count})> usersByDistrict;
  final List<({String code, int count})> jobsByDistrict;

  int get complaintsCombined => orderFeedbackComplaints + legacyComplaints;

  /// Flutter web: no local SQLite aggregates.
  static AdminOperationalSnapshot emptyWeb() => const AdminOperationalSnapshot(
        usersTotal: 0,
        senders: 0,
        couriers: 0,
        jobsTotal: 0,
        jobsPosted: 0,
        jobsAuctionLive: 0,
        jobsAssigned: 0,
        jobsPickedUp: 0,
        jobsDelivered: 0,
        jobsCompleted: 0,
        jobsCancelled: 0,
        blockedUsers: 0,
        orderFeedbackTotal: 0,
        orderFeedbackAvgRating: 0,
        orderFeedbackComplaints: 0,
        orderFeedbackPraises: 0,
        legacyComplaints: 0,
        auctionsTouchedCount: 0,
        avgAuctionBidCount: 0,
        avgFinalDiscountCents: 0,
        activeDeliveryTrackingCount: 0,
        topComplaintUserIds: [],
        topCourierRatings: [],
        usersByRegion: [],
        jobsByRegion: [],
        usersByDistrict: [],
        jobsByDistrict: [],
      );
}
