import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interview_provider.dart';
import 'package:sobes/features/history/presentation/providers/history_provider.dart';
import 'package:sobes/features/history/domain/entities/session_history.dart';
import 'package:sobes/features/interview/presentation/pages/transcript_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis(); 
    });
  }

  void _startAnalysis() {
    final provider = context.read<InterviewProvider>();
    
    if (provider.analysisResult != null && provider.analysisResult!.performanceText != "Ошибка анализа") {
      return; 
    }

    provider.generateAnalysis(
      onSuccess: () {
        // 👇 ИСПРАВЛЕННОЕ СОХРАНЕНИЕ В ИСТОРИЮ 👇
        if (provider.config != null) {
          final newHistory = SessionHistory(
            id: provider.config.hashCode.toString() + provider.messages.length.toString(),
            date: DateTime.now(),
            config: provider.config!,
            messages: provider.messages,
            isFinished: provider.isFinished,
            isFailed: provider.isFailed,
            analysisResult: provider.analysisResult,
          );
          
          context.read<HistoryProvider>().saveSession(newHistory);
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();
    final result = provider.analysisResult;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context), 
                  ),
                  const SizedBox(width: 8),
                  const Text('Session Analysis', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            Expanded(
              child: provider.isAnalyzing
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : result == null 
                      ? const SizedBox.shrink()
                      : result.performanceText == "Ошибка анализа"
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                                  const SizedBox(height: 16),
                                  const Text("Ошибка связи с сервером", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  const Text("Не удалось сгенерировать итоги.", style: TextStyle(color: Colors.white54, fontSize: 14)),
                                  const SizedBox(height: 32),
                                  ElevatedButton.icon(
                                    onPressed: _startAnalysis, 
                                    icon: const Icon(Icons.refresh, color: Colors.black),
                                    label: const Text("Повторить попытку", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildOverallCard(result.score, result.performanceText),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: _buildTimeCard(Icons.bolt, provider.avgResponseFormatted, "AVG. RESPONSE")),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildTimeCard(Icons.schedule, provider.totalTimeFormatted, "TOTAL TIME")),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildListCard("Key Strengths", Icons.check_circle, Colors.green, const Color(0xFF1E2E22), result.strengths),
                                  const SizedBox(height: 16),
                                  _buildListCard("Areas to Improve", Icons.cancel, Colors.redAccent, const Color(0xFF2E1C1C), result.weaknesses),
                                  const SizedBox(height: 24),

                                  if (result.smartRecap.isNotEmpty) ...[
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text("📚 Работа над ошибками", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 16),
                                    ...result.smartRecap.map((recap) => Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF121212),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.lightbulb_outline, color: Colors.blueAccent, size: 24),
                                              const SizedBox(width: 12),
                                              Expanded(child: Text(recap.topic, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(recap.explanation, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4)),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.menu_book, color: Colors.blueAccent, size: 20),
                                                const SizedBox(width: 12),
                                                Expanded(child: Text("Что почитать: ${recap.recommendation}", style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4))),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                    const SizedBox(height: 24),
                                  ],

                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context, 
                                          MaterialPageRoute(builder: (_) => const TranscriptPage())
                                        );
                                      },
                                      icon: const Icon(Icons.description, color: Colors.white),
                                      label: const Text("Смотреть весь чат", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1C1C1E),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        provider.clearChat();
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      },
                                      icon: const Icon(Icons.exit_to_app, color: Colors.black),
                                      label: const Text("Завершить и выйти", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
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

  Widget _buildOverallCard(double score, String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("OVERALL PERFORMANCE", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(text, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
          Container(
            width: 60, height: 60, alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
            child: Text(score.toString(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildTimeCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFF2A2A2C), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, IconData headerIcon, Color accentColor, Color bgColor, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212), borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: accentColor, size: 24),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    Expanded(child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}