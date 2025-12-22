import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/hive_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  // await HiveService.debugResetFirstRun(); // 테스트 끝나면 삭제

  await initializeDateFormatting('ko_KR', null);

  bool firebaseReady = true;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(TimeScraperApp(firebaseReady: firebaseReady));
}
