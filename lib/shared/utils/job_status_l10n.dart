import '../../l10n/generated/app_localizations.dart';
import '../../models/job_status.dart';

String jobStatusLabel(JobStatus s, AppLocalizations l10n) {
  switch (s) {
    case JobStatus.posted:
      return l10n.statusPosted;
    case JobStatus.auctionLive:
      return l10n.statusAuction;
    case JobStatus.assigned:
      return l10n.statusAssigned;
    case JobStatus.pickedUp:
      return l10n.statusPickedUp;
    case JobStatus.delivered:
      return l10n.statusDelivered;
    case JobStatus.completed:
      return l10n.statusCompleted;
    case JobStatus.cancelled:
      return l10n.statCancelled;
  }
}
