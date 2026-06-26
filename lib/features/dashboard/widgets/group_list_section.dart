import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/group_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/balance_chip.dart';

class GroupListSection extends StatelessWidget {
  final List<GroupModel> groups;
  final Map<String, double> balancesByGroupId;

  const GroupListSection({
    super.key,
    required this.groups,
    this.balancesByGroupId = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your groups',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...groups.map((group) {
          final balance = balancesByGroupId[group.id] ?? 0.0;
          final settled = balance.abs() < 0.01;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () => context.push('/groups/${group.id}'),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          AppColors.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      group.isTripMode ? Icons.flight_takeoff : Icons.groups,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.isTripMode ? 'Trip mode' : (settled ? 'No outstanding balance' : 'Tap to view details'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  BalanceChip(balance: balance),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
