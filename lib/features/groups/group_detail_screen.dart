import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/models/settlement_model.dart';
import '../../core/state/group_state.dart';
import '../../core/state/group_state_notifier.dart';
import '../../core/utils/settlement_memo.dart';
import '../../core/utils/upi_launcher.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/balance_chip.dart';
import 'add_expense_modal.dart';
import 'widgets/debt_graph_widget.dart';

import 'package:fl_chart/fl_chart.dart';
import '../../core/models/expense_model.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  int _currentIndex = 0;
  ExpenseCategory? _historyFilterCategory;
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
        return _buildHistoryTab(groupState);
      case 3:
        return _buildAnalyticsTab(groupState);
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
        _buildPendingSettlements(groupState),
        const SizedBox(height: 16),
        _buildLeaderboard(groupState),
        const SizedBox(height: 16),
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
                  final debtorName = _memberName(groupState, transfer.fromUserId);
                  final creditorName = _memberName(groupState, transfer.toUserId);
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
                            '$debtorName pays $creditorName',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '₹${transfer.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => _showSettleSheet(
                            transfer.fromUserId,
                            transfer.toUserId,
                            transfer.amount,
                            debtorName,
                            creditorName,
                            groupState,
                          ),
                          child: const Text('Settle Up'),
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

  Widget _buildPendingSettlements(GroupState groupState) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final pendingSettlements = groupState.settlements.where((settlement) {
      return settlement.status == SettlementStatus.pending &&
          settlement.creditorId == currentUserId;
    }).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pending confirmations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (pendingSettlements.isEmpty)
            Text(
              'No pending settlements for you.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...pendingSettlements.map((settlement) {
              final debtorName = _memberName(groupState, settlement.debtorId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      child: Icon(Icons.pending_actions, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$debtorName marked ₹${settlement.amount.toStringAsFixed(2)} as paid',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(groupStateNotifierProvider.notifier)
                          .confirmSettlement(settlement.id),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
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

  Widget _buildLeaderboard(GroupState groupState) {
    final balances = groupState.netBalances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (balances.isEmpty || balances.every((e) => e.value.abs() < 0.01)) {
      return const SizedBox.shrink();
    }

    final mostOwed = balances.first;
    final owesMost = balances.last;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Leaderboard', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (mostOwed.value > 0.01)
            ListTile(
              leading: const CircleAvatar(child: Text('🏆')),
              title: Text('${_memberName(groupState, mostOwed.key)} is owed most'),
              subtitle: Text('₹${mostOwed.value.toStringAsFixed(2)}'),
            ),
          if (owesMost.value < -0.01)
            ListTile(
              leading: const CircleAvatar(child: Text('💸')),
              title: Text('${_memberName(groupState, owesMost.key)} owes most'),
              subtitle: Text('₹${owesMost.value.abs().toStringAsFixed(2)}'),
            ),
        ],
      ),
    );
  }

  Future<void> _showSettleSheet(
    String debtorId,
    String creditorId,
    double amount,
    String debtorName,
    String creditorName,
    GroupState groupState,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _SettleUpSheet(
          debtorId: debtorId,
          creditorId: creditorId,
          amount: amount,
          debtorName: debtorName,
          creditorName: creditorName,
          groupName: groupState.groupId ?? 'group',
          expenseCount: groupState.expenses.length,
        );
      },
    );
  }

  Widget _buildHistoryTab(groupState) {
    if (groupState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sortedExpenses = List<ExpenseModel>.from(groupState.expenses)
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    final filtered = sortedExpenses.where((e) {
      if (_historyFilterCategory != null && e.category != _historyFilterCategory) return false;
      return true;
    }).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _historyFilterCategory == null,
                onSelected: (_) => setState(() => _historyFilterCategory = null),
              ),
              const SizedBox(width: 8),
              ...ExpenseCategory.values.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(cat.name.toUpperCase()),
                  selected: _historyFilterCategory == cat,
                  onSelected: (_) => setState(() => _historyFilterCategory = cat),
                ),
              )),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No expenses match filters.'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final expense = filtered[index];
                    final payer = groupState.members.firstWhere(
                      (m) => m.id == expense.payerId,
                      orElse: () => groupState.members.first,
                    );
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.history)),
                        title: Text(expense.description),
                        subtitle: Text('${payer.name} paid ₹${expense.amount.toStringAsFixed(2)}'),
                        trailing: Text(
                          expense.createdAt?.toString().split(' ')[0] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(GroupState groupState) {
    if (groupState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (groupState.expenses.isEmpty) {
      return const Center(child: Text('No data for analytics yet.'));
    }

    final categoryTotals = <ExpenseCategory, double>{};
    for (final expense in groupState.expenses) {
      if (expense.category != ExpenseCategory.settlement) {
        categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
      }
    }

    if (categoryTotals.isEmpty) {
      return const Center(child: Text('No expenses to analyze.'));
    }

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    final categoryColors = {
      ExpenseCategory.food: Colors.orange,
      ExpenseCategory.travel: Colors.blue,
      ExpenseCategory.entertainment: Colors.purple,
      ExpenseCategory.shopping: Colors.pink,
      ExpenseCategory.accommodation: Colors.indigo,
      ExpenseCategory.utilities: Colors.amber,
      ExpenseCategory.other: Colors.grey,
    };

    final sections = categoryTotals.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: categoryColors[entry.key] ?? Colors.grey,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Category Spending', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...categoryTotals.entries.map((entry) {
            return ListTile(
              leading: CircleAvatar(backgroundColor: categoryColors[entry.key]),
              title: Text(entry.key.name.toUpperCase()),
              trailing: Text('₹${entry.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }),
        ],
      ),
    );
  }
}


class _SettleUpSheet extends ConsumerStatefulWidget {
  final String debtorId;
  final String creditorId;
  final double amount;
  final String debtorName;
  final String creditorName;
  final String groupName;
  final int expenseCount;

  const _SettleUpSheet({
    required this.debtorId,
    required this.creditorId,
    required this.amount,
    required this.debtorName,
    required this.creditorName,
    required this.groupName,
    required this.expenseCount,
  });

  @override
  ConsumerState<_SettleUpSheet> createState() => _SettleUpSheetState();
}

class _SettleUpSheetState extends ConsumerState<_SettleUpSheet> {
  bool _launching = false;
  bool _launched = false;
  bool _saving = false;

  Future<void> _launchUpi() async {
    setState(() => _launching = true);
    final payee = _resolvePayee();
    final launched = await UpiLauncher.launchSettlement(
      vpa: payee.upiId,
      payeeName: widget.creditorName,
      amount: widget.amount,
      memo: SettlementMemo.build(
        groupName: widget.groupName,
        expenseCount: widget.expenseCount,
      ),
    );

    if (!mounted) return;
    setState(() {
      _launching = false;
      _launched = launched;
    });

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI is available on Android only')),
      );
    }
  }

  UserModel _resolvePayee() {
    return ref.read(groupStateNotifierProvider).members.firstWhere(
          (member) => member.id == widget.creditorId,
          orElse: () => throw StateError('Payee not found'),
        );
  }

  Future<void> _markAsPaid() async {
    setState(() => _saving = true);
    try {
      await ref.read(groupStateNotifierProvider.notifier).settleDebt(
            debtorId: widget.debtorId,
            creditorId: widget.creditorId,
            amount: widget.amount,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settlement marked as paid')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mark as paid: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'TEST MODE — Sandbox UPI',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.debtorName} pays ${widget.creditorName}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '₹${widget.amount.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'After returning from UPI, tap Mark as Paid to create a pending settlement for confirmation.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _launching ? null : _launchUpi,
              child: _launching ? const CircularProgressIndicator() : const Text('Open UPI'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _launched && !_saving ? _markAsPaid : null,
              child: _saving ? const CircularProgressIndicator() : const Text('Mark as Paid'),
            ),
          ],
        ),
      ),
    );
  }
}
