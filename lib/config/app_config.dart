class AppConfig {
  // API URL
  // static const String apiBaseUrl = 'http://localhost/api';
  // static const String apiBaseUrl = 'http://127.0.0.1/api';
  // static const String apiBaseUrl = 'http://10.0.2.2/api';
  // static const String apiBaseUrl = 'http://172.28.107.191/api';
  static const String apiBaseUrl = 'http://192.168.0.100/api';
  // static const String apiBaseUrl = 'http://192.168.160.1/api';


  // // Endpoints
  // static const String loginEndpoint = '/auth/login';
  // static const String registerEndpoint = '/auth/register';
  // static const String logoutEndpoint = '/auth/logout';
  // static const String profileEndpoint = '/user/profile';
  // static const String analyzeEndpoint = '/analysis/analyze';
  // static const String historyEndpoint = '/analysis/history';
  // static const String productEndpoint = '/products';
  //
  // // Timeout duration
  // static const int connectionTimeout = 30000; // milliseconds
  // static const int receiveTimeout = 30000; // milliseconds
  //
  // // Image quality settings
  // static const int imageQuality = 85;
  // static const double maxImageWidth = 1200;
  // static const double maxImageHeight = 1200;

  // Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String userEndpoint = '/user';
  static const String updateProfileEndpoint = '/user/profile';

  // Skin Photos endpoints
  static const String skinPhotosEndpoint = '/skin-photos';
  static const String latestSkinPhotoEndpoint = '/skin-photos/latest';

  // Skin Analyses endpoints
  static const String skinAnalysesEndpoint = '/skin-analyses';
  static const String timelineEndpoint = '/skin-analyses/timeline';

  // Cosmetics endpoints
  static const String cosmeticsEndpoint = '/cosmetics';
  static const String analyzeIngredientsEndpoint = '/cosmetics/analyze-ingredients';

  // Recommendations endpoints
  static const String recommendationsEndpoint = '/recommendations';
  static const String latestRecommendationEndpoint = '/recommendations/latest';
  static const String compareRecommendationsEndpoint = '/recommendations/compare';

  // Timeout duration
  static const int connectionTimeout = 60000; // в миллисекундах (60 секунд)
  static const int receiveTimeout = 60000; // в миллисекундах (60 секунд)

  // Image quality settings
  static const int imageQuality = 85;
  static const double maxImageWidth = 1200;
  static const double maxImageHeight = 1200;
}