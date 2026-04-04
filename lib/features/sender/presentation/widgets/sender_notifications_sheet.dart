import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/sender_in_app_notification.dart';
import '../../application/sender_in_app_notifications_provider.dart';

String _senderNotificationBodyFallback(
  SenderNotificationKind k,
  AppLocalizations l10n,
) {
  return switch (k) {
    SenderNotificationKind.auctionStarted => l10n.senderSnackbarAuctionStarted,
    SenderNotificationKind.auctionEndedAssigned =>
      l10n.senderSnackbarAuctionEndedAssigned,
    SenderNotificationKind.auctionEndedReopened =>
      l10n.senderSnackbarAuctionEndedReopened,
    SenderNotificationKind.auctionEndedCancelled =>
      l10n.senderSnackbarAuctionEndedCancelled,
    SenderNotificationKind.courierNearPickup1Km =>
      l10n.senderNotifCourierNearPickup1Km,
    SenderNotificationKind.courierNearDropoff5Km =>
      l10n.senderNotifCourierNearDropoff5Km,
    SenderNotificationKind.courierNearDropoff2Km =>
      l10n.senderNotifCourierNearDropoff2Km,
  };
}

String senderNotificationDisplay(SenderInAppNotification n, AppLocalizations l10n) {
  final d = n.displayMessage?.trim();
  if (d != null && d.isNotEmpty) return d;
  return _senderNotificationBodyFallback(n.kind, l10n);
}

/// Menyu qatorida yoki avatarda — yangi bildirishnoma borligini ko‘rsatadi.
class PulsingNotificationDot extends StatefulWidget {
  const PulsingNotificationDot({super.key, this.size = 10});

  final double size;

  @override
  State<PulsingNotificationDot> createState() => _PulsingNotificationDotState();
}

class _PulsingNotificationDotState extends State<PulsingNotificationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFF97316);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.65),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}

void showSenderNotificationsSheet(
  BuildContext context,
  WidgetRef ref,
  String userId,
) {
  final closed = showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final l10n = AppLocalizations.of(context);
          final async = ref.watch(senderInAppNotificationsProvider(userId));
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      l10n.senderNotificationsSheetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Expanded(
                    child: async.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Center(
                        child: Text(l10n.senderNotificationsLoadError),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                l10n.senderNotificationsEmpty,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final n = items[index];
                            final body = senderNotificationDisplay(n, l10n);
                            final timeStr = _formatTime(context, n.createdAt);
                            final theme = Theme.of(context);
                            return Material(
                              color: n.read
                                  ? theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.35)
                                  : theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  if (!n.read) {
                                    await ref
                                        .read(senderInAppNotificationsProvider(
                                                userId)
                                            .notifier)
                                        .markRead(n.id);
                                  }
                                  if (!context.mounted) return;
                                  await showDialog<void>(
                                    context: context,
                                    builder: (dCtx) {
                                      final jid = n.jobId;
                                      final showJobLink = jid != null &&
                                          jid.isNotEmpty &&
                                          (n.kind ==
                                                  SenderNotificationKind
                                                      .auctionEndedAssigned ||
                                              n.kind ==
                                                  SenderNotificationKind
                                                      .courierNearPickup1Km ||
                                              n.kind ==
                                                  SenderNotificationKind
                                                      .courierNearDropoff5Km ||
                                              n.kind ==
                                                  SenderNotificationKind
                                                      .courierNearDropoff2Km);
                                      return AlertDialog(
                                        title: Text(
                                          l10n.senderNotificationsTooltip,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                        content: SingleChildScrollView(
                                          child: Text(body),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(dCtx).pop(),
                                            child: Text(
                                                MaterialLocalizations.of(
                                                        context)
                                                    .closeButtonLabel),
                                          ),
                                          if (showJobLink)
                                            FilledButton(
                                              onPressed: () {
                                                final router =
                                                    GoRouter.of(context);
                                                Navigator.of(dCtx).pop();
                                                final nav =
                                                    Navigator.of(context);
                                                if (nav.canPop()) {
                                                  nav.pop();
                                                }
                                                Future.microtask(() =>
                                                    router.push(AppRoutes
                                                        .jobDetail(jid)));
                                              },
                                              child: Text(
                                                  l10n.senderNotifOpenJobDetails),
                                            ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        n.read
                                            ? Icons
                                                .notifications_none_rounded
                                            : Icons
                                                .notifications_active_rounded,
                                        color: n.read
                                            ? theme.colorScheme.onSurfaceVariant
                                            : theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              body,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: n.read
                                                    ? FontWeight.w500
                                                    : FontWeight.w700,
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              timeStr,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            if (!n.read) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                l10n.senderNotificationsTapToRead,
                                                style: theme.textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
  closed.whenComplete(() {
    ref
        .read(senderInAppNotificationsProvider(userId).notifier)
        .markAllRead();
  });
}

String _formatTime(BuildContext context, DateTime at) {
  final locale = Localizations.localeOf(context).toString();
  final now = DateTime.now();
  final diff = now.difference(at);
  if (diff.inSeconds < 60) {
    return AppLocalizations.of(context).senderNotificationsTimeJustNow;
  }
  if (diff.inMinutes < 60) {
    return AppLocalizations.of(context)
        .senderNotificationsTimeMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return AppLocalizations.of(context)
        .senderNotificationsTimeHoursAgo(diff.inHours);
  }
  return DateFormat.yMMMd(locale).add_jm().format(at);
}
