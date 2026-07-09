import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/dio_client.dart';
import '../../features/iam/domain/auth_repository.dart';
import '../../features/iam/infrastructure/auth_remote_data_source.dart';
import '../../features/iam/infrastructure/auth_repository_impl.dart';
import '../../features/iam/application/auth_notifier.dart';
import '../../features/planning/infrastructure/shopping_list_remote_data_source.dart';
import '../../features/journey/infrastructure/shopping_journey_remote_data_source.dart';
import '../../features/experience/infrastructure/experience_remote_data_source.dart';
import '../../features/planning/infrastructure/comparison_remote_data_source.dart';

final sl = GetIt.instance; // sl stands for Service Locator

Future<void> init() async {
  // 1. Core Services & External
  
  // Secure Storage
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    ),
  );

  // Network / Dio Client
  sl.registerLazySingleton<DioClient>(
    () => DioClient(secureStorage: sl()),
  );

  // 2. Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  
  sl.registerLazySingleton<ShoppingListRemoteDataSource>(
    () => ShoppingListRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<ComparisonRemoteDataSource>(
    () => ComparisonRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<ShoppingJourneyRemoteDataSource>(
    () => ShoppingJourneyRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<ExperienceRemoteDataSource>(
    () => ExperienceRemoteDataSource(sl()),
  );

  // 3. Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );

  // 4. Use Cases
  // (We are calling the repository directly from the notifier for now, but we can add use cases here later)

  // 5. State Managers (Blocs/Notifiers)
  sl.registerFactory(() => AuthNotifier(sl()));
}
