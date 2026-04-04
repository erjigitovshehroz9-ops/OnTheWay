import '../../l10n/generated/app_localizations.dart';
import '../../models/support_request_entity.dart';

String supportRequestTypeLabel(AppLocalizations l10n, SupportRequestType t) {
  return switch (t) {
    SupportRequestType.complaint => l10n.createJobContactComplaint,
    SupportRequestType.praise => l10n.createJobContactPraise,
    SupportRequestType.application => l10n.createJobContactApplication,
    SupportRequestType.suggestion => l10n.createJobContactSuggestion,
  };
}

String supportRequestStatusLabel(AppLocalizations l10n, SupportRequestStatus s) {
  return switch (s) {
    SupportRequestStatus.fresh => l10n.supportRequestStatusNew,
    SupportRequestStatus.read => l10n.supportRequestStatusRead,
    SupportRequestStatus.resolved => l10n.supportRequestStatusResolved,
  };
}
