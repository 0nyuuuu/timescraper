import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const TimeScraperApp());
}

