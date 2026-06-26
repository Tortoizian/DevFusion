import '../models/models.dart';

abstract class DatabaseRepository {
  /// Fetches the profile of a user by their ID.
  Future<UserModel> fetchUserProfile(String userId);

  /// Creates a new user profile.
  Future<void> createUserProfile(UserModel user);

  /// Updates the FCM token for a user.
  Future<void> updateFcmToken(String userId, String token);

  /// Creates a new group.
  Future<GroupModel> createGroup(
    String name,
    String creatorId, {
    GroupCategory category = GroupCategory.other,
    bool isTripMode = false,
    double? tripBudget,
  });

  /// Joins a group using an invite code. Returns the joined group's id.
  Future<String> joinGroupWithCode(String inviteCode, String userId);

  /// Fetches all members of a specific group.
  Future<List<UserModel>> fetchGroupMembers(String groupId);

  /// Fetches a single group by id.
  Future<GroupModel> fetchGroup(String groupId);

  /// Fetches all groups the user belongs to.
  Future<List<GroupModel>> fetchUserGroups(String userId);

  /// One-shot fetch of a group's expenses (for balance calculations).
  Future<List<ExpenseModel>> fetchExpensesForGroup(String groupId);

  /// One-shot fetch of a group's expense splits.
  Future<List<ExpenseSplitModel>> fetchSplitsForGroup(String groupId);

  /// One-shot fetch of a group's settlements.
  Future<List<SettlementModel>> fetchSettlementsForGroup(String groupId);

  /// Streams all expenses for a specific group.
  Stream<List<ExpenseModel>> streamExpenses(String groupId);

  /// Streams all expense splits for a specific group.
  Stream<List<ExpenseSplitModel>> streamSplits(String groupId);

  /// Streams all settlements for a specific group.
  Stream<List<SettlementModel>> streamSettlements(String groupId);

  /// Creates an expense and its associated splits in a transaction.
  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String payerId,
    required ExpenseCategory category,
    required SplitType splitType,
    required Map<String, double> userOwedAmounts, // Map of userId -> amount owed
    String? imagePath,
  });

  /// Logs a settlement transaction (initially in 'pending' status).
  Future<void> createSettlement({
    required String groupId,
    required String debtorId,
    required String creditorId,
    required double amount,
  });

  /// Marks a settlement as 'confirmed', which will resolve the debt in the DSA engine.
  Future<void> confirmSettlement(String settlementId);
}
