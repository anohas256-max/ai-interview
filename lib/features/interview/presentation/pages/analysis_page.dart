import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interview_provider.dart';
import 'package:sobes/features/history/presentation/providers/history_provider.dart';
import 'package:sobes/features/history/domain/entities/session_history.dart';
import 'package:sobes/features/interview/presentation/pages/transcript_page.dart';
import 'package:sobes/core/providers/settings_provider.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAnalysis());
  }

  void _startAnalysis() {
    final provider = context.read<InterviewProvider>();
    if (provider.analysisResult != null && provider.analysisResult!.performanceText != "Ошибка анализа") return; 

    provider.generateAnalysis(
      onSuccess: () {
        if (provider.config != null) {
          final newHistory = SessionHistory(
            id: provider.config.hashCode.toString() + provider.messages.length.toString(),
            date: DateTime.now(), config: provider.config!, messages: provider.messages,
            isFinished: provider.isFinished, isFailed: provider.isFailed, analysisResult: provider.analysisResult,
          );
          context.read<HistoryProvider>().saveSession(newHistory);
        }
      }
    );
  }

  // 👇 НОВАЯ ФУНКЦИЯ: Динамический перевод оценки по баллам 👇
  String _getPerformanceLabel(double score, SettingsProvider settings) {
    if (score >= 9.0) return settings.t('perf_excellent');
    if (score >= 7.0) return settings.t('perf_good');
    if (score >= 5.0) return settings.t('perf_average');
    return settings.t('perf_poor');
  }

  // 👇 НОВАЯ ФУНКЦИЯ: Форматирование времени с учетом языка 👇
  String _formatTime(String rawTime, SettingsProvider settings) {
    bool isEng = settings.currentLanguage == 'English';
    if (isEng) return rawTime; // Для инглиша оставляем "12m" и "10s"
    
    // Для русского меняем буквы
    return rawTime.replaceAll('m', 'м').replaceAll('s', 'с');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();
    final settings = context.watch<SettingsProvider>();
    final result = provider.analysisResult;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  Text(settings.t('analysis_title'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: provider.isAnalyzing
                  ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                  : result == null 
                      ? const SizedBox.shrink()
                      : result.performanceText == "Ошибка анализа"
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                                  const SizedBox(height: 16),
                                  Text(settings.t('error_server'), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(settings.t('error_gen'), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                  const SizedBox(height: 32),
                                  ElevatedButton.icon(
                                    onPressed: _startAnalysis, icon: const Icon(Icons.refresh),
                                    label: Text(settings.t('retry_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // 👇 ЗДЕСЬ ТЕПЕРЬ ИСПОЛЬЗУЕТСЯ ДИНАМИЧЕСКИЙ ПЕРЕВОД ОЦЕНКИ 👇
                                  _buildOverallCard(result.score, _getPerformanceLabel(result.score, settings), settings, textColor, cardColor),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      // 👇 ЗДЕСЬ ТЕПЕРЬ ПЕРЕВОДЯТСЯ СЕКУНДЫ 👇
                                      Expanded(child: _buildTimeCard(Icons.bolt, _formatTime(provider.avgResponseFormatted, settings), settings.t('avg_response'), textColor, cardColor)),
                                      const SizedBox(width: 16),
                                      // 👇 И МИНУТЫ 👇
                                      Expanded(child: _buildTimeCard(Icons.schedule, _formatTime(provider.totalTimeFormatted, settings), settings.t('total_time'), textColor, cardColor)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildListCard(settings.t('key_strengths'), Icons.check_circle, Colors.green, cardColor, result.strengths, textColor),
                                  const SizedBox(height: 16),
                                  _buildListCard(settings.t('areas_improve'), Icons.cancel, Colors.redAccent, cardColor, result.weaknesses, textColor),
                                  const SizedBox(height: 24),

                                  if (result.smartRecap.isNotEmpty) ...[
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(settings.t('work_mistakes'), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 16),
                                    ...result.smartRecap.map((recap) => Container(
                                      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.lightbulb_outline, color: Colors.blueAccent, size: 24),
                                              const SizedBox(width: 12),
                                              Expanded(child: Text(recap.topic, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold))),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(recap.explanation, style: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.4)),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.menu_book, color: Colors.blueAccent, size: 20),
                                                const SizedBox(width: 12),
                                                Expanded(child: Text("${settings.t('read_this')} ${recap.recommendation}", style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4))),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                    const SizedBox(height: 24),
                                  ],

                                  SizedBox(
                                    width: double.infinity, height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TranscriptPage())),
                                      icon: const Icon(Icons.description),
                                      label: Text(settings.t('view_chat'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(backgroundColor: cardColor, foregroundColor: textColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  SizedBox(
                                    width: double.infinity, height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        provider.clearChat();
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      },
                                      icon: const Icon(Icons.exit_to_app),
                                      label: Text(settings.t('finish_exit'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallCard(double score, String text, SettingsProvider settings, Color? textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(settings.t('overall_perf'), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(text, style: TextStyle(color: textColor, fontSize: 16)),
            ],
          ),
          Container(
            width: 60, height: 60, alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2)),
            child: Text(score.toString(), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildTimeCard(IconData icon, String value, String label, Color? textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.grey, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, IconData headerIcon, Color accentColor, Color cardColor, List<String> items, Color? textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: accentColor, size: 24),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(headerIcon == Icons.check_circle ? Icons.check : Icons.close, color: accentColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item, style: TextStyle(color: textColor, fontSize: 15, height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}