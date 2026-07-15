enum FeedbackView { anatomicalHeatmap, balanceMonitor }

extension FeedbackViewX on FeedbackView {
  String get id => switch (this) {
    FeedbackView.anatomicalHeatmap => 'anatomical_heatmap',
    FeedbackView.balanceMonitor => 'balance_monitor',
  };

  String get label => switch (this) {
    FeedbackView.anatomicalHeatmap => 'Anatomical Heatmap',
    FeedbackView.balanceMonitor => 'Balance Monitor',
  };
}

FeedbackView? feedbackViewFromId(String? id) {
  for (final view in FeedbackView.values) {
    if (view.id == id) return view;
  }
  return null;
}
