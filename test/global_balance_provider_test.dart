import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsmart/core/auth/auth_provider.dart';
import 'package:splitsmart/core/repository/mock_database_repository.dart';
import 'package:splitsmart/core/state/group_state_notifier.dart';
import 'package:splitsmart/features/dashboard/global_balance_provider.dart';

void main() {
  test('globalBalanceProvider sums net balance across user groups', () async {
    final container = ProviderContainer(
      overrides: [
        databaseRepositoryProvider.overrideWithValue(MockDatabaseRepository()),
        currentUserIdProvider.overrideWithValue('user_abhinav'),
      ],
    );
    addTearDown(container.dispose);

    final balance = await container.read(globalBalanceProvider.future);
    expect(balance, 750.0);
  });

  test('globalBalanceProvider returns zero when user has no groups', () async {
    final container = ProviderContainer(
      overrides: [
        databaseRepositoryProvider.overrideWithValue(MockDatabaseRepository()),
        currentUserIdProvider.overrideWithValue('user_unknown'),
      ],
    );
    addTearDown(container.dispose);

    final balance = await container.read(globalBalanceProvider.future);
    expect(balance, 0.0);
  });
}
