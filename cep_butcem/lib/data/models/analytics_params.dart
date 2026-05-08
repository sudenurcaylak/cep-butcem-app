class AnalyticsParams {
  final String mode; // 'expense' | 'income'
  final String range; // 'day' | 'week' | 'month' | 'year'
  final DateTime anchor;
  final String category;

  const AnalyticsParams({
    required this.mode,
    required this.range,
    required this.anchor,
    required this.category,
  });

  AnalyticsParams copyWith({
    String? mode,
    String? range,
    DateTime? anchor,
    String? category,
  }) {
    return AnalyticsParams(
      mode: mode ?? this.mode,
      range: range ?? this.range,
      anchor: anchor ?? this.anchor,
      category: category ?? this.category,
    );
  }
}
