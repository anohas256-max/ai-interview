import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// 👇 УДАЛИЛИ ИМПОРТ GEMINI, ДОБАВИЛИ ДЖАНГО 👇
import '../../features/catalog/data/datasources/django_api_source.dart';
import '../../features/interview/data/repositories/interview_repo_impl.dart';
import '../../features/interview/presentation/providers/interview_provider.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/history/presentation/providers/history_provider.dart';
import '../../features/catalog/presentation/providers/catalog_provider.dart';
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart';
import 'package:sobes/core/providers/settings_provider.dart';

class AppProviders {
  static List<SingleChildWidget> getGlobalProviders() {
    // 👇 ТЕПЕРЬ МЫ ИСПОЛЬЗУЕМ ДЖАНГО КАК ИСТОЧНИК 👇
    final apiSource = DjangoApiSource();
    final repository = InterviewRepoImpl(apiSource: apiSource);

    return [
      ChangeNotifierProvider(create: (_) => InterviewProvider(repository: repository)),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ChangeNotifierProvider(create: (_) => CatalogProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ];
  }
}