import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skin_analyzer/providers/auth_provider.dart';
import 'package:skin_analyzer/screens/auth/login_screen.dart';
import 'package:skin_analyzer/widgets/loading_overlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final List<String> _skinTypes = [
    'Нормальная',
    'Сухая',
    'Жирная',
    'Комбинированная',
    'Чувствительная',
  ];

  final List<String> _skinConcerns = [
    'Акне',
    'Морщины',
    'Пигментация',
    'Обезвоженность',
    'Расширенные поры',
    'Покраснение',
    'Шелушение',
    'Тусклый цвет лица',
    'Темные круги под глазами',
    'Отечность',
  ];

  String? _selectedSkinType;
  List<String> _selectedSkinConcerns = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _selectedSkinType = user.skinType;
      _selectedSkinConcerns = user.skinConcerns ?? [];
    }
  }

  Future<void> _updateProfile() async {
    if (!_isEditing) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      skinType: _selectedSkinType,
      skinConcerns: _selectedSkinConcerns,
    );

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль успешно обновлен'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Спрашиваем подтверждение выхода
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await authProvider.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updateProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: authProvider.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аватар и имя
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isEditing) ...[
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Тип кожи
              Text(
                'Тип кожи',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_isEditing) ...[
                DropdownButtonFormField<String>(
                  value: _selectedSkinType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Выберите тип кожи',
                  ),
                  items: _skinTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSkinType = value;
                    });
                  },
                ),
              ] else ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.face),
                    title: const Text('Тип кожи'),
                    subtitle: Text(
                      user.skinType ?? 'Не указан',
                      style: TextStyle(
                        color: user.skinType != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Проблемы с кожей
              Text(
                'Проблемы с кожей',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_isEditing) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skinConcerns.map((concern) {
                    final isSelected = _selectedSkinConcerns.contains(concern);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(concern),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSkinConcerns.add(concern);
                          } else {
                            _selectedSkinConcerns.remove(concern);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ] else ...[
                if (user.skinConcerns != null && user.skinConcerns!.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.skinConcerns!.map((concern) {
                      return Chip(
                        label: Text(concern),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      );
                    }).toList(),
                  )
                else
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Проблемы с кожей'),
                      subtitle: const Text(
                        'Не указаны',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 32),

              // Аккаунт
              Text(
                'Аккаунт',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Изменить пароль'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Навигация к экрану смены пароля
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Удалить аккаунт'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Показать диалог подтверждения удаления аккаунта
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Дополнительные настройки
              Text(
                'Приложение',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.color_lens_outlined),
                      title: const Text('Тема оформления'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Настройки темы
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notification_important_outlined),
                      title: const Text('Уведомления'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Настройки уведомлений
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('О приложении'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Информация о приложении
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Кнопка выхода
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Выйти из аккаунта'),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}