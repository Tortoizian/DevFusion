import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/expense_model.dart';
import '../../core/models/user_model.dart';
import '../../core/state/group_state_notifier.dart';
import '../../core/utils/category_classifier.dart';
import '../../core/utils/ocr_scanner_service.dart';
import '../dashboard/global_balance_provider.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _imagePath;
  bool _isSaving = false;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.camera);
    if (xfile != null) {
      setState(() => _imagePath = xfile.path);
    }
  }

  Future<void> _scanBill() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.camera);
    if (xfile != null) {
      setState(() => _imagePath = xfile.path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanning bill...')));
      final text = await OcrScannerService.scanImage(xfile.path);
      if (text != null) {
        final amount = OcrScannerService.extractAmount(text);
        if (amount != null) {
          setState(() {
            _amountController.text = amount.toStringAsFixed(2);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount extracted!')));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find amount in bill.')));
          }
        }
      }
    }
  }

  Future<void> _saveExpense() async {
    setState(() => _isSaving = true);
    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final members = ref.read(groupStateNotifierProvider).members;
      final payerId = _selectedPayerId ?? _defaultPayerId(members, ref.read(currentUserIdProvider));
      if (amount <= 0 || _descController.text.isEmpty || payerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
        setState(() => _isSaving = false);
        return;
      }

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
        setState(() => _isSaving = false);
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
        setState(() => _isSaving = false);
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
        setState(() => _isSaving = false);
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

    await ref.read(groupStateNotifierProvider.notifier).addExpense(
      description: _descController.text,
      amount: amount,
      payerId: payerId,
      category: _selectedCategory,
      splitType: SplitType.fromString(_splitType),
      userOwedAmounts: splitAmounts,
      imagePath: _imagePath,
    );

    refreshDashboardBalances(ref);

    if (mounted) {
      Navigator.pop(context);
    }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _defaultPayerId(List<UserModel> members, String? currentUserId) {
    if (members.isEmpty) return null;
    if (currentUserId != null && members.any((member) => member.id == currentUserId)) {
      return currentUserId;
    }
    return members.first.id;
  }

  Widget _splitTypeChip(String value, String label) {
    final selected = _splitType == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _splitType = value),
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupStateNotifierProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final payerId = _selectedPayerId ?? _defaultPayerId(groupState.members, currentUserId);

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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
              value: payerId,
              items: groupState.members.map((m) {
                return DropdownMenuItem(value: m.id, child: Text(m.name));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPayerId = val);
              },
              decoration: const InputDecoration(labelText: 'Paid By', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Text('Split type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _splitTypeChip('equal', 'Equal'),
                _splitTypeChip('exact', 'Exact'),
                _splitTypeChip('percentage', '%'),
                _splitTypeChip('shares', 'Shares'),
              ],
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Add Receipt'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanBill,
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('Scan Bill'),
                  ),
                ),
              ],
            ),
            if (_imagePath != null) ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Attached'),
                ],
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveExpense,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Save'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
