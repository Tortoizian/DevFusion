import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/group_state_notifier.dart';
import 'add_expense_modal.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  int _currentIndex = 0;

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
        title: Text(groupState.group?.name ?? 'Loading...'),
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
    switch (_currentIndex) {
      case 0:
        return const Center(child: Text('Expenses Tab'));
      case 1:
        return const Center(child: Text('Balances Tab'));
      case 2:
        return const Center(child: Text('History Tab'));
      case 3:
        return const Center(child: Text('Analytics Tab'));
      default:
        return const SizedBox.shrink();
    }
  }
}
