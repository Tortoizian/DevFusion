import 'package:flutter_test/flutter_test.dart';
import 'package:splitsmart/core/algorithms/debt_simplification.dart';

void main() {
  group('DebtSimplificationEngine Tests', () {
    test('Simple 2-person debt where one owes the other', () {
      // User A paid 100, User B owes 50, User A owes 50
      // Net: A is +50, B is -50
      final netBalances = {
        'user_a': 50.0,
        'user_b': -50.0,
      };

      final transfers = DebtSimplificationEngine.simplifyDebts(netBalances);

      expect(transfers.length, 1);
      expect(transfers[0].fromUserId, 'user_b');
      expect(transfers[0].toUserId, 'user_a');
      expect(transfers[0].amount, 50.0);
    });

    test('3-person cycle simplifies correctly', () {
      // Suppose we have:
      // A owes B 100
      // B owes C 100
      // C owes A 100
      // Everyone's net balance should be 0.
      final netBalances = {
        'user_a': 0.0,
        'user_b': 0.0,
        'user_c': 0.0,
      };

      final transfers = DebtSimplificationEngine.simplifyDebts(netBalances);

      expect(transfers.isEmpty, true);
    });

    test('3-person net debt resolution', () {
      // A owes B 100 (-100 for A, +100 for B)
      // B owes C 100 (-100 for B, +100 for C)
      // Net: A is -100, B is 0, C is +100
      // Simplified: A should pay C 100 directly.
      final netBalances = {
        'user_a': -100.0,
        'user_b': 0.0,
        'user_c': 100.0,
      };

      final transfers = DebtSimplificationEngine.simplifyDebts(netBalances);

      expect(transfers.length, 1);
      expect(transfers[0].fromUserId, 'user_a');
      expect(transfers[0].toUserId, 'user_c');
      expect(transfers[0].amount, 100.0);
    });

    test('Complex 4-person trip scenario', () {
      // Scenario:
      // Abhinav (+450)
      // Arnav (-250)
      // Shammas (-150)
      // Jyotirya (-50)
      // Sum = 450 - 250 - 150 - 50 = 0
      final netBalances = {
        'abhinav': 450.0,
        'arnav': -250.0,
        'shammas': -150.0,
        'jyotirya': -50.0,
      };

      final transfers = DebtSimplificationEngine.simplifyDebts(netBalances);

      // Expected transfers:
      // Arnav owes 250 -> Abhinav
      // Shammas owes 150 -> Abhinav
      // Jyotirya owes 50 -> Abhinav
      expect(transfers.length, 3);

      final totalTransferred = transfers.fold<double>(0, (sum, t) => sum + t.amount);
      expect(totalTransferred, 450.0);

      for (var transfer in transfers) {
        expect(transfer.toUserId, 'abhinav');
        if (transfer.fromUserId == 'arnav') {
          expect(transfer.amount, 250.0);
        } else if (transfer.fromUserId == 'shammas') {
          expect(transfer.amount, 150.0);
        } else if (transfer.fromUserId == 'jyotirya') {
          expect(transfer.amount, 50.0);
        }
      }
    });

    test('Precision filtering ignores small balances', () {
      final netBalances = {
        'user_a': 0.004,
        'user_b': -0.004,
      };

      final transfers = DebtSimplificationEngine.simplifyDebts(netBalances);

      expect(transfers.isEmpty, true);
    });

    test('Preserves total debt through simplification', () {
      final netBalances = {
        'user_a': 123.45,
        'user_b': -50.0,
        'user_c': -73.45,
      };

      final transfers = DebtSimplificationEngine.simplifyDebts(netBalances);
      final totalCredit = netBalances.values.where((value) => value > 0).fold<double>(0, (sum, value) => sum + value);
      final totalTransferred = transfers.fold<double>(0, (sum, transfer) => sum + transfer.amount);

      expect(totalTransferred, closeTo(totalCredit, 0.01));
      expect(transfers.every((transfer) => transfer.amount >= 0.01), true);
    });

    test('Bidirectional debts collapse to a single net transfer', () {
      final netBalances = {
        'user_a': -60.0,
        'user_b': 60.0,
      };

      final transfers = DebtSimplificationEngine.simplifyDebts(netBalances);

      expect(transfers.length, 1);
      expect(transfers.first.fromUserId, 'user_a');
      expect(transfers.first.toUserId, 'user_b');
      expect(transfers.first.amount, 60.0);
    });
  });
}
