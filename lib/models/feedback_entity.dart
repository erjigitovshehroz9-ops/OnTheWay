import 'feedback_kind.dart';

class FeedbackEntity {
  const FeedbackEntity({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.jobId,
    required this.kind,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String jobId;
  final FeedbackKind kind;
  final String category;
  final DateTime createdAt;
}
