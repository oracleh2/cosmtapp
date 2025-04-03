import 'package:flutter/material.dart';
import 'package:skin_analyzer/models/skin_analysis.dart';
import 'package:intl/intl.dart';

class AnalysisCard extends StatelessWidget {
  final SkinAnalysis analysis;
  final VoidCallback? onTap;
  final bool isExpanded;

  const AnalysisCard({
    Key? key,
    required this.analysis,
    this.onTap,
    this.isExpanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('d MMMM yyyy, HH:mm');

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение анализа
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                analysis.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Дата анализа
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              color: Theme.of(context).primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Анализ от ${dateFormatter.format(analysis.analysisDate)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            // Основная информация
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Обнаруженные проблемы
                  if (analysis.skinIssues.isNotEmpty) ...[
                    const Text(
                      'Обнаружены проблемы:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: analysis.skinIssues.map((issue) {
                        return Chip(
                          label: Text(
                            issue,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.red[50],
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Проблемы не обнаружены',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Показатели кожи
                  if (isExpanded && analysis.metrics.isNotEmpty) ...[
                    const Text(
                      'Показатели кожи:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...analysis.metrics.map((metric) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(metric.name),
                              Text(
                                '${metric.value.toStringAsFixed(1)}${metric.unit ?? '%'}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: metric.maxValue != null
                                ? metric.value / metric.maxValue!
                                : metric.value / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getColorForMetric(metric),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],

                  // Рекомендации (только если развернуто)
                  if (isExpanded && analysis.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Рекомендации:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...analysis.recommendations.map((recommendation) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(recommendation),
                          ),
                        ],
                      ),
                    )),
                  ],

                  // Кнопка "Подробнее" (только если не развернуто)
                  if (!isExpanded) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton(
                        onPressed: onTap,
                        child: const Text('Подробнее'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForMetric(SkinMetric metric) {
    // Логика определения цвета в зависимости от значения метрики
    if (metric.maxValue == null) {
      // Если нет максимального значения, используем простую логику:
      if (metric.value < 30) return Colors.red;
      if (metric.value < 70) return Colors.orange;
      return Colors.green;
    }

    // Если есть максимальное значение, используем соотношение:
    final ratio = metric.value / metric.maxValue!;
    if (ratio < 0.3) return Colors.red;
    if (ratio < 0.7) return Colors.orange;
    return Colors.green;
  }
}