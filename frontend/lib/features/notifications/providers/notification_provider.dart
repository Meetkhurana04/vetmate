import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vetmate/core/services/http_service.dart';
import 'package:vetmate/features/notifications/models/notification_model.dart';

class NotificationRepository {
  final HttpService _httpService;

  NotificationRepository({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await _httpService.get('/auth/notifications');
    final data = jsonDecode(response.body);
    if (data is! List) return const [];
    return data
        .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.fetchNotifications();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      return NotificationNotifier(repository);
    });
