import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/courier/application/courier_orders_supabase_sync.dart';
import '../providers/core_providers.dart';

/// Runs auction deadline processing every second (native SQLite + RPC). Web: RPC only, no timer.
class AuctionHeartbeat extends ConsumerStatefulWidget {
  const AuctionHeartbeat({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuctionHeartbeat> createState() => _AuctionHeartbeatState();
}

class _AuctionHeartbeatState extends ConsumerState<AuctionHeartbeat> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final repo = await ref.read(jobRepositoryProvider.future);
        await repo.tickAuctions();
      } catch (e, st) {
        debugPrint('[auction_tick] $e\n$st');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider).valueOrNull;
    if (user != null) {
      ref.watch(marketplaceSupabaseSyncProvider);
    }
    return widget.child;
  }
}
