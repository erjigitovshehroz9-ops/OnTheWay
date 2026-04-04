import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/job_entity.dart';
import '../../../../models/job_status.dart';
import '../../../../models/order_feedback_entity.dart';
import '../../../../models/order_feedback_type.dart';
import '../../../../repositories/feedback_repository.dart';

String orderFeedbackCategoryLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'late':
      return l10n.fbCatComplaintLate;
    case 'rude':
      return l10n.fbCatComplaintRude;
    case 'careless_order':
      return l10n.fbCatComplaintCareless;
    case 'address_issue':
      return l10n.fbCatComplaintAddress;
    case 'fast_delivery':
      return l10n.fbCatPraiseFast;
    case 'polite':
      return l10n.fbCatPraisePolite;
    case 'careful':
      return l10n.fbCatPraiseCareful;
    case 'reliable':
      return l10n.fbCatPraiseReliable;
    case 'other':
      return l10n.fbCatOther;
    default:
      return key;
  }
}

Future<void> showOrderFeedbackBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required JobEntity job,
  required String fromUserId,
  required String toUserId,
  required AppLocalizations l10n,
  required bool ratingCourier,
}) async {
  if (kDebugMode) {
    debugPrint('[feedback] open order=${job.id} by=$fromUserId');
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: _OrderFeedbackFormSheet(
        job: job,
        fromUserId: fromUserId,
        toUserId: toUserId,
        l10n: l10n,
        ratingCourier: ratingCourier,
        onSubmitted: () {
          ref.invalidate(
            userSubmittedFeedbackForJobProvider(
              (jobId: job.id, userId: fromUserId),
            ),
          );
          ref.invalidate(
            myOrderFeedbackProvider((orderId: job.id, userId: fromUserId)),
          );
        },
      ),
    ),
  );
}

class _OrderFeedbackFormSheet extends StatefulWidget {
  const _OrderFeedbackFormSheet({
    required this.job,
    required this.fromUserId,
    required this.toUserId,
    required this.l10n,
    required this.ratingCourier,
    required this.onSubmitted,
  });

  final JobEntity job;
  final String fromUserId;
  final String toUserId;
  final AppLocalizations l10n;
  final bool ratingCourier;
  final VoidCallback onSubmitted;

  @override
  State<_OrderFeedbackFormSheet> createState() => _OrderFeedbackFormSheetState();
}

class _OrderFeedbackFormSheetState extends State<_OrderFeedbackFormSheet> {
  int _rating = 0;
  OrderFeedbackType _type = OrderFeedbackType.rating;
  String? _complaintCategory;
  String? _praiseCategory;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(FeedbackRepository repo) async {
    if (_rating < 1 || _rating > 5) return;
    if (_type == OrderFeedbackType.complaint &&
        (_complaintCategory == null || _complaintCategory!.isEmpty)) {
      return;
    }
    if (_type == OrderFeedbackType.praise &&
        (_praiseCategory == null || _praiseCategory!.isEmpty)) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await repo.submitOrderFeedback(
        job: widget.job,
        fromUserId: widget.fromUserId,
        toUserId: widget.toUserId,
        rating: _rating,
        feedbackType: _type,
        complaintCategory: _type == OrderFeedbackType.complaint
            ? _complaintCategory
            : null,
        praiseCategory:
            _type == OrderFeedbackType.praise ? _praiseCategory : null,
        comment: _commentCtrl.text,
      );
      widget.onSubmitted();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.feedbackSentThanks)),
        );
      }
    } on StateError catch (e) {
      if (mounted) {
        final msg = e.message == FeedbackRepository.duplicateOrderFeedbackCode
            ? widget.l10n.feedbackAlreadySubmitted
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.ratingCourier
                  ? l10n.orderFeedbackSheetTitleCourier
                  : l10n.orderFeedbackSheetTitleSender,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.orderFeedbackStarsLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final n = i + 1;
                final on = n <= _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = n),
                  icon: Icon(
                    on ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 36,
                    color: on ? Colors.amber.shade700 : Colors.grey,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.feedbackCategory,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.orderFeedbackTypeNeutral),
                  selected: _type == OrderFeedbackType.rating,
                  onSelected: (_) => setState(() {
                    _type = OrderFeedbackType.rating;
                    _complaintCategory = null;
                    _praiseCategory = null;
                  }),
                ),
                ChoiceChip(
                  label: Text(l10n.orderFeedbackTypeComplaint),
                  selected: _type == OrderFeedbackType.complaint,
                  onSelected: (_) => setState(() {
                    _type = OrderFeedbackType.complaint;
                    _praiseCategory = null;
                  }),
                ),
                ChoiceChip(
                  label: Text(l10n.orderFeedbackTypePraise),
                  selected: _type == OrderFeedbackType.praise,
                  onSelected: (_) => setState(() {
                    _type = OrderFeedbackType.praise;
                    _complaintCategory = null;
                  }),
                ),
              ],
            ),
            if (_type == OrderFeedbackType.complaint) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OrderFeedbackCategories.complaintKeys.map((k) {
                  return FilterChip(
                    label: Text(orderFeedbackCategoryLabel(l10n, k)),
                    selected: _complaintCategory == k,
                    onSelected: (v) => setState(
                      () => _complaintCategory = v ? k : null,
                    ),
                  );
                }).toList(),
              ),
            ],
            if (_type == OrderFeedbackType.praise) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OrderFeedbackCategories.praiseKeys.map((k) {
                  return FilterChip(
                    label: Text(orderFeedbackCategoryLabel(l10n, k)),
                    selected: _praiseCategory == k,
                    onSelected: (v) => setState(
                      () => _praiseCategory = v ? k : null,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.orderFeedbackCommentOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Consumer(
              builder: (context, ref, _) {
                final repoAsync = ref.watch(feedbackRepositoryProvider);
                return repoAsync.when(
                  data: (repo) {
                    final canSend = _rating >= 1 &&
                        (_type == OrderFeedbackType.rating ||
                            (_type == OrderFeedbackType.complaint &&
                                _complaintCategory != null) ||
                            (_type == OrderFeedbackType.praise &&
                                _praiseCategory != null));
                    return FilledButton(
                      onPressed: (!_submitting && canSend)
                          ? () => _submit(repo)
                          : null,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.feedbackSend),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Text('$e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// `completed` buyurtma uchun: CTA yoki mavjud baho kartasi.
class OrderFeedbackDetailSection extends ConsumerWidget {
  const OrderFeedbackDetailSection({
    super.key,
    required this.job,
    required this.viewerId,
    required this.l10n,
    this.courierChrome = false,
  });

  final JobEntity job;
  final String viewerId;
  final AppLocalizations l10n;
  final bool courierChrome;

  static const _textPrimary = Color(0xFF0A1629);
  static const _textSecondary = Color(0xFF7D8592);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (job.status != JobStatus.completed) {
      return const SizedBox.shrink();
    }
    final w = job.winnerCourierId?.trim() ?? '';
    if (w.isEmpty) return const SizedBox.shrink();
    final eligible = viewerId == job.senderId || viewerId == w;
    if (!eligible) return const SizedBox.shrink();

    final mineAsync = ref.watch(
      myOrderFeedbackProvider((orderId: job.id, userId: viewerId)),
    );
    final submittedAsync = ref.watch(
      userSubmittedFeedbackForJobProvider((jobId: job.id, userId: viewerId)),
    );

    final titleStyle = courierChrome
        ? const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          )
        : Theme.of(context).textTheme.titleSmall!;

    final secondaryStyle = courierChrome
        ? const TextStyle(
            fontSize: 14,
            height: 1.35,
            color: _textSecondary,
          )
        : TextStyle(
            fontSize: 14,
            height: 1.35,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );

    return mineAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 32),
          Text(l10n.submitFeedback, style: titleStyle),
          const SizedBox(height: 10),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (mine) => submittedAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 32),
            Text(l10n.submitFeedback, style: titleStyle),
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (submitted) {
          final canOpenForm = mine == null && !submitted;
          if (kDebugMode) {
            debugPrint(
              '[feedback-ui] canReview=$canOpenForm order=${job.id} viewer=$viewerId',
            );
          }

          final ratingCourier = viewerId == job.senderId;

          Widget body;
          if (mine != null) {
            body = _SummaryCard(
              feedback: mine,
              l10n: l10n,
              secondaryStyle: secondaryStyle,
              courierChrome: courierChrome,
            );
          } else if (submitted) {
            body = Text(
              l10n.feedbackAlreadySubmitted,
              style: secondaryStyle,
            );
          } else {
            body = FilledButton(
              style: courierChrome
                  ? FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF13635B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    )
                  : null,
              onPressed: () async {
                final toId = viewerId == job.senderId
                    ? job.winnerCourierId!
                    : job.senderId;
                await showOrderFeedbackBottomSheet(
                  context: context,
                  ref: ref,
                  job: job,
                  fromUserId: viewerId,
                  toUserId: toId,
                  l10n: l10n,
                  ratingCourier: ratingCourier,
                );
              },
              child: Text(
                ratingCourier ? l10n.rateCourierCta : l10n.rateSenderCta,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Divider(
                height: 32,
                color: courierChrome ? const Color(0xFFE8ECF2) : null,
              ),
              Text(l10n.submitFeedback, style: titleStyle),
              const SizedBox(height: 10),
              body,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.feedback,
    required this.l10n,
    required this.secondaryStyle,
    required this.courierChrome,
  });

  final OrderFeedbackEntity feedback;
  final AppLocalizations l10n;
  final TextStyle secondaryStyle;
  final bool courierChrome;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (feedback.feedbackType) {
      OrderFeedbackType.rating => l10n.orderFeedbackSummaryTypeRating,
      OrderFeedbackType.complaint => l10n.orderFeedbackSummaryTypeComplaint,
      OrderFeedbackType.praise => l10n.orderFeedbackSummaryTypePraise,
    };
    final cat = feedback.complaintCategory ?? feedback.praiseCategory;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: courierChrome ? Colors.white : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: courierChrome
              ? const Color(0xFFE8ECF2)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orderFeedbackYourSummaryTitle,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: courierChrome
                  ? OrderFeedbackDetailSection._textPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.orderFeedbackSummaryRating(feedback.rating),
            style: secondaryStyle.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(typeLabel, style: secondaryStyle),
          if (cat != null && cat.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.orderFeedbackSummaryCategory(
                orderFeedbackCategoryLabel(l10n, cat),
              ),
              style: secondaryStyle,
            ),
          ],
          if (feedback.comment != null && feedback.comment!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(feedback.comment!.trim(), style: secondaryStyle),
            ),
        ],
      ),
    );
  }
}
