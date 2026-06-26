import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../repository/database_repository.dart';

class PushNotificationService {
  static Future<void> initialize(DatabaseRepository db, String userId) async {
    try {
      await Firebase.initializeApp();
      
      final messaging = FirebaseMessaging.instance;
      
      // Request permissions for iOS
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null) {
        await db.updateFcmToken(userId, token);
      }

      messaging.onTokenRefresh.listen((newToken) {
        db.updateFcmToken(userId, newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Handle foreground messages if needed, like showing a local notification
      });
    } catch (e) {
      print('Firebase Initialization Failed: $e');
    }
  }
}
