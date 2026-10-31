/// What the statements list shows. An empty set means "all".
class StatementFilter {
  final Set<int> accounts;
  final Set<String> tags;

  /// Show statements without any of [tags] instead of those with one of them.
  final bool excludeTags;

  /// Selecting only one of them limits the list to it; none or both show all.
  final bool income;
  final bool expense;

  /// Searched in title and note, case-insensitive.
  final String text;

  const StatementFilter({
    this.accounts = const {},
    this.tags = const {},
    this.excludeTags = false,
    this.income = false,
    this.expense = false,
    this.text = '',
  });

  StatementFilter copyWith({
    Set<int>? accounts,
    Set<String>? tags,
    bool? income,
    bool? expense,
    String? text,
  }) => StatementFilter(
    accounts: accounts ?? this.accounts,
    tags: tags ?? this.tags,
    excludeTags: excludeTags,
    income: income ?? this.income,
    expense: expense ?? this.expense,
    text: text ?? this.text,
  );

  bool get isActive =>
      accounts.isNotEmpty ||
      tags.isNotEmpty ||
      income != expense ||
      text.isNotEmpty;
}
