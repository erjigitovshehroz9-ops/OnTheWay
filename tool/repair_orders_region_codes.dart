// One-time repair: recompute `region_code` / `district_code` on `public.orders` using
// the same logic as the app (`PickupAdminCodeResolver` + pickup_address/title extra).
//
// Usage (from repo root; pure Dart — no Flutter device):
//   dart run tool/repair_orders_region_codes.dart
//   dart run tool/repair_orders_region_codes.dart --apply
//   dart run tool/repair_orders_region_codes.dart --apply --only-fallback-defaults
//
// Environment (required for --apply and for dry-run fetch):
//   SUPABASE_URL          e.g. https://xxxx.supabase.co
//   SUPABASE_SERVICE_ROLE_KEY   (Dashboard → Settings → API; never commit)
//
// `--only-fallback-defaults` limits PATCH to rows where stored codes are exactly
// TK / TK_C (typical wrong fallback from empty haystack before pickupAddressExtra).

import 'dart:convert';
import 'dart:io';

import 'package:courier_auction/core/geo/pickup_admin_code_resolver.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');
  final onlyFallbackDefaults = args.contains('--only-fallback-defaults');

  final base = Platform.environment['SUPABASE_URL']?.trim();
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY']?.trim();
  if (base == null || base.isEmpty || key == null || key.isEmpty) {
    stderr.writeln(
      'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY to fetch orders.',
    );
    exitCode = 1;
    return;
  }

  final uri = Uri.parse(base);
  final host = uri.hasScheme ? '${uri.scheme}://${uri.host}' : base;
  final root = host.endsWith('/') ? host.substring(0, host.length - 1) : host;

  final headers = {
    'apikey': key,
    'Authorization': 'Bearer $key',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final select = Uri.parse(
    '$root/rest/v1/orders?'
    'select=id,pickup_region,pickup_district,pickup_address,title,region_code,district_code,status'
    '&status=in.(posted,auction_live)',
  );

  final getRes = await http.get(select, headers: headers);
  if (getRes.statusCode != 200) {
    stderr.writeln(
      'GET orders failed ${getRes.statusCode}: ${getRes.body}',
    );
    exitCode = 1;
    return;
  }

  final list = jsonDecode(getRes.body) as List<dynamic>;
  var wouldChange = 0;
  var skipped = 0;
  var patched = 0;

  for (final raw in list) {
    final row = Map<String, dynamic>.from(raw as Map);
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) continue;

    final oldR = (row['region_code'] as String?)?.trim() ?? '';
    final oldD = (row['district_code'] as String?)?.trim() ?? '';

    if (onlyFallbackDefaults && (oldR != 'TK' || oldD != 'TK_C')) {
      skipped++;
      continue;
    }

    final pr = row['pickup_region'] as String?;
    final pd = row['pickup_district'] as String?;
    final pa = row['pickup_address'] as String?;
    final title = row['title'] as String?;

    final extra = <String>[
      pa?.trim() ?? '',
      title?.trim() ?? '',
    ].where((s) => s.isNotEmpty).join(' ');

    final resolved = PickupAdminCodeResolver.resolve(
      pickupRegion: pr,
      pickupDistrictOrCity: pd,
      pickupAddressExtra: extra.isEmpty ? null : extra,
      fallbackRegionCode: oldR.isEmpty ? null : oldR,
      fallbackDistrictCode: oldD.isEmpty ? null : oldD,
    );

    if (resolved.regionCode == oldR && resolved.districtCode == oldD) {
      continue;
    }

    wouldChange++;
    stdout.writeln(
      '$id: $oldR/$oldD -> ${resolved.regionCode}/${resolved.districtCode}',
    );

    if (!apply) continue;

    final patchUri = Uri.parse('$root/rest/v1/orders?id=eq.${Uri.encodeComponent(id)}');
    final body = jsonEncode({
      'region_code': resolved.regionCode,
      'district_code': resolved.districtCode,
    });
    final patchHeaders = Map<String, String>.from(headers)
      ..['Prefer'] = 'return=minimal';
    final patchRes = await http.patch(
      patchUri,
      headers: patchHeaders,
      body: body,
    );
    if (patchRes.statusCode != 200 && patchRes.statusCode != 204) {
      stderr.writeln(
        'PATCH $id failed ${patchRes.statusCode}: ${patchRes.body}',
      );
    } else {
      patched++;
    }
  }

  stdout.writeln(
    'Done. rows=${list.length} would_change=$wouldChange '
    'skipped_filter=$skipped patched=$patched apply=$apply',
  );
  if (!apply && wouldChange > 0) {
    stdout.writeln('Re-run with --apply to write changes.');
  }
}
