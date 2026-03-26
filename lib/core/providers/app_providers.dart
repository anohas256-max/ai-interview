import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../features/interview/data/datasources/gemini_api_source.dart';
import '../../features/interview/data/repositories/interview_repo_impl.dart';
import '../../features/interview/presentation/providers/interview_provider.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/history/presentation/providers/history_provider.dart';
import '../../features/catalog/presentation/providers/catalog_provider.dart';
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart';

class AppProviders {
  // Этот метод собирает все зависимости и пульты в один список
  static List<SingleChildWidget> getGlobalProviders() {
    // 1. Инициализируем нижний слой (API и Репозитории)
    final apiSource = GeminiApiSource();
    final repository = InterviewRepoImpl(apiSource: apiSource);

    // 2. Отдаем список Провайдеров
    return [
      ChangeNotifierProvider(create: (_) => InterviewProvider(repository: repository)),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ChangeNotifierProvider(create: (_) => CatalogProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ];
  }
}