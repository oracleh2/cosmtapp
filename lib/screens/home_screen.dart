import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skin_analyzer/providers/auth_provider.dart';
import 'package:skin_analyzer/providers/analysis_provider.dart';
import 'package:skin_analyzer/screens/camera_screen.dart';
import 'package:skin_analyzer/screens/history_screen.dart';
import 'package:skin_analyzer/screens/profile_screen.dart';
import 'package:skin_analyzer/widgets/loading_overlay.dart';
import 'package:skin_analyzer/models/analysis_type.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Загружаем историю анализов при открытии приложения
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
      analysisProvider.loadAnalysisHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'История',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final analysisProvider = Provider.of<AnalysisProvider>(context);

    return LoadingOverlay(
      isLoading: authProvider.isLoading || analysisProvider.isLoading,
      child: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32, // -32 для учета padding по 16 с каждой стороны
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Приветствие
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              authProvider.currentUser?.name.substring(0, 1).toUpperCase() ?? 'A',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Привет, ${authProvider.currentUser?.name ?? 'Пользователь'}!',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Text(
                                  'Что хотите проверить сегодня?',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Кнопки анализа
                      Text(
                        'Выберите тип анализа',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        childAspectRatio: 1.0, // Изменено с 1.2 на 1.0, чтобы карточки были выше
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildAnalysisCard(
                            context,
                            title: 'Анализ кожи',
                            description: 'Оценка состояния и рекомендации',
                            icon: Icons.face,
                            onTap: () {
                              _navigateToCameraScreen(context, AnalysisType.skin);
                            },
                          ),
                          _buildAnalysisCard(
                            context,
                            title: 'Анализ косметики',
                            description: 'Проверка состава продуктов',
                            icon: Icons.spa,
                            onTap: () {
                              _navigateToCameraScreen(context, AnalysisType.product);
                            },
                          ),
                          _buildAnalysisCard(
                            context,
                            title: 'История',
                            description: 'Предыдущие анализы',
                            icon: Icons.history,
                            onTap: () {
                              // Перейти к экрану истории через родительский виджет
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const HistoryScreen()),
                              );
                            },
                          ),
                          _buildAnalysisCard(
                            context,
                            title: 'Подбор косметики',
                            description: 'Рекомендации по продуктам',
                            icon: Icons.shopping_bag,
                            onTap: () {
                              // Здесь будет навигация к экрану подбора косметики
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Последние анализы (если есть)
                      if (analysisProvider.analyses.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Последние анализы',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                                );
                              },
                              child: const Text('Смотреть все'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: analysisProvider.analyses.length > 3
                              ? 3
                              : analysisProvider.analyses.length,
                          itemBuilder: (context, index) {
                            final analysis = analysisProvider.analyses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: analysis.thumbnailUrl != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    analysis.thumbnailUrl!,
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
                                    Icons.image,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                title: Text(
                                  'Анализ от ${_formatDate(analysis.analysisDate)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  analysis.skinIssues.isNotEmpty
                                      ? analysis.skinIssues.join(', ')
                                      : 'Нет проблем с кожей',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  // Навигация к детальной информации об анализе
                                  analysisProvider.getAnalysisDetails(analysis.id);
                                  // TODO: переход к экрану детальной информации
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(
      BuildContext context, {
        required String title,
        required String description,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCameraScreen(BuildContext context, AnalysisType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(analysisType: type),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'сегодня, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateToCheck == yesterday) {
      return 'вчера, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

// Типы анализа определены в models/analysis_type.dart