import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/hive_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  // await HiveService.debugResetFirstRun(); // 테스트 끝나면 삭제

  await initializeDateFormatting('ko_KR', null);

  // ✅ Firebase 미설정 상태에서도 앱이 죽지 않게 처리
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(TimeScraperApp(firebaseReady: firebaseReady));
}
