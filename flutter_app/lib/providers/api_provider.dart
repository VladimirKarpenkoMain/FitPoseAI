import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  // Keep alive to maintain single instance
  ref.keepAlive();
  return ApiService();
});
