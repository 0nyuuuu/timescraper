import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await initializeDateFormatting('ko_KR', null); // ✅ 이거 추가
  runApp(const TimeScraperApp());
}

