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
  final Map<String, TextEditingController> _percentControllers = {};
  final Map<String, TextEditingController> _shareControllers = {};

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    for (final controller in _exactControllers.values) {
      controller.dispose();
    }
    for (final controller in _percentControllers.values) {
      controller.dispose();
    }
    for (final controller in _shareControllers.values) {
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
    } else if (_splitType == 'percentage') {
      double sumPercent = 0;
      for (final m in members) {
        final pct = double.tryParse(_percentControllers[m.id]?.text ?? '0') ?? 0.0;
        sumPercent += pct;
      }
      if ((sumPercent - 100).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Percentages must sum up to 100')));
        return;
      }
      double currentSum = 0;
      for (int i = 0; i < members.length; i++) {
        if (i == members.length - 1) {
          splitAmounts[members[i].id] = double.parse((amount - currentSum).toStringAsFixed(2));
        } else {
          final pct = double.tryParse(_percentControllers[members[i].id]?.text ?? '0') ?? 0.0;
          final split = double.parse((amount * pct / 100).toStringAsFixed(2));
          splitAmounts[members[i].id] = split;
          currentSum += split;
        }
      }
    } else if (_splitType == 'shares') {
      double sumShares = 0;
      for (final m in members) {
        final share = double.tryParse(_shareControllers[m.id]?.text ?? '1') ?? 0.0;
        sumShares += share;
      }
      if (sumShares <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Total shares must be greater than 0')));
        return;
      }
      double currentSum = 0;
      for (int i = 0; i < members.length; i++) {
        if (i == members.length - 1) {
          splitAmounts[members[i].id] = double.parse((amount - currentSum).toStringAsFixed(2));
        } else {
          final share = double.tryParse(_shareControllers[members[i].id]?.text ?? '1') ?? 0.0;
          final split = double.parse((amount * share / sumShares).toStringAsFixed(2));
          splitAmounts[members[i].id] = split;
          currentSum += split;
        }
      }
    }

    ref.read(groupStateNotifierProvider.notifier).addExpense(
      description: _descController.text,
      amount: amount,
      payerId: _selectedPayerId!,
      category: _selectedCategory,
      splitType: SplitType.fromString(_splitType),
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
                ButtonSegment(value: 'percentage', label: Text('%')),
                ButtonSegment(value: 'shares', label: Text('Shares')),
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
            if (_splitType == 'percentage')
              ...groupState.members.map((m) {
                _percentControllers.putIfAbsent(m.id, () => TextEditingController());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: _percentControllers[m.id],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: '${m.name} owes (%)', border: const OutlineInputBorder()),
                  ),
                );
              }),
            if (_splitType == 'shares')
              ...groupState.members.map((m) {
                _shareControllers.putIfAbsent(m.id, () => TextEditingController(text: '1'));
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: _shareControllers[m.id],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: '${m.name} shares', border: const OutlineInputBorder()),
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
