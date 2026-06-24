import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/group_state.dart';
import '../../core/state/group_state_notifier.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/balance_chip.dart';
import 'add_expense_modal.dart';
import 'widgets/debt_graph_widget.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  int _currentIndex = 0;
  bool _showSimplifiedGraph = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupStateNotifierProvider.notifier).loadGroup(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(groupState.groupId != null ? 'Group Details' : 'Loading...'),
        actions: [
          if (groupState.members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: groupState.members.take(3).map((m) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.0),
                    child: CircleAvatar(radius: 12, child: Icon(Icons.person, size: 16)),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Balances'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Analytics'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => AddExpenseModal(groupId: widget.groupId),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    final groupState = ref.watch(groupStateNotifierProvider);
    switch (_currentIndex) {
      case 0:
        return _buildExpensesTab(groupState);
      case 1:
        return _buildBalancesTab(groupState);
      case 2:
        return const Center(child: Text('History Tab'));
      case 3:
        return const Center(child: Text('Analytics Tab'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildExpensesTab(groupState) {
    if (groupState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (groupState.expenses.isEmpty) {
      return const Center(child: Text('No expenses yet.'));
    }
    return ListView.builder(
      itemCount: groupState.expenses.length,
      itemBuilder: (context, index) {
        final expense = groupState.expenses[index];
        final payer = groupState.members.firstWhere(
          (m) => m.id == expense.payerId,
          orElse: () => groupState.members.first,
        );
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.receipt)),
            title: Text(expense.description),
            subtitle: Text('${payer.name} paid ₹${expense.amount.toStringAsFixed(2)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(expense.category.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(expense.splitType.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalancesTab(GroupState groupState) {
    if (groupState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groupState.members.isEmpty) {
      return const Center(child: Text('No balances yet.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Net balances',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ...groupState.members.map((member) {
                final balance = groupState.netBalances[member.id] ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.person, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          member.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      BalanceChip(balance: balance),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DebtGraphWidget(
          groupState: groupState,
          showSimplified: _showSimplifiedGraph,
          onToggleSimplify: () {
            setState(() {
              _showSimplifiedGraph = !_showSimplifiedGraph;
            });
          },
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Simplified transfers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (groupState.simplifiedDebts.isEmpty)
                Text(
                  'Nothing to settle right now.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...groupState.simplifiedDebts.map((transfer) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.swap_horiz, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_memberName(groupState, transfer.fromUserId)} pays ${_memberName(groupState, transfer.toUserId)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '₹${transfer.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  String _memberName(GroupState groupState, String userId) {
    return groupState.members
        .firstWhere(
          (member) => member.id == userId,
          orElse: () => groupState.members.first,
        )
        .name;
  }
}
