import 'package:connection_notifier/connection_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:wiceq/notification_service.dart';

import 'HomePage.dart';
import 'QuoteProvider.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📬 Background notification: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  NotificationService.initializeNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ],
        child: ConnectionNotifier(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'IKEINSPIREME',
            theme: ThemeData(
              fontFamily: "PoetsenOne-Regular",
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              primarySwatch: Colors.blue,
            ),
            home: const HomePage(),
            builder: EasyLoading.init(),
          ),
        ));
  }
}
