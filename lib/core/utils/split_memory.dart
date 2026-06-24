import 'package:shared_preferences/shared_preferences.dart';

class SplitMemory {
  static const _keyPrefix = 'last_split_type_';

  static Future<void> saveLastSplitType(String groupId, String splitType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$groupId', splitType);
  }

  static Future<String?> getLastSplitType(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$groupId');
  }
}
