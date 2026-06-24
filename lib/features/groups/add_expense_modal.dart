import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/expense_model.dart';
import '../../core/state/group_state_notifier.dart';
import '../../core/utils/category_classifier.dart';

class AddExpenseModal extends ConsumerStatefulWidget {
  final String groupId;

  const AddExpenseModal({super.key, required this.groupId});

  @override
  ConsumerState<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends ConsumerState<AddExpenseModal> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  String? _selectedPayerId;
  String _splitType = 'equal'; // Default
  final Map<String, TextEditingController> _exactControllers = {};

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    for (final controller in _exactControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDescriptionChanged(String value) {
    setState(() {
      _selectedCategory = CategoryClassifier.classify(value);
    });
  }

  void _saveExpense() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0 || _descController.text.isEmpty || _selectedPayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final members = ref.read(groupStateNotifierProvider).members;
    final Map<String, double> splitAmounts = {};

    if (_splitType == 'equal') {
      final splitAmount = double.parse((amount / members.length).toStringAsFixed(2));
      double currentSum = 0;
      for (int i = 0; i < members.length; i++) {
        if (i == members.length - 1) {
          splitAmounts[members[i].id] = double.parse((amount - currentSum).toStringAsFixed(2));
        } else {
          splitAmounts[members[i].id] = splitAmount;
          currentSum += splitAmount;
        }
      }
    } else if (_splitType == 'exact') {
      double sum = 0;
      for (final m in members) {
        final val = double.tryParse(_exactControllers[m.id]?.text ?? '0') ?? 0.0;
        splitAmounts[m.id] = val;
        sum += val;
      }
      if ((sum - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exact amounts must sum up to total')));
        return;
      }
    }

    ref.read(groupStateNotifierProvider.notifier).addExpense(
      description: _descController.text,
      amount: amount,
      payerId: _selectedPayerId!,
      category: _selectedCategory,
      splitType: _splitType,
      userOwedAmounts: splitAmounts,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupStateNotifierProvider);
    if (_selectedPayerId == null && groupState.members.isNotEmpty) {
      _selectedPayerId = groupState.members.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              onChanged: _onDescriptionChanged,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              items: ExpenseCategory.values.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat.name));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPayerId,
              items: groupState.members.map((m) {
                return DropdownMenuItem(value: m.id, child: Text(m.name));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPayerId = val);
              },
              decoration: const InputDecoration(labelText: 'Paid By', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'equal', label: Text('Equal')),
                ButtonSegment(value: 'exact', label: Text('Exact')),
              ],
              selected: {_splitType},
              onSelectionChanged: (set) {
                setState(() => _splitType = set.first);
              },
            ),
            if (_splitType == 'exact')
              ...groupState.members.map((m) {
                _exactControllers.putIfAbsent(m.id, () => TextEditingController());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: _exactControllers[m.id],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: '${m.name} owes (₹)', border: const OutlineInputBorder()),
                  ),
                );
              }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveExpense,
              child: const Text('Save'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
