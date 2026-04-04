import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase RPC orqali `user_device_tokens` jadvali.
class PushDeviceRepository {
  PushDeviceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> registerToken({
    required String userId,
    required String token,
    required String platform,
    required String deviceId,
  }) async {
    await _client.rpc(
      'register_push_device_token',
      params: {
        'p_user_id': userId,
        'p_token': token,
        'p_platform': platform,
        'p_device_id': deviceId,
      },
    );
    if (kDebugMode) {
      debugPrint(
        '[push] token registered user=$userId platform=$platform device=$deviceId',
      );
    }
  }

  Future<void> deactivateForDevice({
    required String userId,
    required String deviceId,
  }) async {
    await _client.rpc(
      'deactivate_push_device_token',
      params: {
        'p_user_id': userId,
        'p_device_id': deviceId,
      },
    );
    if (kDebugMode) {
      debugPrint('[push] token deactivated user=$userId device=$deviceId');
    }
  }

  Future<void> deactivateTokenValue(String token) async {
    await _client.rpc(
      'deactivate_push_token_by_value',
      params: {'p_token': token},
    );
  }
}
