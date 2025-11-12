import 'package:connection_notifier/connection_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import 'HomePage.dart';
import 'QuoteProvider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
            title: 'Wise Christian Quotes',
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
