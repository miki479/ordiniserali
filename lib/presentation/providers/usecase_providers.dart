import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/calculate_frequent_dish_usecase.dart';
import '../../domain/usecases/cleanup_old_orders_usecase.dart';
import '../../domain/usecases/resolve_colleague_usecase.dart';
import 'repository_providers.dart';

final calculateFrequentDishUseCaseProvider = Provider((ref) {
  return CalculateFrequentDishUseCase(ref.watch(orderRepositoryProvider));
});

final resolveColleagueUseCaseProvider = Provider((ref) {
  return ResolveColleagueUseCase(ref.watch(userRepositoryProvider));
});

final cleanupOldOrdersUseCaseProvider = Provider((ref) {
  return CleanupOldOrdersUseCase(
    ref.watch(orderRepositoryProvider),
    ref.watch(localSettingsRepositoryProvider),
  );
});
