enum FeedbackKind {
  complaint,
  praise;

  static FeedbackKind fromStorage(String raw) {
    return raw == 'praise' ? FeedbackKind.praise : FeedbackKind.complaint;
  }

  String toStorage() =>
      this == FeedbackKind.praise ? 'praise' : 'complaint';
}
