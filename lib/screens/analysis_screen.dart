import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skin_analyzer/models/skin_analysis.dart';
import 'package:skin_analyzer/models/analysis_type.dart';
import 'package:skin_analyzer/providers/analysis_provider.dart';
import 'package:skin_analyzer/providers/auth_provider.dart';
import 'package:skin_analyzer/widgets/loading_overlay.dart';
import 'package:skin_analyzer/widgets/recommendation_card.dart';
import 'package:skin_analyzer/widgets/skin_metric_chart.dart';

class AnalysisScreen extends StatefulWidget {
  final File imageFile;
  final AnalysisType analysisType;
  final Map<String, dynamic>? initialData; // Для предварительных данных

  const AnalysisScreen({
    Key? key,
    required this.imageFile,
    required this.analysisType,
    this.initialData,
  }) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;
  String? _errorMessage;
  Map<String, dynamic>? _analysisData;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _analysisData = widget.initialData;
      _hasAnalyzed = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _analyzeImage();
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success;

      // Дополнительные данные для анализа
      Map<String, dynamic>? additionalData;

      if (authProvider.currentUser != null) {
        additionalData = {
          'skin_type': authProvider.currentUser!.skinType,
          'skin_concerns': authProvider.currentUser!.skinConcerns,
        };
      }

      if (widget.analysisType == AnalysisType.skin) {
        // Анализ кожи
        success = await analysisProvider.analyzeSkin(widget.imageFile, additionalData: additionalData);
      } else {
        // Анализ продукта
        final result = await analysisProvider.analyzeProductIngredients(widget.imageFile);
        success = result != null;
        if (success) {
          _analysisData = result;
        }
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _hasAnalyzed = success;
          if (!success) {
            _errorMessage = analysisProvider.errorMessage ?? 'Ошибка при анализе';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisProvider = Provider.of<AnalysisProvider>(context);
    final currentAnalysis = widget.analysisType == AnalysisType.skin
        ? analysisProvider.currentAnalysis
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.analysisType == AnalysisType.skin ? 'Анализ кожи' : 'Анализ состава',
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isAnalyzing,
        loadingText: 'Анализируем изображение...',
        child: widget.analysisType == AnalysisType.skin
            ? _buildSkinAnalysisContent(currentAnalysis)
            : _buildProductAnalysisContent(),
      ),
    );
  }

  Widget _buildSkinAnalysisContent(SkinAnalysis? analysis) {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_hasAnalyzed || analysis == null) {
      return _buildPreAnalysisView();
    }

    return _buildSkinAnalysisResultView(analysis);
  }

  Widget _buildProductAnalysisContent() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_hasAnalyzed || _analysisData == null) {
      return _buildPreAnalysisView();
    }

    return _buildProductAnalysisResultView(_analysisData!);
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Не удалось выполнить анализ',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Произошла неизвестная ошибка',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _analyzeImage,
              child: const Text('Попробовать снова'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Вернуться назад'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreAnalysisView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              widget.imageFile,
              fit: BoxFit.cover,
              height: 300,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.analysisType == AnalysisType.skin
                        ? 'Анализ кожи'
                        : 'Анализ состава косметики',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.analysisType == AnalysisType.skin
                        ? 'ИИ анализирует состояние вашей кожи и подготовит рекомендации.'
                        : 'ИИ анализирует состав косметического продукта и оценит его безопасность.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (!_isAnalyzing && !_hasAnalyzed)
                    ElevatedButton(
                      onPressed: _analyzeImage,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Начать анализ'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.analysisType == AnalysisType.skin)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Что анализирует ИИ?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: Icons.water_drop,
                      title: 'Увлажненность',
                      description: 'Оценка уровня увлажненности кожи',
                    ),
                    _buildFeatureItem(
                      icon: Icons.sunny,
                      title: 'Повреждения от солнца',
                      description: 'Обнаружение солнечных повреждений',
                    ),
                    _buildFeatureItem(
                      icon: Icons.face,
                      title: 'Морщины и текстура',
                      description: 'Анализ текстуры и морщин',
                    ),
                    _buildFeatureItem(
                      icon: Icons.opacity,
                      title: 'Жирность',
                      description: 'Оценка жирности кожи',
                    ),
                    _buildFeatureItem(
                      icon: Icons.colorize,
                      title: 'Покраснение',
                      description: 'Выявление воспаления и покраснений',
                    ),
                  ],
                ),
              ),
            ),
          if (widget.analysisType == AnalysisType.product)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Что анализирует ИИ?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: Icons.science,
                      title: 'Ингредиенты',
                      description: 'Распознавание всех компонентов состава',
                    ),
                    _buildFeatureItem(
                      icon: Icons.warning,
                      title: 'Потенциальные аллергены',
                      description: 'Выявление возможных аллергенов',
                    ),
                    _buildFeatureItem(
                      icon: Icons.shield,
                      title: 'Безопасность',
                      description: 'Оценка безопасности компонентов',
                    ),
                    _buildFeatureItem(
                      icon: Icons.psychology,
                      title: 'Совместимость с кожей',
                      description: 'Подходит ли продукт для вашего типа кожи',
                    ),
                    _buildFeatureItem(
                      icon: Icons.thumb_up,
                      title: 'Эффективность',
                      description: 'Оценка эффективности продукта',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkinAnalysisResultView(SkinAnalysis analysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Изображение
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              widget.imageFile,
              fit: BoxFit.cover,
              height: 200,
            ),
          ),
          const SizedBox(height: 24),

          // Результаты анализа
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Анализ завершен',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Обнаруженные проблемы кожи
                  if (analysis.skinIssues.isNotEmpty) ...[
                    Text(
                      'Обнаружено:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...analysis.skinIssues.map((issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, size: 20),
                          Expanded(
                            child: Text(issue),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Метрики кожи
          if (analysis.metrics.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Показатели кожи',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: SkinMetricChart(metrics: analysis.metrics),
                    ),
                    const SizedBox(height: 16),
                    ...analysis.metrics.map((metric) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(metric.name),
                          ),
                          Expanded(
                            flex: 7,
                            child: LinearProgressIndicator(
                              value: metric.maxValue != null
                                  ? metric.value / metric.maxValue!
                                  : metric.value / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getColorForMetric(metric),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${metric.value.toStringAsFixed(1)}${metric.unit ?? '%'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Рекомендации
          if (analysis.recommendations.isNotEmpty)
            RecommendationCard(recommendations: analysis.recommendations),
          const SizedBox(height: 16),

          // Рекомендуемые продукты
          if (analysis.recommendedProducts != null && analysis.recommendedProducts!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Рекомендуемые продукты',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...analysis.recommendedProducts!.map((product) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: product.imageUrl != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.spa,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          '${product.brand} ${product.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.category),
                            if (product.recommendationReason != null)
                              Text(
                                product.recommendationReason!,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: product.rating != null
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              product.rating!.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star_half, color: Colors.amber, size: 16),
                              ],
                            ),
                          ],
                        )
                            : null,
                        onTap: () {
                          // TODO: Открыть детальную информацию о продукте
                        },
                      ),
                    )),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Кнопка "Сохранить результат"
          ElevatedButton(
            onPressed: () {
              // Результаты уже сохранены в истории
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Вернуться на главную'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductAnalysisResultView(Map<String, dynamic> data) {
    // Отображение результатов анализа состава продукта
    // Это шаблон, который нужно адаптировать под ваш формат данных от API

    List<String> ingredients = [];
    List<Map<String, dynamic>> concerns = [];
    List<String> benefits = [];
    double safetyScore = 0.0;

    // Извлекаем данные из ответа API
    if (data.containsKey('ingredients') && data['ingredients'] is List) {
      ingredients = List<String>.from(data['ingredients']);
    }

    if (data.containsKey('concerns') && data['concerns'] is List) {
      concerns = List<Map<String, dynamic>>.from(data['concerns']);
    }

    if (data.containsKey('benefits') && data['benefits'] is List) {
      benefits = List<String>.from(data['benefits']);
    }

    if (data.containsKey('safety_score')) {
      safetyScore = (data['safety_score'] as num).toDouble();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Изображение
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              widget.imageFile,
              fit: BoxFit.cover,
              height: 200,
            ),
          ),
          const SizedBox(height: 24),

          // Результаты анализа
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Анализ завершен',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Оценка безопасности
                  Text(
                    'Оценка безопасности',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: safetyScore / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getSafetyColor(safetyScore),
                          ),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${safetyScore.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ингредиенты
          if (ingredients.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Обнаруженные ингредиенты',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...ingredients.map((ingredient) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(ingredient),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Потенциальные проблемы
          if (concerns.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Обратите внимание',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...concerns.map((concern) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  concern['name'] ?? 'Неизвестный ингредиент',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          if (concern.containsKey('description') && concern['description'] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 24, top: 4),
                              child: Text(
                                concern['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Полезные свойства
          if (benefits.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Полезные свойства',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...benefits.map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_up, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(benefit),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Кнопка "Вернуться на главную"
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Вернуться на главную'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Color _getSafetyColor(double score) {
    if (score < 30) return Colors.red;
    if (score < 70) return Colors.orange;
    return Colors.green;
  }
}