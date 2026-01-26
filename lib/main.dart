import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/services/storage_service.dart';
import 'data/services/api_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/data_service.dart';
import 'data/services/transcript_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/progress_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = await StorageService.getInstance();
  final apiService = await ApiService.getInstance();
  final authService = AuthService(apiService, storageService);
  final dataService = DataService.getInstance();
  final transcriptService = TranscriptService.getInstance();

  // Load data
  await Future.wait([
    dataService.loadData(),
    transcriptService.loadTranscripts(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(authService, dataService, storageService),
        ),
      ],
      child: const TopikGoApp(),
    ),
  );
}
