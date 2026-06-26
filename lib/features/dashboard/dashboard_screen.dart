import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/profile_provider.dart';
import '../../core/models/user_model.dart';
import '../../shared/widgets/app_button.dart';
import 'global_balance_provider.dart';
import 'widgets/dashboard_empty_state.dart';
import 'widgets/global_balance_card.dart';
import 'widgets/group_list_section.dart';

import '../../core/state/group_state_notifier.dart';
import '../../core/utils/push_notification_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _avatarUrl(String name) {
    return UserModel(
      id: '',
      name: name,
      upiId: '',
      createdAt: DateTime.now(),
    ).avatarUrl.replaceFirst('/svg?', '/png?');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = ref.read(currentProfileProvider).valueOrNull;
      if (profile != null) {
        await PushNotificationService.initialize(
          ref.read(databaseRepositoryProvider),
          profile.id,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final displayName = profile?.name ?? 'there';
    final globalBalanceAsync = ref.watch(globalBalanceProvider);
    final groupSummariesAsync = ref.watch(userGroupSummariesProvider);
    final hasGroups = groupSummariesAsync.valueOrNull?.isNotEmpty ?? false;

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
            const SizedBox(height: 16),
            groupSummariesAsync.when(
              data: (summaries) {
                if (summaries.isEmpty) {
                  return const DashboardEmptyState();
                }

                return GroupListSection(
                  groups: summaries.map((summary) => summary.group).toList(),
                  balancesByGroupId: {
                    for (final summary in summaries) summary.group.id: summary.netBalance,
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Could not load your groups. Pull to refresh or try again.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (hasGroups) const SizedBox(height: 8),
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
