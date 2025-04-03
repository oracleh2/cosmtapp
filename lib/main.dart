import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skin_analyzer/providers/auth_provider.dart';
import 'package:skin_analyzer/providers/analysis_provider.dart';
import 'package:skin_analyzer/screens/home_screen.dart';
import 'package:skin_analyzer/screens/auth/login_screen.dart';
import 'package:skin_analyzer/config/theme.dart';
import 'package:skin_analyzer/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:skin_analyzer/utils/network_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Вывод информации о сетевых интерфейсах
  await NetworkInfo.printNetworkInterfaces();

  // Очистка токена авторизации при каждом запуске приложения
  // Очищаем токен только в режиме отладки
  //   if (kDebugMode) {
  //     const secureStorage = FlutterSecureStorage();
  //     await secureStorage.delete(key: 'auth_token');
  //   }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Вспомогательная функция для проверки авторизации
  Future<bool> _checkAuth(AuthProvider authProvider) async {
    return await authProvider.isAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Skin Analyzer',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: FutureBuilder<bool>(
              future: _checkAuth(authProvider),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final bool isAuthenticated = snapshot.data ?? false;
                return isAuthenticated
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}