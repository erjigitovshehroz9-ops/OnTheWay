enum JobStatus {
  posted,
  auctionLive,
  assigned,
  pickedUp,
  delivered,
  completed,
  cancelled;

  static JobStatus fromStorage(String value) {
    switch (value) {
      case 'posted':
        return JobStatus.posted;
      case 'auction_live':
        return JobStatus.auctionLive;
      case 'assigned':
        return JobStatus.assigned;
      case 'picked_up':
        return JobStatus.pickedUp;
      case 'delivered':
        return JobStatus.delivered;
      case 'completed':
        return JobStatus.completed;
      case 'cancelled':
        return JobStatus.cancelled;
      case 'draft':
        return JobStatus.posted;
      case 'live_auction':
        return JobStatus.auctionLive;
      case 'winner_selected':
        return JobStatus.assigned;
      case 'in_delivery':
        return JobStatus.pickedUp;
      default:
        return JobStatus.posted;
    }
  }

  String toStorage() {
    switch (this) {
      case JobStatus.posted:
        return 'posted';
      case JobStatus.auctionLive:
        return 'auction_live';
      case JobStatus.assigned:
        return 'assigned';
      case JobStatus.pickedUp:
        return 'picked_up';
      case JobStatus.delivered:
        return 'delivered';
      case JobStatus.completed:
        return 'completed';
      case JobStatus.cancelled:
        return 'cancelled';
    }
  }
}
