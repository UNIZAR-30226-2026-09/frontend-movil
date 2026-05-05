import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api/dio_provider.dart';
import '../models/ranking_model.dart';
import '../services/ranking_service.dart';

final rankingServiceProvider = Provider<RankingService>((ref) {
  final dio = ref.watch(dioProvider);
  return RankingService(dio);
});

final rankingProvider = FutureProvider.autoDispose<List<RankingModel>>((ref) {
  final service = ref.watch(rankingServiceProvider);
  return service.getRanking(limite: 10);
});