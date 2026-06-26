abstract final class SettlementMemo {
  static String build({
    required String groupName,
    required int expenseCount,
  }) {
    return 'SplitSmart: $groupName ($expenseCount expenses)';
  }
}
