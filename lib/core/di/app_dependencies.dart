import '../../features/encyclopedia/data/datasources/encyclopedia_local_datasource.dart';
import '../../features/encyclopedia/data/repositories/encyclopedia_repository_impl.dart';
import '../../features/encyclopedia/domain/repositories/encyclopedia_repository.dart';

class AppDependencies {
  AppDependencies._();

  static late final EncyclopediaLocalDataSource _encyclopediaDataSource;
  static late final EncyclopediaRepository _encyclopediaRepo;

  static Future<void> init() async {
    _encyclopediaDataSource = EncyclopediaLocalDataSource();
    _encyclopediaRepo = EncyclopediaRepositoryImpl(_encyclopediaDataSource);
  }

  static EncyclopediaRepository get encyclopediaRepo => _encyclopediaRepo;
}
