import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/dio_client.dart';
import '../services/favorites_storage.dart';
import '../services/wallet_storage.dart';
import '../../features/iam/domain/auth_repository.dart';
import '../../features/iam/infrastructure/auth_remote_data_source.dart';
import '../../features/iam/infrastructure/auth_repository_impl.dart';
import '../../features/iam/application/auth_notifier.dart';
import '../../features/planning/infrastructure/shopping_list_remote_data_source.dart';
import '../../features/planning/infrastructure/comparison_remote_data_source.dart';
import '../../features/planning/infrastructure/preferences_remote_data_source.dart';
import '../../features/planning/infrastructure/store_remote_data_source.dart';
import '../../features/planning/infrastructure/product_catalog_service.dart';
import '../../features/journey/infrastructure/shopping_journey_remote_data_source.dart';
import '../../features/experience/infrastructure/experience_remote_data_source.dart';
import '../../features/experience/infrastructure/mlkit_ocr_scanner_impl.dart';
import '../../features/experience/domain/ocr_scanner_interface.dart';
import '../../features/notifications/infrastructure/notifications_remote_data_source.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(),
    ),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(secureStorage: sl()),
  );

  sl.registerLazySingleton<FavoritesStorage>(
    () => FavoritesStorage(sl()),
  );

  sl.registerLazySingleton<WalletStorage>(
    () => WalletStorage(sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ShoppingListRemoteDataSource>(
    () => ShoppingListRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<ComparisonRemoteDataSource>(
    () => ComparisonRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<PreferencesRemoteDataSource>(
    () => PreferencesRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<StoreRemoteDataSource>(
    () => StoreRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<ProductCatalogService>(
    () => ProductCatalogService(sl(), sl(), sl()),
  );

  sl.registerLazySingleton<ShoppingJourneyRemoteDataSource>(
    () => ShoppingJourneyRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<ExperienceRemoteDataSource>(
    () => ExperienceRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<OcrScannerInterface>(
    () => MlKitOcrScannerImpl(),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );

  sl.registerLazySingleton<AuthNotifier>(() => AuthNotifier(sl()));
}
