import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/destination_repository.dart';
import 'data/repositories/itinerary_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/offline_sync_repository.dart';
import 'data/repositories/review_repository.dart';
import 'data/repositories/theme_repository.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('id', null);
  } catch (e) {
    debugPrint('Locale initialization error: $e');
  }
  await SupabaseService().init();
  await ThemeRepository().init();
  await AuthRepository().init();
  await DestinationRepository().init();
  await ItineraryRepository().init();
  await NotificationRepository().init();
  await ReviewRepository().init();
  await OfflineSyncRepository().init();
  runApp(const BandungHubApp());
}
