import 'package:flutter_test/flutter_test.dart';
import 'package:splitsmart/core/utils/settlement_memo.dart';

void main() {
  test('build returns the sandbox settlement memo format', () {
    expect(
      SettlementMemo.build(groupName: 'Goa 2025', expenseCount: 6),
      'SplitSmart: Goa 2025 (6 expenses)',
    );
  });
}
