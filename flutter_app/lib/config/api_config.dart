class ApiConfig {
  // Change this to your backend URL
  // For Android emulator use: http://10.0.2.2:8000
  // For iOS simulator use: http://localhost:8000
  // For real device use your computer's IP: http://192.168.x.x:8000
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Endpoints
  static const String register = '/register';
  static const String login = '/login';
  static const String refresh = '/refresh';
  static const String workouts = '/workouts';
}
