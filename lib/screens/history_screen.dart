import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skin_analyzer/models/skin_analysis.dart';
import 'package:skin_analyzer/providers/analysis_provider.dart';
import 'package:skin_analyzer/widgets/loading_overlay.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Загружаем историю при первом открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalysisProvider>(context, listen: false).loadAnalysisHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysisProvider = Provider.of<AnalysisProvider>(context);
    final analyses = analysisProvider.analyses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История анализов'),
      ),
      body: LoadingOverlay(
        isLoading: analysisProvider.isLoading,
        child: analyses.isEmpty
            ? _buildEmptyHistory()
            : _buildHistoryList(analyses),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'История анализов пуста',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Сделайте анализ кожи или косметики, \nи результаты появятся здесь',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<SkinAnalysis> analyses) {
    // Группировка анализов по месяцам
    final Map<String, List<SkinAnalysis>> groupedAnalyses = {};
    final DateFormat monthFormatter = DateFormat('MMMM yyyy');

    for (var analysis in analyses) {
      final monthKey = monthFormatter.format(analysis.analysisDate);
      if (!groupedAnalyses.containsKey(monthKey)) {
        groupedAnalyses[monthKey] = [];
      }
      groupedAnalyses[monthKey]!.add(analysis);
    }

    // Сортировка ключей по убыванию дат
    final sortedMonths = groupedAnalyses.keys.toList()
      ..sort((a, b) {
        final aDate = monthFormatter.parse(a);
        final bDate = monthFormatter.parse(b);
        return bDate.compareTo(aDate);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMonths.length,
      itemBuilder: (context, index) {
        final month = sortedMonths[index];
        final monthlyAnalyses = groupedAnalyses[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                month,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...monthlyAnalyses.map((analysis) => _buildAnalysisItem(analysis)),
          ],
        );
      },
    );
  }

  Widget _buildAnalysisItem(SkinAnalysis analysis) {
    final dateFormatter = DateFormat('d MMMM, HH:mm');
    final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);

    return Dismissible(
      key: Key('analysis_${analysis.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Запрашиваем подтверждение удаления
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Удалить анализ?'),
              content: const Text('Этот анализ будет удален навсегда.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        // Удаляем анализ
        analysisProvider.deleteAnalysis(analysis.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Анализ удален'),
            action: SnackBarAction(
              label: 'Отменить',
              onPressed: () {
                // Загружаем историю заново
                analysisProvider.loadAnalysisHistory();
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            // Переход к детальной информации об анализе
            analysisProvider.getAnalysisDetails(analysis.id);
            // TODO: Реализовать переход к экрану деталей анализа
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Миниатюра изображения
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: analysis.thumbnailUrl != null
                      ? Image.network(
                    analysis.thumbnailUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  )
                      : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),
                ),
                const SizedBox(width: 16),

                // Информация об анализе
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Анализ от ${dateFormatter.format(analysis.analysisDate)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (analysis.skinIssues.isNotEmpty)
                        Text(
                          analysis.skinIssues.join(', '),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'Проблемы не обнаружены',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${analysis.recommendations.length} рекомендаций',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Индикатор
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}