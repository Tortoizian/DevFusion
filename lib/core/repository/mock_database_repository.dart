import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/invite_code_generator.dart';
import 'database_repository.dart';

class MockDatabaseRepository implements DatabaseRepository {
  final _uuid = const Uuid();

  // In-memory tables
  final List<UserModel> _users = [];
  final List<GroupModel> _groups = [];
  final List<GroupMemberModel> _groupMembers = [];
  final List<ExpenseModel> _expenses = [];
  final List<ExpenseSplitModel> _expenseSplits = [];
  final List<SettlementModel> _settlements = [];

  // Stream Controllers for real-time simulation
  final Map<String, StreamController<List<ExpenseModel>>> _expenseControllers = {};
  final Map<String, StreamController<List<ExpenseSplitModel>>> _splitsControllers = {};
  final Map<String, StreamController<List<SettlementModel>>> _settlementsControllers = {};

  MockDatabaseRepository() {
    _insertSeedData();
  }

  void _insertSeedData() {
    // 1. Create Users (matching the team members in docs)
    final abhinav = UserModel(id: 'user_abhinav', name: 'Abhinav', upiId: 'abhinav@upi', createdAt: DateTime.now());
    final arnav = UserModel(id: 'user_arnav', name: 'Arnav', upiId: 'arnav@upi', createdAt: DateTime.now());
    final shammas = UserModel(id: 'user_shammas', name: 'Shammas', upiId: 'shammas@upi', createdAt: DateTime.now());
    final jyotirya = UserModel(id: 'user_jyotirya', name: 'Jyotirya', upiId: 'jyotirya@upi', createdAt: DateTime.now());

    _users.addAll([abhinav, arnav, shammas, jyotirya]);

    // 2. Create Group
    final group = GroupModel(id: 'group_hackathon', name: 'Hackathon Trip', inviteCode: 'HACK99', createdBy: 'user_abhinav', createdAt: DateTime.now());
    _groups.add(group);

    // 3. Create Group Memberships
    _groupMembers.addAll([
      GroupMemberModel(groupId: 'group_hackathon', userId: 'user_abhinav', joinedAt: DateTime.now()),
      GroupMemberModel(groupId: 'group_hackathon', userId: 'user_arnav', joinedAt: DateTime.now()),
      GroupMemberModel(groupId: 'group_hackathon', userId: 'user_shammas', joinedAt: DateTime.now()),
      GroupMemberModel(groupId: 'group_hackathon', userId: 'user_jyotirya', joinedAt: DateTime.now()),
    ]);

    // 4. Create Pizza Expense (paid by Abhinav, total: 1000)
    // Abhinav owes 250, Arnav owes 250, Shammas owes 400, Jyotirya owes 100
    final pizzaExpense = ExpenseModel(
      id: 'expense_pizza',
      groupId: 'group_hackathon',
      description: 'Domino\'s Pizza',
      amount: 1000.0,
      payerId: 'user_abhinav',
      category: ExpenseCategory.food,
      splitType: SplitType.exact,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
    _expenses.add(pizzaExpense);

    _expenseSplits.addAll([
      ExpenseSplitModel(id: 'split_1', expenseId: 'expense_pizza', userId: 'user_abhinav', amountOwed: 250.0),
      ExpenseSplitModel(id: 'split_2', expenseId: 'expense_pizza', userId: 'user_arnav', amountOwed: 250.0),
      ExpenseSplitModel(id: 'split_3', expenseId: 'expense_pizza', userId: 'user_shammas', amountOwed: 400.0),
      ExpenseSplitModel(id: 'split_4', expenseId: 'expense_pizza', userId: 'user_jyotirya', amountOwed: 100.0),
    ]);

    // 5. Create a Pending Settlement (Arnav paid Abhinav 250)
    final settlement = SettlementModel(
      id: 'settlement_arnav_abhinav',
      groupId: 'group_hackathon',
      debtorId: 'user_arnav',
      creditorId: 'user_abhinav',
      amount: 250.0,
      status: SettlementStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    );
    _settlements.add(settlement);
  }

  // Helper to get or create stream controller
  StreamController<List<T>> _getController<T>(
    String groupId,
    Map<String, StreamController<List<T>>> registry,
    List<T> Function(String) getList,
  ) {
    if (!registry.containsKey(groupId)) {
      final controller = StreamController<List<T>>.broadcast();
      registry[groupId] = controller;
      // Emit initial value
      scheduleMicrotask(() => controller.add(getList(groupId)));
    }
    return registry[groupId]!;
  }

  void _triggerUpdate(String groupId) {
    if (_expenseControllers.containsKey(groupId)) {
      _expenseControllers[groupId]!.add(_getExpensesForGroup(groupId));
    }
    if (_splitsControllers.containsKey(groupId)) {
      _splitsControllers[groupId]!.add(_getSplitsForGroup(groupId));
    }
    if (_settlementsControllers.containsKey(groupId)) {
      _settlementsControllers[groupId]!.add(_getSettlementsForGroup(groupId));
    }
  }

  List<ExpenseModel> _getExpensesForGroup(String groupId) {
    return _expenses.where((e) => e.groupId == groupId).toList();
  }

  List<ExpenseSplitModel> _getSplitsForGroup(String groupId) {
    final expenseIds = _getExpensesForGroup(groupId).map((e) => e.id).toSet();
    return _expenseSplits.where((s) => expenseIds.contains(s.expenseId)).toList();
  }

  List<SettlementModel> _getSettlementsForGroup(String groupId) {
    return _settlements.where((s) => s.groupId == groupId).toList();
  }

  @override
  Future<UserModel> fetchUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _users.firstWhere(
      (u) => u.id == userId,
      orElse: () => throw Exception('User not found'),
    );
  }

  @override
  Future<void> createUserProfile(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _users.removeWhere((u) => u.id == user.id);
    _users.add(user);
  }

  @override
  Future<void> updateFcmToken(String userId, String token) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final old = _users[index];
      _users[index] = old.copyWith(fcmToken: token);
    }
  }

  @override
  Future<GroupModel> createGroup(
    String name,
    String creatorId, {
    GroupCategory category = GroupCategory.other,
    bool isTripMode = false,
    double? tripBudget,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final inviteCode = InviteCodeGenerator.generate();
    final group = GroupModel(
      id: _uuid.v4(),
      name: name,
      inviteCode: inviteCode,
      createdBy: creatorId,
      createdAt: DateTime.now(),
      isTripMode: isTripMode,
      tripBudget: tripBudget,
    );
    _groups.add(group);

    // Auto join the creator
    _groupMembers.add(GroupMemberModel(
      groupId: group.id,
      userId: creatorId,
      joinedAt: DateTime.now(),
    ));

    return group;
  }

  @override
  Future<String> joinGroupWithCode(String inviteCode, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final group = _groups.firstWhere(
      (g) => g.inviteCode.toUpperCase() == inviteCode.toUpperCase(),
      orElse: () => throw Exception('Group with code $inviteCode not found'),
    );

    // Check if already member
    final exists = _groupMembers.any((m) => m.groupId == group.id && m.userId == userId);
    if (!exists) {
      _groupMembers.add(GroupMemberModel(
        groupId: group.id,
        userId: userId,
        joinedAt: DateTime.now(),
      ));
    }

    return group.id;
  }

  @override
  Future<List<UserModel>> fetchGroupMembers(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final memberIds = _groupMembers
        .where((m) => m.groupId == groupId)
        .map((m) => m.userId)
        .toSet();
    return _users.where((u) => memberIds.contains(u.id)).toList();
  }

  @override
  Future<List<GroupModel>> fetchUserGroups(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final groupIds = _groupMembers
        .where((m) => m.userId == userId)
        .map((m) => m.groupId)
        .toSet();
    return _groups.where((g) => groupIds.contains(g.id)).toList();
  }

  @override
  Future<List<ExpenseModel>> fetchExpensesForGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _getExpensesForGroup(groupId);
  }

  @override
  Future<List<ExpenseSplitModel>> fetchSplitsForGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _getSplitsForGroup(groupId);
  }

  @override
  Future<List<SettlementModel>> fetchSettlementsForGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _getSettlementsForGroup(groupId);
  }

  @override
  Stream<List<ExpenseModel>> streamExpenses(String groupId) {
    return _getController(groupId, _expenseControllers, _getExpensesForGroup).stream;
  }

  @override
  Stream<List<ExpenseSplitModel>> streamSplits(String groupId) {
    return _getController(groupId, _splitsControllers, _getSplitsForGroup).stream;
  }

  @override
  Stream<List<SettlementModel>> streamSettlements(String groupId) {
    return _getController(groupId, _settlementsControllers, _getSettlementsForGroup).stream;
  }

  @override
  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String payerId,
    required ExpenseCategory category,
    required SplitType splitType,
    required Map<String, double> userOwedAmounts,
    String? imagePath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final expenseId = _uuid.v4();
    final expense = ExpenseModel(
      id: expenseId,
      groupId: groupId,
      description: description,
      amount: amount,
      payerId: payerId,
      category: category,
      splitType: splitType,
      createdAt: DateTime.now(),
      receiptUrl: imagePath,
    );

    _expenses.add(expense);

    userOwedAmounts.forEach((userId, owedAmount) {
      _expenseSplits.add(ExpenseSplitModel(
        id: _uuid.v4(),
        expenseId: expenseId,
        userId: userId,
        amountOwed: owedAmount,
      ));
    });

    _triggerUpdate(groupId);
  }

  @override
  Future<void> createSettlement({
    required String groupId,
    required String debtorId,
    required String creditorId,
    required double amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final settlement = SettlementModel(
      id: _uuid.v4(),
      groupId: groupId,
      debtorId: debtorId,
      creditorId: creditorId,
      amount: amount,
      status: SettlementStatus.pending,
      createdAt: DateTime.now(),
    );

    _settlements.add(settlement);
    _triggerUpdate(groupId);
  }

  @override
  Future<void> confirmSettlement(String settlementId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _settlements.indexWhere((s) => s.id == settlementId);
    if (index != -1) {
      final old = _settlements[index];
      _settlements[index] = old.copyWith(status: SettlementStatus.confirmed);
      _triggerUpdate(old.groupId);
    }
  }
}
