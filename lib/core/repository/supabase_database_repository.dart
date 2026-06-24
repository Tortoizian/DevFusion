import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'database_repository.dart';

class SupabaseDatabaseRepository implements DatabaseRepository {
  SupabaseDatabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<UserModel> fetchUserProfile(String userId) async {
    final data = await _client.from('profiles').select().eq('id', userId).single();
    return UserModel.fromJson(data);
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
  Future<void> createUserProfile(UserModel user) =>
      _unimplemented('createUserProfile');

  @override
  Future<GroupModel> createGroup(String name, String creatorId) =>
      _unimplemented('createGroup');

  @override
  Future<void> joinGroupWithCode(String inviteCode, String userId) =>
      _unimplemented('joinGroupWithCode');

  @override
  Stream<List<ExpenseModel>> streamExpenses(String groupId) =>
      _unimplemented('streamExpenses');

  @override
  Stream<List<ExpenseSplitModel>> streamSplits(String groupId) =>
      _unimplemented('streamSplits');

  @override
  Stream<List<SettlementModel>> streamSettlements(String groupId) =>
      _unimplemented('streamSettlements');

  @override
  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String payerId,
    required ExpenseCategory category,
    required SplitType splitType,
    required Map<String, double> userOwedAmounts,
  }) =>
      _unimplemented('addExpense');

  @override
  Future<void> createSettlement({
    required String groupId,
    required String debtorId,
    required String creditorId,
    required double amount,
  }) =>
      _unimplemented('createSettlement');

  @override
  Future<void> confirmSettlement(String settlementId) =>
      _unimplemented('confirmSettlement');

  Never _unimplemented(String method) {
    throw UnimplementedError('$method is not implemented yet');
  }
}
