import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'database_repository.dart';

class SupabaseDatabaseRepository implements DatabaseRepository {
  SupabaseDatabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static final _random = Random();
  static const _inviteCharset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  @override
  Future<UserModel> fetchUserProfile(String userId) async {
    final data = await _client.from('profiles').select().eq('id', userId).single();
    return UserModel.fromJson(data);
  }

  @override
  Future<List<GroupModel>> fetchUserGroups(String userId) async {
    final rows = await _client
        .from('group_members')
        .select('groups(*)')
        .eq('user_id', userId);

    return rows
        .map((row) => row['groups'])
        .whereType<Map<String, dynamic>>()
        .map(GroupModel.fromJson)
        .toList();
  }

  @override
  Future<List<ExpenseModel>> fetchExpensesForGroup(String groupId) async {
    final rows = await _client.from('expenses').select().eq('group_id', groupId);
    return rows.map((row) => ExpenseModel.fromJson(row)).toList();
  }

  @override
  Future<List<ExpenseSplitModel>> fetchSplitsForGroup(String groupId) async {
    return _fetchSplitsForGroup(groupId);
  }

  @override
  Future<List<SettlementModel>> fetchSettlementsForGroup(String groupId) async {
    final rows = await _client.from('settlements').select().eq('group_id', groupId);
    return rows.map((row) => SettlementModel.fromJson(row)).toList();
  }

  @override
  Future<List<UserModel>> fetchGroupMembers(String groupId) async {
    final rows = await _client
        .from('group_members')
        .select('user_id, profiles(*)')
        .eq('group_id', groupId);

    return rows
        .map((row) => row['profiles'])
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  @override
  Future<void> createUserProfile(UserModel user) async {
    await _client.from('profiles').upsert({
      'id': user.id,
      'name': user.name,
      'upi_id': user.upiId,
      'avatar_url': user.avatarUrl,
    });
  }

  @override
  Future<GroupModel> createGroup(String name, String creatorId) async {
    PostgrestException? lastError;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final inviteCode = _generateInviteCode();
        final data = await _client
            .from('groups')
            .insert({
              'name': name,
              'invite_code': inviteCode,
              'created_by': creatorId,
              'category': 'other',
            })
            .select()
            .single();

        await _client.from('group_members').insert({
          'group_id': data['id'],
          'user_id': creatorId,
        });

        return GroupModel.fromJson(data);
      } on PostgrestException catch (e) {
        lastError = e;
        if (e.code == '23505' && attempt < 2) continue;
        rethrow;
      }
    }

    throw lastError ?? StateError('Failed to generate unique invite code');
  }

  @override
  Future<void> joinGroupWithCode(String inviteCode, String userId) async {
    final group = await _client
        .from('groups')
        .select()
        .eq('invite_code', inviteCode.toUpperCase())
        .single();

    await _client.from('group_members').upsert({
      'group_id': group['id'],
      'user_id': userId,
    });
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
  }) async {
    final expenseRow = await _client
        .from('expenses')
        .insert({
          'group_id': groupId,
          'description': description,
          'amount': amount,
          'payer_id': payerId,
          'category': category.name,
          'split_type': splitType.name,
        })
        .select()
        .single();

    if (userOwedAmounts.isNotEmpty) {
      final splits = userOwedAmounts.entries
          .map(
            (entry) => {
              'expense_id': expenseRow['id'],
              'user_id': entry.key,
              'amount_owed': entry.value,
            },
          )
          .toList();

      await _client.from('expense_splits').insert(splits);
    }
  }

  @override
  Future<void> createSettlement({
    required String groupId,
    required String debtorId,
    required String creditorId,
    required double amount,
  }) async {
    await _client.from('settlements').insert({
      'group_id': groupId,
      'debtor_id': debtorId,
      'creditor_id': creditorId,
      'amount': amount,
      'status': SettlementStatus.pending.name,
    });
  }

  @override
  Future<void> confirmSettlement(String settlementId) async {
    await _client
        .from('settlements')
        .update({'status': SettlementStatus.confirmed.name})
        .eq('id', settlementId);
  }

  @override
  Stream<List<ExpenseModel>> streamExpenses(String groupId) {
    return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map(
          (rows) => rows.map((row) => ExpenseModel.fromJson(row)).toList(),
        );
  }

  @override
  Stream<List<ExpenseSplitModel>> streamSplits(String groupId) {
    return _combinedRealtimeStream(
      fetch: () => _fetchSplitsForGroup(groupId),
      watches: [
        _client.from('expenses').stream(primaryKey: ['id']).eq('group_id', groupId),
        _client.from('expense_splits').stream(primaryKey: ['id']),
      ],
    );
  }

  @override
  Stream<List<SettlementModel>> streamSettlements(String groupId) {
    return _client
        .from('settlements')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map(
          (rows) => rows.map((row) => SettlementModel.fromJson(row)).toList(),
        );
  }

  Future<List<ExpenseSplitModel>> _fetchSplitsForGroup(String groupId) async {
    final expenses = await _client.from('expenses').select('id').eq('group_id', groupId);
    final expenseIds = expenses.map((row) => row['id'] as String).toList();
    if (expenseIds.isEmpty) return [];

    final rows = await _client.from('expense_splits').select().inFilter('expense_id', expenseIds);
    return rows.map((row) => ExpenseSplitModel.fromJson(row)).toList();
  }

  Stream<List<T>> _combinedRealtimeStream<T>({
    required Future<List<T>> Function() fetch,
    required List<Stream<List<Map<String, dynamic>>>> watches,
  }) {
    final subscriptions = <StreamSubscription<List<Map<String, dynamic>>>>[];

    return Stream<List<T>>.multi((controller) async {
      Future<void> emitLatest() async {
        try {
          controller.add(await fetch());
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      }

      await emitLatest();

      for (final watch in watches) {
        subscriptions.add(watch.listen((_) => emitLatest(), onError: controller.addError));
      }

      controller.onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      };
    });
  }

  String _generateInviteCode() {
    return List.generate(
      6,
      (_) => _inviteCharset[_random.nextInt(_inviteCharset.length)],
    ).join();
  }

}
