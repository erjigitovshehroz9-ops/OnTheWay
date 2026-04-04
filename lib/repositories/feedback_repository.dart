import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/feedback_entity.dart';
import '../models/feedback_kind.dart';
import '../models/job_entity.dart';
import '../models/job_status.dart';
import '../models/order_feedback_entity.dart';
import '../models/order_feedback_type.dart';
import '../services/supabase_service.dart';
import 'user_repository.dart';

class FeedbackRepository {
  FeedbackRepository({
    required AppDatabase database,
    required UserRepository userRepository,
    this.supabaseOrderService,
  })  : _db = database,
        _users = userRepository;

  /// Eski mahalliy `feedback` jadvali uchun.
  static const duplicateFeedbackCode = 'feedback_already_submitted';

  /// `order_feedback` unique yoki server `duplicate`.
  static const duplicateOrderFeedbackCode = 'order_feedback_duplicate';

  final AppDatabase _db;
  final UserRepository _users;
  final SupabaseOrderService? supabaseOrderService;
  final _uuid = const Uuid();

  /// Yangi yoki eski jadval — bittasida yozuv bo‘lsa true.
  Future<bool> hasSubmittedForJob({
    required String fromUserId,
    required String jobId,
  }) {
    return _db.hasAnyFeedbackFromUserForOrder(
      fromUserId: fromUserId,
      orderId: jobId,
    );
  }

  Future<OrderFeedbackEntity?> loadMyOrderFeedback({
    required String orderId,
    required String fromUserId,
  }) async {
    final local = await _db.getOrderFeedbackByFromUser(
      orderId: orderId,
      fromUserId: fromUserId,
    );
    final remote = supabaseOrderService;
    if (remote != null) {
      try {
        final row = await remote.fetchMyOrderFeedbackRemote(
          orderId: orderId,
          fromUserId: fromUserId,
        );
        if (row != null) {
          await _db.insertOrderFeedback(row);
          return row;
        }
      } catch (e, st) {
        debugPrint('[feedback] load remote failed: $e');
        if (kDebugMode) debugPrintStack(stackTrace: st);
      }
    }
    return local;
  }

  bool canSubmitOrderFeedback(JobEntity job, String viewerId) {
    if (job.status != JobStatus.completed) return false;
    final w = job.winnerCourierId?.trim() ?? '';
    if (w.isEmpty) return false;
    return viewerId == job.senderId || viewerId == w;
  }

  String? feedbackRecipientUserId(JobEntity job, String viewerId) {
    final w = job.winnerCourierId?.trim();
    if (w == null || w.isEmpty) return null;
    if (viewerId == job.senderId) return w;
    if (viewerId == w) return job.senderId;
    return null;
  }

  Future<void> submitOrderFeedback({
    required JobEntity job,
    required String fromUserId,
    required String toUserId,
    required int rating,
    required OrderFeedbackType feedbackType,
    String? complaintCategory,
    String? praiseCategory,
    String? comment,
  }) async {
    if (job.status != JobStatus.completed) {
      throw StateError('order_not_completed');
    }
    if (rating < 1 || rating > 5) throw StateError('invalid_rating');
    final w = job.winnerCourierId?.trim() ?? '';
    if (w.isEmpty) throw StateError('no_winner');
    if (fromUserId != job.senderId && fromUserId != w) {
      throw StateError('forbidden');
    }
    if (fromUserId == job.senderId && toUserId != w) {
      throw StateError('invalid_to');
    }
    if (fromUserId == w && toUserId != job.senderId) {
      throw StateError('invalid_to');
    }

    if (await hasSubmittedForJob(fromUserId: fromUserId, jobId: job.id)) {
      debugPrint(
        '[feedback] duplicate prevented order=${job.id} from=$fromUserId',
      );
      throw StateError(duplicateOrderFeedbackCode);
    }

    if (feedbackType == OrderFeedbackType.complaint) {
      final c = complaintCategory?.trim() ?? '';
      if (c.isEmpty) throw StateError('complaint_category_required');
    }
    if (feedbackType == OrderFeedbackType.praise) {
      final c = praiseCategory?.trim() ?? '';
      if (c.isEmpty) throw StateError('praise_category_required');
    }

    if (kDebugMode) {
      debugPrint(
        '[feedback] submit order=${job.id} from=$fromUserId to=$toUserId '
        'rating=$rating type=${feedbackType.toStorage()}',
      );
    }

    final s = supabaseOrderService;
    late String id;
    if (s != null) {
      final res = await s.submitOrderFeedbackRpc(
        orderId: job.id,
        toUserId: toUserId,
        rating: rating,
        feedbackType: feedbackType.toStorage(),
        complaintCategory: complaintCategory,
        praiseCategory: praiseCategory,
        comment: comment,
      );
      if (res['ok'] != true) {
        final err = res['error']?.toString() ?? 'unknown';
        if (err == 'duplicate') {
          debugPrint(
            '[feedback] duplicate prevented order=${job.id} from=$fromUserId',
          );
          throw StateError(duplicateOrderFeedbackCode);
        }
        throw StateError('remote_$err');
      }
      id = res['id']?.toString() ?? _uuid.v4();
    } else {
      id = _uuid.v4();
    }

    final now = DateTime.now();
    final fromRole = fromUserId == job.senderId ? 'sender' : 'courier';
    final toRole = toUserId == job.senderId ? 'sender' : 'courier';
    final trimmedComment = comment?.trim();
    final entity = OrderFeedbackEntity(
      id: id,
      orderId: job.id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromRole: fromRole,
      toRole: toRole,
      rating: rating,
      feedbackType: feedbackType,
      complaintCategory: feedbackType == OrderFeedbackType.complaint
          ? complaintCategory?.trim()
          : null,
      praiseCategory:
          feedbackType == OrderFeedbackType.praise ? praiseCategory?.trim() : null,
      comment: trimmedComment != null && trimmedComment.isNotEmpty
          ? trimmedComment
          : null,
      createdAt: now,
      updatedAt: now,
      complaintStatus: feedbackType == OrderFeedbackType.complaint ? 'new' : null,
    );
    await _db.insertOrderFeedback(entity);
    await _users.applyOrderFeedbackImpact(
      toUserId: toUserId,
      rating: rating,
      feedbackType: feedbackType,
    );

    if (kDebugMode) {
      debugPrint('[feedback] success id=$id');
    }

    if (s != null) {
      try {
        final sum = await s.fetchUserFeedbackSummaryRemote(toUserId);
        if (sum != null && kDebugMode) {
          debugPrint(
            '[feedback] summary user=$toUserId avg=${sum['average_rating']} '
            'total=${sum['total_ratings']} complaints=${sum['total_complaints']} '
            'praises=${sum['total_praises']}',
          );
        }
      } catch (_) {}
    }
  }

  /// Eski oqim (mahalliy `feedback` jadvali).
  Future<void> submit({
    required String fromUserId,
    required String toUserId,
    required String jobId,
    required FeedbackKind kind,
    required String category,
  }) async {
    if (await hasSubmittedForJob(fromUserId: fromUserId, jobId: jobId)) {
      throw StateError(FeedbackRepository.duplicateFeedbackCode);
    }
    await _db.insertFeedback(
      FeedbackEntity(
        id: _uuid.v4(),
        fromUserId: fromUserId,
        toUserId: toUserId,
        jobId: jobId,
        kind: kind,
        category: category,
        createdAt: DateTime.now(),
      ),
    );
    await _users.applyFeedbackDelta(
      userId: toUserId,
      complaintDelta: kind == FeedbackKind.complaint ? 1 : 0,
      praiseDelta: kind == FeedbackKind.praise ? 1 : 0,
    );
  }
}
