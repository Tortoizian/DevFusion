import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/profile_provider.dart';
import '../../core/models/user_model.dart';
import '../../shared/widgets/app_button.dart';
import 'global_balance_provider.dart';
import 'widgets/dashboard_empty_state.dart';
import 'widgets/global_balance_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _avatarUrl(String name) {
    return UserModel(
      id: '',
      name: name,
      upiId: '',
      createdAt: DateTime.now(),
    ).avatarUrl.replaceFirst('/svg?', '/png?');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final displayName = profile?.name ?? 'there';
    final globalBalanceAsync = ref.watch(globalBalanceProvider);
    final userGroupsAsync = ref.watch(userGroupsProvider);
    final hasGroups = userGroupsAsync.valueOrNull?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SplitSmart'),
        actions: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundImage: NetworkImage(_avatarUrl(profile.name)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hey, $displayName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            globalBalanceAsync.when(
              data: (balance) => GlobalBalanceCard(netBalance: balance),
              loading: () => const GlobalBalanceCard(netBalance: 0),
              error: (_, __) => const GlobalBalanceCard(netBalance: 0),
            ),
            if (!hasGroups && !userGroupsAsync.isLoading) const DashboardEmptyState(),
            AppButton(
              label: 'Create Group',
              onPressed: () => context.push('/groups/create'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Join Group',
              isOutlined: true,
              onPressed: () => context.push('/groups/join'),
            ),
          ],
        ),
      ),
    );
  }
}
