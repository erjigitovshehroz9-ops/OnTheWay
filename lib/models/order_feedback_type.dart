/// Supabase `order_feedback.feedback_type`.
enum OrderFeedbackType {
  /// Faqat yulduzlar (shikoyat / maqtovsiz).
  rating,

  /// Shikoyat + ixtiyoriy kategoriya.
  complaint,

  /// Maqtov + ixtiyoriy kategoriya.
  praise;

  static OrderFeedbackType fromStorage(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'complaint':
        return OrderFeedbackType.complaint;
      case 'praise':
        return OrderFeedbackType.praise;
      default:
        return OrderFeedbackType.rating;
    }
  }

  String toStorage() => name;
}
