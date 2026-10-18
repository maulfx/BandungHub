import 'package:flutter/material.dart';

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
