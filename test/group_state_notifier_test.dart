import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitsmart/core/models/models.dart';
import 'package:splitsmart/core/repository/mock_database_repository.dart';
import 'package:splitsmart/core/state/group_state_notifier.dart';

void main() {
  group('GroupStateNotifier State Management Tests', () {
    late ProviderContainer container;
    late MockDatabaseRepository mockRepository;

    setUp(() {
      mockRepository = MockDatabaseRepository();
      container = ProviderContainer(
        overrides: [
          databaseRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial loading of group state and lazy debt calculations', () async {
      final notifier = container.read(groupStateNotifierProvider.notifier);

      // Initially, the state is empty
      expect(container.read(groupStateNotifierProvider).groupId, null);

      // Load group
      await notifier.loadGroup('group_hackathon');

      // Wait a microtask for the stream listeners to receive initial mock data
      await Future.delayed(const Duration(milliseconds: 250));

      final state = container.read(groupStateNotifierProvider);

      expect(state.groupId, 'group_hackathon');
      expect(state.isLoading, false);
      expect(state.members.length, 4);
      expect(state.expenses.length, 1);
      expect(state.splits.length, 4);
      expect(state.settlements.length, 1);

      // Verify net balance calculations
      // Abhinav: paid 1000, owes 250 -> Net = +750
      // Arnav: paid 0, owes 250 -> Net = -250
      // Shammas: paid 0, owes 400 -> Net = -400
      // Jyotirya: paid 0, owes 100 -> Net = -100
      // (Settlement between Arnav and Abhinav is pending, so it shouldn't count yet)
      final balances = state.netBalances;
      expect(balances['user_abhinav'], 750.0);
      expect(balances['user_arnav'], -250.0);
      expect(balances['user_shammas'], -400.0);
      expect(balances['user_jyotirya'], -100.0);

      // Verify simplified debts
      final debts = state.simplifiedDebts;
      expect(debts.length, 3);
      
      final arnavDebt = debts.firstWhere((d) => d.fromUserId == 'user_arnav');
      expect(arnavDebt.toUserId, 'user_abhinav');
      expect(arnavDebt.amount, 250.0);

      final shammasDebt = debts.firstWhere((d) => d.fromUserId == 'user_shammas');
      expect(shammasDebt.toUserId, 'user_abhinav');
      expect(shammasDebt.amount, 400.0);

      final jyotiryaDebt = debts.firstWhere((d) => d.fromUserId == 'user_jyotirya');
      expect(jyotiryaDebt.toUserId, 'user_abhinav');
      expect(jyotiryaDebt.amount, 100.0);
    });

    test('Confirming a pending settlement updates balance reactively', () async {
      final notifier = container.read(groupStateNotifierProvider.notifier);

      await notifier.loadGroup('group_hackathon');
      await Future.delayed(const Duration(milliseconds: 250));

      // Confirm the settlement
      await notifier.confirmSettlement('settlement_arnav_abhinav');
      await Future.delayed(const Duration(milliseconds: 250));

      final state = container.read(groupStateNotifierProvider);

      // Confirm settlement status changed to confirmed
      final confirmedSettlement = state.settlements.firstWhere((s) => s.id == 'settlement_arnav_abhinav');
      expect(confirmedSettlement.status, SettlementStatus.confirmed);

      // Verify updated balances:
      // Arnav owes 250, but paid 250 -> Net = 0
      // Abhinav was owed 750, received 250 -> Net = +500
      final balances = state.netBalances;
      expect(balances['user_arnav'], 0.0);
      expect(balances['user_abhinav'], 500.0);
      expect(balances['user_shammas'], -400.0);
      expect(balances['user_jyotirya'], -100.0);

      // Verify updated simplified debts (Arnav should be removed)
      final debts = state.simplifiedDebts;
      expect(debts.length, 2);
      expect(debts.any((d) => d.fromUserId == 'user_arnav'), false);
    });

    test('Adding a new expense reactively updates state and recalculated debts', () async {
      final notifier = container.read(groupStateNotifierProvider.notifier);

      await notifier.loadGroup('group_hackathon');
      await Future.delayed(const Duration(milliseconds: 250));

      // Confirm Arnav's settlement first so his net balance starts at 0
      await notifier.confirmSettlement('settlement_arnav_abhinav');
      await Future.delayed(const Duration(milliseconds: 250));

      // Now add a new expense: Arnav pays 600 for Snacks, shared equally between Arnav and Shammas (300 each)
      await notifier.addExpense(
        description: 'Snacks',
        amount: 600.0,
        payerId: 'user_arnav',
        category: ExpenseCategory.food,
        splitType: SplitType.equal,
        userOwedAmounts: {
          'user_arnav': 300.0,
          'user_shammas': 300.0,
        },
      );
      await Future.delayed(const Duration(milliseconds: 250));

      final state = container.read(groupStateNotifierProvider);

      // We should now have 2 expenses
      expect(state.expenses.length, 2);

      // New Balances calculation:
      // Arnav: started at 0. Paid 600, owed 300 -> +300
      // Shammas: started at -400. Paid 0, owed 300 -> -700
      // Abhinav: remains at +500
      // Jyotirya: remains at -100
      final balances = state.netBalances;
      expect(balances['user_arnav'], 300.0);
      expect(balances['user_shammas'], -700.0);
      expect(balances['user_abhinav'], 500.0);
      expect(balances['user_jyotirya'], -100.0);

      // Simplified debts should resolve:
      // Shammas owes 700, Jyotirya owes 100
      // Arnav is owed 300, Abhinav is owed 500
      // The greedy algorithm should output transfers matching these balances.
      final debts = state.simplifiedDebts;
      
      // Let's verify the net flows:
      double totalReceived = 0;
      double totalPaid = 0;
      for (var transfer in debts) {
        if (transfer.fromUserId == 'user_shammas') totalPaid += transfer.amount;
        if (transfer.fromUserId == 'user_jyotirya') totalPaid += transfer.amount;
        if (transfer.toUserId == 'user_arnav') totalReceived += transfer.amount;
        if (transfer.toUserId == 'user_abhinav') totalReceived += transfer.amount;
      }
      
      expect(totalPaid, 800.0);
      expect(totalReceived, 800.0);
    });
  });
}
