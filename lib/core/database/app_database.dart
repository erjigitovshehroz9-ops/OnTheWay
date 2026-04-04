import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/regions_seed.dart';
import '../../models/admin_operational_snapshot.dart';
import '../../models/app_user.dart';
import '../../models/bid_entity.dart';
import '../../models/delivery_speed.dart';
import '../../models/feedback_entity.dart';
import '../../models/feedback_kind.dart';
import '../../models/job_entity.dart';
import '../../models/job_status.dart';
import '../../models/job_transport_type.dart';
import '../../models/localized_string.dart';
import '../../models/order_feedback_entity.dart';
import '../../models/order_feedback_type.dart';
import '../../models/payment_type.dart';
import '../../models/region_record.dart';
import '../../models/support_request_entity.dart';
import '../../models/user_role.dart';
import '../geo/pickup_admin_code_resolver.dart';
import '../geo/work_area_keys.dart';
import '../utils/auction_math.dart';
import 'app_database_path.dart';

List<JobEntity> _dedupeJobsByIdPreserveOrder(List<JobEntity> jobs) {
  final seen = <String>{};
  final out = <JobEntity>[];
  for (final j in jobs) {
    if (seen.add(j.id)) out.add(j);
  }
  return out;
}

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static const _name = 'courier_auction.db';
  static const _version = 22;

  static AppDatabase? _singleton;
  static Future<AppDatabase>? _opening;

  /// Single shared instance; [open] is safe to call from many providers/timers.
  static Future<AppDatabase> open() async {
    final existing = _singleton;
    if (existing != null) return existing;
    final pending = _opening;
    if (pending != null) return pending;

    _opening = _openNew();
    try {
      final db = await _opening!;
      _singleton = db;
      return db;
    } finally {
      _opening = null;
    }
  }

  static Future<AppDatabase> _openNew() async {
    // Web: absolute path so sqflite_common never joins [getDatabasesPath] (avoids
    // path_provider). IO: [resolveAppDatabasePath] uses path_provider (not imported on web).
    final path = await resolveAppDatabasePath(_name);
    if (kDebugMode) {
      print('DB PATH: $path');
    }
    final db = await openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchemaV4(db);
        await _createSupportRequestsTable(db);
        await _seedRegions(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _upgradeUsersV2(db);
          await _upgradeJobsV2(db);
          await db.rawUpdate(
            "UPDATE jobs SET status = 'posted' WHERE status = 'draft'",
          );
          await db.rawUpdate(
            "UPDATE jobs SET status = 'auction_live' WHERE status = 'live_auction'",
          );
          await db.rawUpdate(
            "UPDATE jobs SET status = 'assigned' WHERE status = 'winner_selected'",
          );
          await db.rawUpdate(
            '''UPDATE jobs SET 
            product_type_uz = title_uz, product_type_ru = title_ru, product_type_en = title_en,
            pickup_uz = '', pickup_ru = '', pickup_en = '',
            dropoff_uz = '', dropoff_ru = '', dropoff_en = '',
            extra_notes_uz = description_uz, extra_notes_ru = description_ru, extra_notes_en = description_en,
            region_code = 'TK', district_code = 'TK_C',
            start_price_cents = 10000, floor_price_cents = 5000
            WHERE start_price_cents = 0 OR start_price_cents IS NULL''',
          );
        }
        if (oldVersion < 3) {
          await _createAuxTablesV3(db);
          await _seedRegions(db);
        }
        if (oldVersion < 4) {
          await _upgradeJobsV4(db);
        }
        if (oldVersion < 5) {
          await _upgradeJobsV5(db);
        }
        if (oldVersion < 6) {
          await _upgradeJobsV6(db);
        }
        if (oldVersion < 7) {
          await _createSupportRequestsTable(db);
        }
        if (oldVersion < 8) {
          await _upgradeRegionsV8(db);
        }
        if (oldVersion < 9) {
          await _upgradeUsersV9(db);
          await _normalizeJobsTransportV9(db);
        }
        if (oldVersion < 10) {
          await _upgradeJobsAndUsersLocationKeysV10(db);
        }
        if (oldVersion < 11) {
          await _recomputeLocationKeysV11(db);
        }
        if (oldVersion < 12) {
          await _upgradeJobsPickupOriginalsV12(db);
        }
        if (oldVersion < 13) {
          await _resyncRegionsDistrictsTablesV13(db);
        }
        if (oldVersion < 14) {
          await _upgradeJobsProximityNotifyFlagsV14(db);
        }
        if (oldVersion < 15) {
          await _upgradeJobsSupabaseSyncFlagV15(db);
        }
        if (oldVersion < 16) {
          await _upgradeJobsCrossDeviceFieldsV16(db);
        }
        if (oldVersion < 17) {
          await _upgradeJobsAuctionBidCountV17(db);
        }
        if (oldVersion < 18) {
          await _upgradeJobsWinnerSelectedAtV18(db);
        }
        if (oldVersion < 19) {
          await _upgradeJobsCourierTrackingExtrasV19(db);
        }
        if (oldVersion < 20) {
          await _upgradeOrderFeedbackV20(db);
        }
        if (oldVersion < 21) {
          await _upgradeOrderFeedbackModerationV21(db);
        }
        if (oldVersion < 22) {
          await _upgradeJobsAuctionCurrentPriceV22(db);
        }
      },
    );
    return AppDatabase._(db);
  }

  static Future<Set<String>> _getColumnNames(Database db, String table) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    return columns
        .map((e) => (e['name']?.toString() ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  static Future<void> _upgradeJobsSupabaseSyncFlagV15(Database db) async {
    final columnNames = await _getColumnNames(db, 'jobs');
    if (!columnNames.contains('synced_from_supabase')) {
      await db.execute(
        'ALTER TABLE jobs ADD COLUMN synced_from_supabase INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  static Future<void> _upgradeJobsCourierTrackingExtrasV19(Database db) async {
    final columnNames = await _getColumnNames(db, 'jobs');
    if (!columnNames.contains('courier_heading')) {
      await db.execute('ALTER TABLE jobs ADD COLUMN courier_heading REAL');
    }
    if (!columnNames.contains('courier_speed_mps')) {
      await db.execute('ALTER TABLE jobs ADD COLUMN courier_speed_mps REAL');
    }
    if (!columnNames.contains('courier_accuracy_m')) {
      await db.execute('ALTER TABLE jobs ADD COLUMN courier_accuracy_m REAL');
    }
  }

  static Future<void> _upgradeJobsWinnerSelectedAtV18(Database db) async {
    final columnNames = await _getColumnNames(db, 'jobs');
    if (!columnNames.contains('winner_selected_at')) {
      await db.execute('ALTER TABLE jobs ADD COLUMN winner_selected_at INTEGER');
    }
  }

  static Future<void> _upgradeJobsAuctionCurrentPriceV22(Database db) async {
    final columnNames = await _getColumnNames(db, 'jobs');
    if (!columnNames.contains('current_price_cents')) {
      await db.execute('ALTER TABLE jobs ADD COLUMN current_price_cents INTEGER');
    }
  }

  static Future<void> _upgradeJobsAuctionBidCountV17(Database db) async {
    final columnNames = await _getColumnNames(db, 'jobs');
    if (!columnNames.contains('auction_bid_count')) {
      await db.execute(
        'ALTER TABLE jobs ADD COLUMN auction_bid_count INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  static Future<void> _upgradeJobsCrossDeviceFieldsV16(Database db) async {
    final columnNames = await _getColumnNames(db, 'jobs');
    if (!columnNames.contains('delivery_window_start')) {
      await db.execute('ALTER TABLE jobs ADD COLUMN delivery_window_start TEXT');
    }
    if (!columnNames.contains('volume_category')) {
      await db.execute(
        "ALTER TABLE jobs ADD COLUMN volume_category TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!columnNames.contains('order_comments')) {
      await db.execute('ALTER TABLE jobs ADD COLUMN order_comments TEXT');
    }
  }

  static Future<void> _upgradeJobsProximityNotifyFlagsV14(Database db) async {
    final columnNames = await _getColumnNames(db, 'jobs');

    if (!columnNames.contains('notify_pickup_1km')) {
      await db.execute(
        'ALTER TABLE jobs ADD COLUMN notify_pickup_1km INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (!columnNames.contains('notify_dropoff_5km')) {
      await db.execute(
        'ALTER TABLE jobs ADD COLUMN notify_dropoff_5km INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (!columnNames.contains('notify_dropoff_2km')) {
      await db.execute(
        'ALTER TABLE jobs ADD COLUMN notify_dropoff_2km INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  static Future<void> _createSchemaV4(Database db) async {
    await _createSchemaV3(db);
    await _upgradeJobsV4(db);
  }

  static Future<void> _upgradeUsersV9(Database db) async {
    final columnNames = await _getColumnNames(db, 'users');
    if (!columnNames.contains('courier_transport_types')) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN courier_transport_types TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  static Future<void> _resyncRegionsDistrictsTablesV13(Database db) async {
    await db.delete('districts');
    await db.delete('regions');
    await _seedRegions(db);
  }

  static Future<void> _upgradeJobsPickupOriginalsV12(Database db) async {
    final columnNames = await _getColumnNames(db, 'jobs');

    if (!columnNames.contains('pickup_region_original')) {
      await db.execute(
        'ALTER TABLE jobs ADD COLUMN pickup_region_original TEXT',
      );
    }
    if (!columnNames.contains('pickup_district_original')) {
      await db.execute(
        'ALTER TABLE jobs ADD COLUMN pickup_district_original TEXT',
      );
    }

    await db.rawUpdate(
      "UPDATE jobs SET pickup_region_original = pickup_region "
      "WHERE pickup_region IS NOT NULL AND TRIM(pickup_region) != ''",
    );
    await db.rawUpdate(
      "UPDATE jobs SET pickup_district_original = pickup_district_city "
      "WHERE pickup_district_city IS NOT NULL AND TRIM(pickup_district_city) != ''",
    );
  }

  static Future<void> _recomputeLocationKeysV11(Database db) async {
    final jobRows = await db.query('jobs');
    for (final r in jobRows) {
      final disp = WorkAreaKeys.fromPickupDisplay(
        r['pickup_region'] as String?,
        r['pickup_district_city'] as String?,
      );
      final cod = WorkAreaKeys.fromAdminCodes(
        r['region_code'] as String?,
        r['district_code'] as String?,
      );
      await db.update(
        'jobs',
        {
          'pickup_region_key':
              disp.regionKey.isNotEmpty ? disp.regionKey : cod.regionKey,
          'pickup_district_key':
              disp.districtKey.isNotEmpty ? disp.districtKey : cod.districtKey,
        },
        where: 'id = ?',
        whereArgs: [r['id']],
      );
    }
    final userRows = await db.query('users');
    for (final r in userRows) {
      final k = WorkAreaKeys.fromAdminCodes(
        r['region_code'] as String?,
        r['district_code'] as String?,
      );
      await db.update(
        'users',
        {
          'working_region_key': k.regionKey,
          'working_district_key': k.districtKey,
        },
        where: 'id = ?',
        whereArgs: [r['id']],
      );
    }
  }

  static Future<void> _upgradeJobsAndUsersLocationKeysV10(Database db) async {
    final jobColumns = await _getColumnNames(db, 'jobs');
    final userColumns = await _getColumnNames(db, 'users');

    if (!jobColumns.contains('pickup_region_key')) {
      await db.execute(
        "ALTER TABLE jobs ADD COLUMN pickup_region_key TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!jobColumns.contains('pickup_district_key')) {
      await db.execute(
        "ALTER TABLE jobs ADD COLUMN pickup_district_key TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!userColumns.contains('working_region_key')) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN working_region_key TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!userColumns.contains('working_district_key')) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN working_district_key TEXT NOT NULL DEFAULT ''",
      );
    }

    final jobRows = await db.query('jobs');
    for (final r in jobRows) {
      final resolved = PickupAdminCodeResolver.resolve(
        pickupRegion: r['pickup_region'] as String?,
        pickupDistrictOrCity: r['pickup_district_city'] as String?,
        fallbackRegionCode: r['region_code'] as String?,
        fallbackDistrictCode: r['district_code'] as String?,
      );
      final disp = WorkAreaKeys.fromPickupDisplay(
        r['pickup_region'] as String?,
        r['pickup_district_city'] as String?,
      );
      final cod = WorkAreaKeys.fromAdminCodes(
        resolved.regionCode,
        resolved.districtCode,
      );
      await db.update(
        'jobs',
        {
          'region_code': resolved.regionCode,
          'district_code': resolved.districtCode,
          'pickup_region_key':
              disp.regionKey.isNotEmpty ? disp.regionKey : cod.regionKey,
          'pickup_district_key':
              disp.districtKey.isNotEmpty ? disp.districtKey : cod.districtKey,
        },
        where: 'id = ?',
        whereArgs: [r['id']],
      );
    }

    final userRows = await db.query('users');
    for (final r in userRows) {
      final k = WorkAreaKeys.fromAdminCodes(
        r['region_code'] as String?,
        r['district_code'] as String?,
      );
      await db.update(
        'users',
        {
          'working_region_key': k.regionKey,
          'working_district_key': k.districtKey,
        },
        where: 'id = ?',
        whereArgs: [r['id']],
      );
    }
  }

  static Future<void> _normalizeJobsTransportV9(Database db) async {
    final rows = await db.query('jobs');
    for (final r in rows) {
      final id = r['id']! as String;
      final raw = r['transport_type'] as String? ?? '';
      final next = JobTransportType.migrateStoredJobTransportToSingleKey(raw);
      if (next != raw) {
        await db.update(
          'jobs',
          {'transport_type': next},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  static Future<void> _createSchemaV3(Database db) async {
    await db.execute('''
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  phone TEXT NOT NULL UNIQUE,
  role TEXT,
  phone_verified INTEGER NOT NULL DEFAULT 0,
  offer_accepted INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  telegram TEXT NOT NULL DEFAULT '',
  rating REAL NOT NULL DEFAULT 5.0,
  completed_jobs INTEGER NOT NULL DEFAULT 0,
  complaint_count INTEGER NOT NULL DEFAULT 0,
  praise_count INTEGER NOT NULL DEFAULT 0,
  blocked INTEGER NOT NULL DEFAULT 0,
  region_code TEXT,
  district_code TEXT,
  working_region_key TEXT NOT NULL DEFAULT '',
  working_district_key TEXT NOT NULL DEFAULT '',
  is_system_admin INTEGER NOT NULL DEFAULT 0,
  courier_lat REAL,
  courier_lng REAL,
  courier_location_updated_at INTEGER,
  courier_transport_types TEXT NOT NULL DEFAULT ''
);
''');
    await db.execute('''
CREATE TABLE jobs (
  id TEXT PRIMARY KEY,
  sender_id TEXT NOT NULL,
  title_uz TEXT NOT NULL,
  title_ru TEXT NOT NULL,
  title_en TEXT NOT NULL,
  description_uz TEXT NOT NULL,
  description_ru TEXT NOT NULL,
  description_en TEXT NOT NULL,
  product_type_uz TEXT NOT NULL,
  product_type_ru TEXT NOT NULL,
  product_type_en TEXT NOT NULL,
  pickup_uz TEXT NOT NULL,
  pickup_ru TEXT NOT NULL,
  pickup_en TEXT NOT NULL,
  dropoff_uz TEXT NOT NULL,
  dropoff_ru TEXT NOT NULL,
  dropoff_en TEXT NOT NULL,
  product_weight_kg REAL NOT NULL,
  product_volume_l REAL NOT NULL,
  dimensions_mm TEXT NOT NULL DEFAULT '',
  transport_type TEXT NOT NULL DEFAULT '',
  recipient_name TEXT NOT NULL,
  recipient_phone TEXT NOT NULL,
  image_path TEXT NOT NULL,
  delivery_speed TEXT NOT NULL,
  delivery_window_start TEXT,
  delivery_window_end TEXT,
  volume_category TEXT NOT NULL DEFAULT '',
  start_price_cents INTEGER NOT NULL,
  floor_price_cents INTEGER NOT NULL,
  final_price_cents INTEGER,
  current_price_cents INTEGER,
  fragile INTEGER NOT NULL DEFAULT 0,
  cold_chain INTEGER NOT NULL DEFAULT 0,
  order_comments TEXT,
  payment_type TEXT NOT NULL,
  extra_notes_uz TEXT NOT NULL,
  extra_notes_ru TEXT NOT NULL,
  extra_notes_en TEXT NOT NULL,
  region_code TEXT NOT NULL,
  district_code TEXT NOT NULL,
  pickup_lat REAL,
  pickup_lng REAL,
  dropoff_lat REAL,
  dropoff_lng REAL,
  pickup_region TEXT,
  pickup_district_city TEXT,
  pickup_region_original TEXT,
  pickup_district_original TEXT,
  pickup_region_key TEXT NOT NULL DEFAULT '',
  pickup_district_key TEXT NOT NULL DEFAULT '',
  dropoff_region TEXT,
  dropoff_district_city TEXT,
  status TEXT NOT NULL,
  auction_duration_sec INTEGER NOT NULL DEFAULT 30,
  auction_ends_at INTEGER,
  auction_step INTEGER NOT NULL DEFAULT 0,
  auction_bid_count INTEGER NOT NULL DEFAULT 0,
  leading_courier_id TEXT,
  winner_courier_id TEXT,
  courier_lat REAL,
  courier_lng REAL,
  courier_location_at INTEGER,
  courier_heading REAL,
  courier_speed_mps REAL,
  courier_accuracy_m REAL,
  courier_completion_note TEXT,
  notify_pickup_1km INTEGER NOT NULL DEFAULT 0,
  notify_dropoff_5km INTEGER NOT NULL DEFAULT 0,
  notify_dropoff_2km INTEGER NOT NULL DEFAULT 0,
  synced_from_supabase INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  winner_selected_at INTEGER,
  FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE
);
''');
    await db.execute('''
CREATE TABLE bids (
  id TEXT PRIMARY KEY,
  job_id TEXT NOT NULL,
  courier_id TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (job_id) REFERENCES jobs (id) ON DELETE CASCADE,
  FOREIGN KEY (courier_id) REFERENCES users (id) ON DELETE CASCADE
);
''');
    await _createAuxTablesV3(db);
    await db.execute('CREATE INDEX idx_jobs_sender ON jobs (sender_id);');
    await db.execute(
      'CREATE INDEX idx_jobs_region ON jobs (region_code, district_code);',
    );
    await db.execute('CREATE INDEX idx_jobs_status ON jobs (status);');
    await db.execute('CREATE INDEX idx_bids_job ON bids (job_id);');
  }

  static Future<void> _createAuxTablesV3(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS regions (
  code TEXT PRIMARY KEY,
  name_uz TEXT NOT NULL,
  name_ru TEXT NOT NULL,
  name_en TEXT NOT NULL
);
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS districts (
  code TEXT PRIMARY KEY,
  region_code TEXT NOT NULL,
  name_uz TEXT NOT NULL,
  name_ru TEXT NOT NULL,
  name_en TEXT NOT NULL,
  FOREIGN KEY (region_code) REFERENCES regions (code)
);
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS auction_steps (
  id TEXT PRIMARY KEY,
  job_id TEXT NOT NULL,
  courier_id TEXT NOT NULL,
  step_index INTEGER NOT NULL,
  price_cents INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (job_id) REFERENCES jobs (id) ON DELETE CASCADE
);
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS feedback (
  id TEXT PRIMARY KEY,
  from_user_id TEXT NOT NULL,
  to_user_id TEXT NOT NULL,
  job_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  category TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_feedback_to ON feedback (to_user_id);',
    );
    await db.execute('''
CREATE TABLE IF NOT EXISTS order_feedback (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL,
  from_user_id TEXT NOT NULL,
  to_user_id TEXT NOT NULL,
  from_role TEXT NOT NULL,
  to_role TEXT NOT NULL,
  rating INTEGER NOT NULL,
  feedback_type TEXT NOT NULL,
  complaint_category TEXT,
  praise_category TEXT,
  comment TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  complaint_status TEXT,
  admin_note TEXT,
  reviewed_by TEXT,
  reviewed_at INTEGER,
  UNIQUE (order_id, from_user_id)
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_order_feedback_order ON order_feedback (order_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_order_feedback_to ON order_feedback (to_user_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_order_feedback_from ON order_feedback (from_user_id);',
    );
  }

  static Future<void> _upgradeOrderFeedbackModerationV21(Database db) async {
    final cols = await _getColumnNames(db, 'order_feedback');
    if (!cols.contains('complaint_status')) {
      await db.execute(
        'ALTER TABLE order_feedback ADD COLUMN complaint_status TEXT',
      );
    }
    if (!cols.contains('admin_note')) {
      await db.execute('ALTER TABLE order_feedback ADD COLUMN admin_note TEXT');
    }
    if (!cols.contains('reviewed_by')) {
      await db.execute('ALTER TABLE order_feedback ADD COLUMN reviewed_by TEXT');
    }
    if (!cols.contains('reviewed_at')) {
      await db.execute(
        'ALTER TABLE order_feedback ADD COLUMN reviewed_at INTEGER',
      );
    }
  }

  static Future<void> _upgradeOrderFeedbackV20(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS order_feedback (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL,
  from_user_id TEXT NOT NULL,
  to_user_id TEXT NOT NULL,
  from_role TEXT NOT NULL,
  to_role TEXT NOT NULL,
  rating INTEGER NOT NULL,
  feedback_type TEXT NOT NULL,
  complaint_category TEXT,
  praise_category TEXT,
  comment TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  complaint_status TEXT,
  admin_note TEXT,
  reviewed_by TEXT,
  reviewed_at INTEGER,
  UNIQUE (order_id, from_user_id)
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_order_feedback_order ON order_feedback (order_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_order_feedback_to ON order_feedback (to_user_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_order_feedback_from ON order_feedback (from_user_id);',
    );
  }

  static Future<void> _upgradeUsersV2(Database db) async {
    const alters = [
      'ALTER TABLE users ADD COLUMN first_name TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE users ADD COLUMN last_name TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE users ADD COLUMN telegram TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE users ADD COLUMN rating REAL NOT NULL DEFAULT 5.0;',
      'ALTER TABLE users ADD COLUMN completed_jobs INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE users ADD COLUMN complaint_count INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE users ADD COLUMN praise_count INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE users ADD COLUMN blocked INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE users ADD COLUMN region_code TEXT;',
      'ALTER TABLE users ADD COLUMN district_code TEXT;',
      'ALTER TABLE users ADD COLUMN is_system_admin INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE users ADD COLUMN courier_lat REAL;',
      'ALTER TABLE users ADD COLUMN courier_lng REAL;',
      'ALTER TABLE users ADD COLUMN courier_location_updated_at INTEGER;',
    ];
    for (final sql in alters) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }
    await db.rawUpdate(
      "UPDATE users SET is_system_admin = 1 WHERE role = 'admin'",
    );
  }

  static Future<void> _upgradeJobsV2(Database db) async {
    const alters = [
      'ALTER TABLE jobs ADD COLUMN product_type_uz TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN product_type_ru TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN product_type_en TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN pickup_uz TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN pickup_ru TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN pickup_en TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN dropoff_uz TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN dropoff_ru TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN dropoff_en TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN product_weight_kg REAL NOT NULL DEFAULT 0;',
      'ALTER TABLE jobs ADD COLUMN product_volume_l REAL NOT NULL DEFAULT 0;',
      'ALTER TABLE jobs ADD COLUMN recipient_name TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN recipient_phone TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN image_path TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN delivery_speed TEXT NOT NULL DEFAULT "fast";',
      'ALTER TABLE jobs ADD COLUMN delivery_window_end TEXT;',
      'ALTER TABLE jobs ADD COLUMN start_price_cents INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE jobs ADD COLUMN floor_price_cents INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE jobs ADD COLUMN final_price_cents INTEGER;',
      'ALTER TABLE jobs ADD COLUMN fragile INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE jobs ADD COLUMN cold_chain INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE jobs ADD COLUMN payment_type TEXT NOT NULL DEFAULT "cash";',
      'ALTER TABLE jobs ADD COLUMN extra_notes_uz TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN extra_notes_ru TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN extra_notes_en TEXT NOT NULL DEFAULT "";',
      'ALTER TABLE jobs ADD COLUMN region_code TEXT NOT NULL DEFAULT "TK";',
      'ALTER TABLE jobs ADD COLUMN district_code TEXT NOT NULL DEFAULT "TK_C";',
      'ALTER TABLE jobs ADD COLUMN pickup_lat REAL;',
      'ALTER TABLE jobs ADD COLUMN pickup_lng REAL;',
      'ALTER TABLE jobs ADD COLUMN dropoff_lat REAL;',
      'ALTER TABLE jobs ADD COLUMN dropoff_lng REAL;',
      'ALTER TABLE jobs ADD COLUMN auction_step INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE jobs ADD COLUMN leading_courier_id TEXT;',
      'ALTER TABLE jobs ADD COLUMN courier_lat REAL;',
      'ALTER TABLE jobs ADD COLUMN courier_lng REAL;',
      'ALTER TABLE jobs ADD COLUMN courier_location_at INTEGER;',
      'ALTER TABLE jobs ADD COLUMN courier_completion_note TEXT;',
    ];
    for (final sql in alters) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }
  }

  static Future<void> _upgradeJobsV4(Database db) async {
    const alters = [
      'ALTER TABLE jobs ADD COLUMN pickup_region TEXT;',
      'ALTER TABLE jobs ADD COLUMN pickup_district_city TEXT;',
      'ALTER TABLE jobs ADD COLUMN dropoff_region TEXT;',
      'ALTER TABLE jobs ADD COLUMN dropoff_district_city TEXT;',
    ];
    for (final sql in alters) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }
  }

  static Future<void> _upgradeJobsV5(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE jobs ADD COLUMN dimensions_mm TEXT NOT NULL DEFAULT "";',
      );
    } catch (_) {}
  }

  static Future<void> _upgradeJobsV6(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE jobs ADD COLUMN transport_type TEXT NOT NULL DEFAULT "";',
      );
    } catch (_) {}
  }

  static Future<void> _createSupportRequestsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS support_requests (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  user_phone TEXT NOT NULL,
  role TEXT NOT NULL,
  request_type TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'new'
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_support_requests_created ON support_requests (created_at DESC);',
    );
  }

  static Future<void> _upgradeRegionsV8(Database db) async {
    await db.rawUpdate(
      "UPDATE jobs SET district_code = 'TO_OQQ' WHERE district_code = 'TO_O'",
    );
    await db.rawUpdate(
      "UPDATE jobs SET district_code = 'AN_AND' WHERE district_code = 'AN_A'",
    );
    await db.rawUpdate(
      "UPDATE users SET district_code = 'TO_OQQ' WHERE district_code = 'TO_O'",
    );
    await db.rawUpdate(
      "UPDATE users SET district_code = 'AN_AND' WHERE district_code = 'AN_A'",
    );
    await db.delete('districts');
    await db.delete('regions');
    await _seedRegions(db);
  }

  static Future<void> _seedRegions(Database db) async {
    for (final r in RegionsSeed.regions) {
      await db.insert(
        'regions',
        {
          'code': r.code,
          'name_uz': r.name.uz,
          'name_ru': r.name.ru,
          'name_en': r.name.en,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    for (final d in RegionsSeed.districts) {
      await db.insert(
        'districts',
        {
          'code': d.code,
          'region_code': d.regionCode,
          'name_uz': d.name.uz,
          'name_ru': d.name.ru,
          'name_en': d.name.en,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> close() => _db.close();

  Future<void> upsertUser(AppUser user) async {
    final wk = WorkAreaKeys.fromAdminCodes(user.regionCode, user.districtCode);
    if (kDebugMode) {
      debugPrint(
        '[userArea] save id=${user.id} rawRegion=${user.regionCode} rawDistrict=${user.districtCode} '
        'workingRKey=${wk.regionKey} workingDKey=${wk.districtKey}',
      );
    }
    final values = <String, Object?>{
      'id': user.id,
      'phone': user.phone,
      'role': user.role?.storageValue,
      'phone_verified': user.phoneVerified ? 1 : 0,
      'offer_accepted': user.offerAccepted ? 1 : 0,
      'created_at': user.createdAt.millisecondsSinceEpoch,
      'first_name': user.firstName,
      'last_name': user.lastName,
      'telegram': user.telegram,
      'rating': user.rating,
      'completed_jobs': user.completedJobs,
      'complaint_count': user.complaintCount,
      'praise_count': user.praiseCount,
      'blocked': user.blocked ? 1 : 0,
      'region_code': user.regionCode,
      'district_code': user.districtCode,
      'working_region_key': wk.regionKey,
      'working_district_key': wk.districtKey,
      'is_system_admin': user.isSystemAdmin ? 1 : 0,
      'courier_lat': user.courierLat,
      'courier_lng': user.courierLng,
      'courier_location_updated_at':
          user.courierLocationUpdatedAt?.millisecondsSinceEpoch,
      'courier_transport_types': JobTransportType.encodeTransportTypesToStorage(
        user.courierTransportTypes,
      ),
    };

    final updated = await _db.update(
      'users',
      values,
      where: 'id = ?',
      whereArgs: [user.id],
    );

    if (updated == 0) {
      await _db.insert('users', values);
    }
  }

  Future<AppUser?> getUserById(String id) async {
    final rows = await _db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _userFromMap(rows.first);
  }

  Future<AppUser?> getUserByPhone(String phone) async {
    final rows = await _db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _userFromMap(rows.first);
  }

  Future<List<AppUser>> listAllUsers() async {
    final rows = await _db.query('users', orderBy: 'created_at DESC');
    return rows.map(_userFromMap).toList();
  }

  AppUser _userFromMap(Map<String, Object?> m) {
    return AppUser(
      id: m['id']! as String,
      phone: m['phone']! as String,
      role: UserRole.tryParse(m['role'] as String?),
      phoneVerified: (m['phone_verified'] as int? ?? 0) == 1,
      offerAccepted: (m['offer_accepted'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
      firstName: m['first_name'] as String? ?? '',
      lastName: m['last_name'] as String? ?? '',
      telegram: m['telegram'] as String? ?? '',
      rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
      completedJobs: m['completed_jobs'] as int? ?? 0,
      complaintCount: m['complaint_count'] as int? ?? 0,
      praiseCount: m['praise_count'] as int? ?? 0,
      blocked: (m['blocked'] as int? ?? 0) == 1,
      regionCode: m['region_code'] as String?,
      districtCode: m['district_code'] as String?,
      workingRegionKey: () {
        final k = m['working_region_key'] as String? ?? '';
        if (k.isNotEmpty) return k;
        return WorkAreaKeys.fromAdminCodes(
          m['region_code'] as String?,
          m['district_code'] as String?,
        ).regionKey;
      }(),
      workingDistrictKey: () {
        final k = m['working_district_key'] as String? ?? '';
        if (k.isNotEmpty) return k;
        return WorkAreaKeys.fromAdminCodes(
          m['region_code'] as String?,
          m['district_code'] as String?,
        ).districtKey;
      }(),
      isSystemAdmin: (m['is_system_admin'] as int? ?? 0) == 1,
      courierLat: (m['courier_lat'] as num?)?.toDouble(),
      courierLng: (m['courier_lng'] as num?)?.toDouble(),
      courierLocationUpdatedAt: m['courier_location_updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              m['courier_location_updated_at']! as int,
            ),
      courierTransportTypes: JobTransportType.normalizeCourierKeyList(
        JobTransportType.parseStoredTransportCodes(
          m['courier_transport_types'] as String? ?? '',
        ),
      ),
    );
  }

  Future<void> insertJob(JobEntity job) async {
    await _db.insert(
      'jobs',
      _jobToMap(job),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateJob(JobEntity job) async {
    await _db.update(
      'jobs',
      _jobToMap(job),
      where: 'id = ?',
      whereArgs: [job.id],
    );
  }

  Future<void> deleteJobById(String id) async {
    if (id.isEmpty) return;
    await _db.delete('jobs', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _jobToMap(JobEntity job) {
    return {
      'id': job.id,
      'sender_id': job.senderId,
      'title_uz': job.title.uz,
      'title_ru': job.title.ru,
      'title_en': job.title.en,
      'description_uz': job.description.uz,
      'description_ru': job.description.ru,
      'description_en': job.description.en,
      'product_type_uz': job.productType.uz,
      'product_type_ru': job.productType.ru,
      'product_type_en': job.productType.en,
      'pickup_uz': job.pickupAddress.uz,
      'pickup_ru': job.pickupAddress.ru,
      'pickup_en': job.pickupAddress.en,
      'dropoff_uz': job.dropoffAddress.uz,
      'dropoff_ru': job.dropoffAddress.ru,
      'dropoff_en': job.dropoffAddress.en,
      'product_weight_kg': job.productWeightKg,
      'product_volume_l': job.productVolumeL,
      'dimensions_mm': job.dimensionsMm,
      'transport_type': job.transportType,
      'recipient_name': job.recipientName,
      'recipient_phone': job.recipientPhone,
      'image_path': job.imagePath,
      'delivery_speed': job.deliverySpeed.toStorage(),
      'delivery_window_start': job.deliveryWindowStart,
      'delivery_window_end': job.deliveryWindowEnd,
      'volume_category': job.volumeCategoryKey,
      'start_price_cents': job.startPriceCents,
      'floor_price_cents': job.floorPriceCents,
      'final_price_cents': job.finalPriceCents,
      'current_price_cents': job.currentPriceCents,
      'fragile': job.fragile ? 1 : 0,
      'cold_chain': job.coldChain ? 1 : 0,
      'order_comments': job.orderComments,
      'payment_type': job.paymentType.toStorage(),
      'extra_notes_uz': '',
      'extra_notes_ru': '',
      'extra_notes_en': '',
      'region_code': job.regionCode,
      'district_code': job.districtCode,
      'pickup_lat': job.pickupLat,
      'pickup_lng': job.pickupLng,
      'dropoff_lat': job.dropoffLat,
      'dropoff_lng': job.dropoffLng,
      'pickup_region': job.pickupRegion,
      'pickup_district_city': job.pickupDistrictOrCity,
      'pickup_region_original': job.pickupRegionOriginal,
      'pickup_district_original': job.pickupDistrictOriginal,
      'pickup_region_key': job.pickupRegionKey,
      'pickup_district_key': job.pickupDistrictKey,
      'dropoff_region': job.dropoffRegion,
      'dropoff_district_city': job.dropoffDistrictOrCity,
      'status': job.status.toStorage(),
      'auction_duration_sec': 30,
      'auction_ends_at': job.auctionEndsAt?.millisecondsSinceEpoch,
      'auction_step': job.auctionStep,
      'auction_bid_count': job.auctionBidCount,
      'leading_courier_id': job.leadingCourierId,
      'winner_courier_id': job.winnerCourierId,
      'courier_lat': job.courierLat,
      'courier_lng': job.courierLng,
      'courier_location_at': job.courierLocationAt?.millisecondsSinceEpoch,
      'courier_heading': job.courierHeading,
      'courier_speed_mps': job.courierSpeedMps,
      'courier_accuracy_m': job.courierAccuracyM,
      'courier_completion_note': job.courierCompletionNote,
      'notify_pickup_1km': job.notifiedPickup1Km ? 1 : 0,
      'notify_dropoff_5km': job.notifiedDropoff5Km ? 1 : 0,
      'notify_dropoff_2km': job.notifiedDropoff2Km ? 1 : 0,
      'synced_from_supabase': job.syncedFromSupabase ? 1 : 0,
      'created_at': job.createdAt.millisecondsSinceEpoch,
      'winner_selected_at': job.winnerSelectedAt?.millisecondsSinceEpoch,
    };
  }

  Future<JobEntity?> getJobById(String id) async {
    final rows = await _db.query(
      'jobs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _jobFromMap(rows.first);
  }

  Future<List<JobEntity>> listJobsForSender(String senderId) async {
    final rows = await _db.query(
      'jobs',
      where: 'sender_id = ?',
      whereArgs: [senderId],
      orderBy: 'created_at DESC',
    );
    final list = rows.map(_jobFromMap).toList();
    return _dedupeJobsByIdPreserveOrder(list);
  }

  Future<List<JobEntity>> listJobsForCourierFeed({
    required String? regionCode,
    required String? districtCode,
    required String courierWorkingRegionKey,
    required String courierWorkingDistrictKey,
    required bool courierWholeRegionDistrict,
    List<String>? courierTransportKeys,
    String? winnerCourierId,
    /// Courier marketplace: only rows hydrated from Supabase (`synced_from_supabase = 1`).
    /// Sender lists use other queries; leave `false` for non-courier feed callers.
    bool requireRemoteBackedJobs = false,
  }) async {
    final where = StringBuffer(
      "status IN ('posted','auction_live')",
    );
    final args = <Object?>[];
    if (requireRemoteBackedJobs) {
      where.write(' AND synced_from_supabase = 1');
    }
    if (regionCode != null && regionCode.isNotEmpty) {
      where.write(
        ' AND (region_code = ? OR region_code IS NULL OR TRIM(IFNULL(region_code,\'\')) = \'\')',
      );
      args.add(regionCode);
    }
    if (kDebugMode) {
      debugPrint('[courierFeedSql] sqlWhere=${where.toString()} sqlArgs=$args');
    }
    final rows = await _db.query(
      'jobs',
      where: where.toString(),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
    );
    var jobs = rows.map(_jobFromMap).toList();
    jobs = jobs
        .where(
          (j) => WorkAreaKeys.courierJobMatchesWorkArea(
            job: j,
            courierWorkingRegionKey: courierWorkingRegionKey,
            courierWorkingDistrictKey: courierWorkingDistrictKey,
            courierRegionCode: regionCode,
            courierDistrictCode: districtCode,
            wholeRegionDistrict: courierWholeRegionDistrict,
          ),
        )
        .toList();

    if (kDebugMode) {
      debugPrint(
        '[courierFeedSql] whereArgRegion=$regionCode districtCode=$districtCode '
        '(Dart-only, not in SQL) wholeRegion=$courierWholeRegionDistrict',
      );
      debugPrint(
        '[courierFeedSql] workingRKey=$courierWorkingRegionKey '
        'workingDKey=$courierWorkingDistrictKey rowsAfterWorkArea=${jobs.length}',
      );
    }

    if (courierTransportKeys != null && courierTransportKeys.isNotEmpty) {
      jobs = jobs
          .where(
            (j) => JobTransportType.courierSeesJob(
              courierNormalizedKeys: courierTransportKeys,
              jobTransportStored: j.transportType,
            ),
          )
          .toList();
    }

    if (winnerCourierId != null && winnerCourierId.isNotEmpty) {
      var wonWhere =
          "winner_courier_id = ? AND status IN ('assigned','picked_up','delivered','completed')";
      if (requireRemoteBackedJobs) {
        wonWhere += ' AND synced_from_supabase = 1';
      }
      final wonRows = await _db.query(
        'jobs',
        where: wonWhere,
        whereArgs: [winnerCourierId],
        orderBy: 'created_at DESC',
      );
      var wonJobs = wonRows.map(_jobFromMap).toList();
      if (courierTransportKeys != null && courierTransportKeys.isNotEmpty) {
        wonJobs = wonJobs
            .where(
              (j) => JobTransportType.courierSeesJob(
                courierNormalizedKeys: courierTransportKeys,
                jobTransportStored: j.transportType,
              ),
            )
            .toList();
      }
      final byId = <String, JobEntity>{for (final j in jobs) j.id: j};
      for (final j in wonJobs) {
        byId[j.id] = j;
      }
      jobs = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return _dedupeJobsByIdPreserveOrder(jobs);
  }

  Future<List<JobEntity>> listActiveTrackingJobs() async {
    final rows = await _db.query(
      'jobs',
      where: 'status = ?',
      whereArgs: [JobStatus.pickedUp.toStorage()],
    );
    return rows.map(_jobFromMap).toList();
  }

  Future<List<JobEntity>> listAllJobsAdmin({int limit = 800}) async {
    final rows = await _db.query(
      'jobs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_jobFromMap).toList();
  }

  JobEntity _jobFromMap(Map<String, Object?> m) {
    return JobEntity(
      id: m['id']! as String,
      senderId: m['sender_id']! as String,
      title: LocalizedString(
        uz: m['title_uz']! as String,
        ru: m['title_ru']! as String,
        en: m['title_en']! as String,
      ),
      description: LocalizedString(
        uz: m['description_uz']! as String,
        ru: m['description_ru']! as String,
        en: m['description_en']! as String,
      ),
      productType: LocalizedString(
        uz: m['product_type_uz'] as String? ?? '',
        ru: m['product_type_ru'] as String? ?? '',
        en: m['product_type_en'] as String? ?? '',
      ),
      pickupAddress: LocalizedString(
        uz: m['pickup_uz'] as String? ?? '',
        ru: m['pickup_ru'] as String? ?? '',
        en: m['pickup_en'] as String? ?? '',
      ),
      dropoffAddress: LocalizedString(
        uz: m['dropoff_uz'] as String? ?? '',
        ru: m['dropoff_ru'] as String? ?? '',
        en: m['dropoff_en'] as String? ?? '',
      ),
      productWeightKg: (m['product_weight_kg'] as num?)?.toDouble() ?? 0,
      productVolumeL: (m['product_volume_l'] as num?)?.toDouble() ?? 0,
      dimensionsMm: m['dimensions_mm'] as String? ?? '',
      volumeCategoryKey: (m['volume_category'] as String?)?.trim() ?? '',
      transportType: m['transport_type'] as String? ?? '',
      recipientName: m['recipient_name'] as String? ?? '',
      recipientPhone: m['recipient_phone'] as String? ?? '',
      imagePath: m['image_path'] as String? ?? '',
      deliverySpeed: DeliverySpeed.fromStorage(m['delivery_speed'] as String?),
      deliveryWindowStart: m['delivery_window_start'] as String?,
      deliveryWindowEnd: m['delivery_window_end'] as String?,
      startPriceCents: m['start_price_cents'] as int? ?? 0,
      floorPriceCents: m['floor_price_cents'] as int? ?? 0,
      finalPriceCents: m['final_price_cents'] as int?,
      currentPriceCents: m['current_price_cents'] as int?,
      fragile: (m['fragile'] as int? ?? 0) == 1,
      coldChain: (m['cold_chain'] as int? ?? 0) == 1,
      orderComments: m['order_comments'] as String?,
      paymentType: PaymentType.fromStorage(m['payment_type'] as String?),
      regionCode: (m['region_code'] as String?)?.trim() ?? '',
      districtCode: (m['district_code'] as String?)?.trim() ?? '',
      pickupLat: (m['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (m['pickup_lng'] as num?)?.toDouble(),
      dropoffLat: (m['dropoff_lat'] as num?)?.toDouble(),
      dropoffLng: (m['dropoff_lng'] as num?)?.toDouble(),
      pickupRegion: m['pickup_region'] as String?,
      pickupDistrictOrCity: m['pickup_district_city'] as String?,
      pickupRegionOriginal: m['pickup_region_original'] as String?,
      pickupDistrictOriginal: m['pickup_district_original'] as String?,
      pickupRegionKey: () {
        final k = m['pickup_region_key'] as String? ?? '';
        if (k.isNotEmpty) return k;
        return WorkAreaKeys.fromPickupDisplay(
          m['pickup_region'] as String?,
          m['pickup_district_city'] as String?,
        ).regionKey;
      }(),
      pickupDistrictKey: () {
        final k = m['pickup_district_key'] as String? ?? '';
        if (k.isNotEmpty) return k;
        return WorkAreaKeys.fromPickupDisplay(
          m['pickup_region'] as String?,
          m['pickup_district_city'] as String?,
        ).districtKey;
      }(),
      dropoffRegion: m['dropoff_region'] as String?,
      dropoffDistrictOrCity: m['dropoff_district_city'] as String?,
      status: JobStatus.fromStorage(m['status']! as String),
      auctionEndsAt: m['auction_ends_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(m['auction_ends_at']! as int),
      auctionStep: m['auction_step'] as int? ?? 0,
      auctionBidCount: m['auction_bid_count'] as int? ?? 0,
      leadingCourierId: m['leading_courier_id'] as String?,
      winnerCourierId: m['winner_courier_id'] as String?,
      courierLat: (m['courier_lat'] as num?)?.toDouble(),
      courierLng: (m['courier_lng'] as num?)?.toDouble(),
      courierLocationAt: m['courier_location_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              m['courier_location_at']! as int,
            ),
      courierHeading: (m['courier_heading'] as num?)?.toDouble(),
      courierSpeedMps: (m['courier_speed_mps'] as num?)?.toDouble(),
      courierAccuracyM: (m['courier_accuracy_m'] as num?)?.toDouble(),
      courierCompletionNote: m['courier_completion_note'] as String?,
      notifiedPickup1Km: (m['notify_pickup_1km'] as int? ?? 0) == 1,
      notifiedDropoff5Km: (m['notify_dropoff_5km'] as int? ?? 0) == 1,
      notifiedDropoff2Km: (m['notify_dropoff_2km'] as int? ?? 0) == 1,
      syncedFromSupabase: (m['synced_from_supabase'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
      winnerSelectedAt: m['winner_selected_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              m['winner_selected_at']! as int,
            ),
    );
  }

  Future<void> insertAuctionStep({
    required String id,
    required String jobId,
    required String courierId,
    required int stepIndex,
    required int priceCents,
    int? createdAtMs,
  }) async {
    await _db.insert('auction_steps', {
      'id': id,
      'job_id': jobId,
      'courier_id': courierId,
      'step_index': stepIndex,
      'price_cents': priceCents,
      'created_at': createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Idempotent (e.g. Supabase realtime + local join both deliver the same bid id).
  Future<void> insertAuctionStepIfAbsent({
    required String id,
    required String jobId,
    required String courierId,
    required int stepIndex,
    required int priceCents,
    int? createdAtMs,
  }) async {
    final rows = await _db.query(
      'auction_steps',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) return;
    await insertAuctionStep(
      id: id,
      jobId: jobId,
      courierId: courierId,
      stepIndex: stepIndex,
      priceCents: priceCents,
      createdAtMs: createdAtMs,
    );
  }

  Future<List<Map<String, Object?>>> listAuctionSteps(String jobId) async {
    return _db.query(
      'auction_steps',
      where: 'job_id = ?',
      whereArgs: [jobId],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> insertSupportRequest(SupportRequestEntity r) async {
    await _db.insert('support_requests', {
      'id': r.id,
      'user_id': r.userId,
      'user_name': r.userName,
      'user_phone': r.userPhone,
      'role': r.roleStorage,
      'request_type': r.requestType.toStorage(),
      'message': r.message,
      'created_at': r.createdAt.millisecondsSinceEpoch,
      'status': r.status.toStorage(),
    });
  }

  Future<List<SupportRequestEntity>> listSupportRequests() async {
    final rows = await _db.query(
      'support_requests',
      orderBy: 'created_at DESC',
    );
    return rows.map(_supportRequestFromMap).toList();
  }

  Future<SupportRequestEntity?> getSupportRequestById(String id) async {
    final rows = await _db.query(
      'support_requests',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _supportRequestFromMap(rows.first);
  }

  Future<void> updateSupportRequestStatus(
    String id,
    SupportRequestStatus status,
  ) async {
    await _db.update(
      'support_requests',
      {'status': status.toStorage()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  SupportRequestEntity _supportRequestFromMap(Map<String, Object?> m) {
    return SupportRequestEntity(
      id: m['id']! as String,
      userId: m['user_id']! as String,
      userName: m['user_name']! as String,
      userPhone: m['user_phone']! as String,
      roleStorage: m['role']! as String,
      requestType: SupportRequestType.fromStorage(m['request_type']! as String),
      message: m['message']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
      status: SupportRequestStatus.fromStorage(m['status']! as String),
    );
  }

  Future<void> insertFeedback(FeedbackEntity f) async {
    await _db.insert('feedback', {
      'id': f.id,
      'from_user_id': f.fromUserId,
      'to_user_id': f.toUserId,
      'job_id': f.jobId,
      'kind': f.kind.toStorage(),
      'category': f.category,
      'created_at': f.createdAt.millisecondsSinceEpoch,
    });
  }

  Future<bool> hasFeedbackFromUserForJob({
    required String fromUserId,
    required String jobId,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT 1 FROM feedback WHERE from_user_id = ? AND job_id = ? LIMIT 1',
      [fromUserId, jobId],
    );
    return rows.isNotEmpty;
  }

  Future<void> insertOrderFeedback(OrderFeedbackEntity row) async {
    await _db.insert(
      'order_feedback',
      {
        'id': row.id,
        'order_id': row.orderId,
        'from_user_id': row.fromUserId,
        'to_user_id': row.toUserId,
        'from_role': row.fromRole,
        'to_role': row.toRole,
        'rating': row.rating,
        'feedback_type': row.feedbackType.toStorage(),
        'complaint_category': row.complaintCategory,
        'praise_category': row.praiseCategory,
        'comment': row.comment,
        'created_at': row.createdAt.millisecondsSinceEpoch,
        'updated_at': row.updatedAt.millisecondsSinceEpoch,
        'complaint_status': row.complaintStatus,
        'admin_note': row.adminNote,
        'reviewed_by': row.reviewedBy,
        'reviewed_at': row.reviewedAt?.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  OrderFeedbackEntity? _orderFeedbackFromMap(Map<String, Object?> m) {
    final id = m['id'] as String?;
    if (id == null || id.isEmpty) return null;
    return OrderFeedbackEntity(
      id: id,
      orderId: m['order_id']! as String,
      fromUserId: m['from_user_id']! as String,
      toUserId: m['to_user_id']! as String,
      fromRole: m['from_role']! as String,
      toRole: m['to_role']! as String,
      rating: (m['rating'] as int?) ?? 1,
      feedbackType:
          OrderFeedbackType.fromStorage(m['feedback_type'] as String? ?? 'rating'),
      complaintCategory: m['complaint_category'] as String?,
      praiseCategory: m['praise_category'] as String?,
      comment: m['comment'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at']! as int),
      complaintStatus: m['complaint_status'] as String?,
      adminNote: m['admin_note'] as String?,
      reviewedBy: m['reviewed_by'] as String?,
      reviewedAt: m['reviewed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['reviewed_at']! as int)
          : null,
    );
  }

  Future<OrderFeedbackEntity?> getOrderFeedbackByFromUser({
    required String orderId,
    required String fromUserId,
  }) async {
    final rows = await _db.query(
      'order_feedback',
      where: 'order_id = ? AND from_user_id = ?',
      whereArgs: [orderId, fromUserId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _orderFeedbackFromMap(rows.first);
  }

  /// Eski `feedback` yoki yangi `order_feedback` — bittasi bo‘lsa true.
  Future<bool> hasAnyFeedbackFromUserForOrder({
    required String fromUserId,
    required String orderId,
  }) async {
    final n = await _db.rawQuery(
      '''
SELECT 1 FROM order_feedback WHERE from_user_id = ? AND order_id = ?
UNION
SELECT 1 FROM feedback WHERE from_user_id = ? AND job_id = ?
LIMIT 1
''',
      [fromUserId, orderId, fromUserId, orderId],
    );
    return n.isNotEmpty;
  }

  Future<int> countOrderFeedbackByType(String feedbackType) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM order_feedback WHERE feedback_type = ?',
      [feedbackType],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countFeedbackToUser(String userId, FeedbackKind kind) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM feedback WHERE to_user_id = ? AND kind = ?',
      [userId, kind.toStorage()],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<List<RegionRecord>> listRegions() async {
    final rows = await _db.query('regions', orderBy: 'code ASC');
    return rows
        .map(
          (m) => RegionRecord(
            code: m['code']! as String,
            name: LocalizedString(
              uz: m['name_uz']! as String,
              ru: m['name_ru']! as String,
              en: m['name_en']! as String,
            ),
          ),
        )
        .toList();
  }

  Future<List<DistrictRecord>> listDistricts(String regionCode) async {
    final rows = await _db.query(
      'districts',
      where: 'region_code = ?',
      whereArgs: [regionCode],
      orderBy: 'code ASC',
    );
    return rows
        .map(
          (m) => DistrictRecord(
            code: m['code']! as String,
            regionCode: m['region_code']! as String,
            name: LocalizedString(
              uz: m['name_uz']! as String,
              ru: m['name_ru']! as String,
              en: m['name_en']! as String,
            ),
          ),
        )
        .toList();
  }

  Future<void> insertBid(BidEntity bid) async {
    await _db.insert(
      'bids',
      {
        'id': bid.id,
        'job_id': bid.jobId,
        'courier_id': bid.courierId,
        'amount_cents': bid.amountCents,
        'created_at': bid.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BidEntity>> listBidsForJob(String jobId) async {
    final rows = await _db.query(
      'bids',
      where: 'job_id = ?',
      whereArgs: [jobId],
      orderBy: 'amount_cents DESC, created_at ASC',
    );
    return rows
        .map(
          (m) => BidEntity(
            id: m['id']! as String,
            jobId: m['job_id']! as String,
            courierId: m['courier_id']! as String,
            amountCents: m['amount_cents']! as int,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              m['created_at']! as int,
            ),
          ),
        )
        .toList();
  }

  Future<int> countUsers() async {
    final rows = await _db.rawQuery('SELECT COUNT(*) AS c FROM users');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countJobs() async {
    final rows = await _db.rawQuery('SELECT COUNT(*) AS c FROM jobs');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countJobsByStatus(String status) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM jobs WHERE status = ?',
      [status],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countUsersByRole(String role) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM users WHERE role = ?',
      [role],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countBlockedUsers() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM users WHERE blocked = 1',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countFeedback(FeedbackKind kind) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM feedback WHERE kind = ?',
      [kind.toStorage()],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countJobsInRegion(String regionCode) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM jobs WHERE region_code = ?',
      [regionCode],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countJobsInRegionWithStatus(
    String regionCode,
    String status,
  ) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM jobs WHERE region_code = ? AND status = ?',
      [regionCode, status],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countJobsInDistrict(String districtCode) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM jobs WHERE district_code = ?',
      [districtCode],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countJobsNotTerminal() async {
    final rows = await _db.rawQuery(
      "SELECT COUNT(*) AS c FROM jobs WHERE status NOT IN ('completed','cancelled')",
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countSenders() async {
    final rows = await _db.rawQuery(
      "SELECT COUNT(*) AS c FROM users WHERE role = 'sender'",
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Returns job ids that moved to `assigned` (winner picked) for remote sync.
  Future<List<String>> processExpiredAuctions() async {
    final assignedIds = <String>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await _db.query(
      'jobs',
      where:
          'status = ? AND auction_ends_at IS NOT NULL AND auction_ends_at < ? '
          'AND IFNULL(synced_from_supabase, 0) = 0',
      whereArgs: [JobStatus.auctionLive.toStorage(), now],
    );
    for (final m in rows) {
      final job = _jobFromMap(m);
      final winner = job.leadingCourierId;
      if (winner == null) {
        await updateJob(
          job.copyWith(
            status: JobStatus.posted,
            auctionEndsAt: null,
            leadingCourierId: null,
            auctionStep: 0,
            currentPriceCents: null,
          ),
        );
        continue;
      }
      final finalPrice = job.currentPriceCents ??
          AuctionMath.committedPriceCents(
            job.startPriceCents,
            job.auctionStep,
            job.floorPriceCents,
          );
      await updateJob(
        job.copyWith(
          status: JobStatus.assigned,
          winnerCourierId: winner,
          finalPriceCents: finalPrice,
          auctionEndsAt: null,
          currentPriceCents: null,
          winnerSelectedAt: job.winnerSelectedAt ?? DateTime.now(),
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[auction] finalize order=${job.id} winner=$winner finalPrice=$finalPrice (local_unsynced)',
        );
      }
      assignedIds.add(job.id);
    }
    return assignedIds;
  }

  List<({String code, int count})> _rowsToCodeCounts(List<Map<String, Object?>> rows) {
    final out = <({String code, int count})>[];
    for (final m in rows) {
      final c = m['code']?.toString().trim() ?? '';
      if (c.isEmpty) continue;
      final n = (m['c'] as num?)?.toInt() ?? 0;
      out.add((code: c, count: n));
    }
    return out;
  }

  /// Buyurtmada shikoyat (yangi yoki eski jadval) bor-yo‘qligi.
  Future<Set<String>> adminOrderIdsWithComplaint() async {
    final s = <String>{};
    final r1 = await _db.rawQuery(
      "SELECT DISTINCT order_id AS oid FROM order_feedback WHERE feedback_type = 'complaint'",
    );
    for (final m in r1) {
      final id = m['oid']?.toString();
      if (id != null && id.isNotEmpty) s.add(id);
    }
    final r2 = await _db.rawQuery(
      "SELECT DISTINCT job_id AS oid FROM feedback WHERE kind = 'complaint'",
    );
    for (final m in r2) {
      final id = m['oid']?.toString();
      if (id != null && id.isNotEmpty) s.add(id);
    }
    return s;
  }

  Future<List<OrderFeedbackEntity>> listAdminOrderFeedback({
    int limit = 400,
    String? feedbackType,
    bool? lowRatingOnly,
    bool? complaintFromSenderOnly,
  }) async {
    var where = '1=1';
    final args = <Object?>[];
    if (feedbackType != null && feedbackType.isNotEmpty) {
      where += ' AND feedback_type = ?';
      args.add(feedbackType);
    }
    if (lowRatingOnly == true) {
      where += ' AND rating <= 2';
    }
    if (complaintFromSenderOnly == true) {
      where += " AND from_role = 'sender' AND to_role = 'courier'";
    }
    final rows = await _db.query(
      'order_feedback',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_orderFeedbackFromMap).whereType<OrderFeedbackEntity>().toList();
  }

  Future<void> updateOrderFeedbackModeration({
    required String feedbackId,
    required String complaintStatus,
    String? adminNote,
    required String reviewedByUserId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.update(
      'order_feedback',
      {
        'complaint_status': complaintStatus,
        'admin_note': adminNote,
        'reviewed_by': reviewedByUserId,
        'reviewed_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [feedbackId],
    );
  }

  Future<AdminOperationalSnapshot> loadAdminOperationalSnapshot() async {
    final usersTotal = await countUsers();
    final senders = await countSenders();
    final couriers = await countUsersByRole('courier');
    final jobsTotal = await countJobs();
    final jobsPosted = await countJobsByStatus(JobStatus.posted.toStorage());
    final jobsAuctionLive =
        await countJobsByStatus(JobStatus.auctionLive.toStorage());
    final jobsAssigned = await countJobsByStatus(JobStatus.assigned.toStorage());
    final jobsPickedUp = await countJobsByStatus(JobStatus.pickedUp.toStorage());
    final jobsDelivered = await countJobsByStatus(JobStatus.delivered.toStorage());
    final jobsCompleted =
        await countJobsByStatus(JobStatus.completed.toStorage());
    final jobsCancelled =
        await countJobsByStatus(JobStatus.cancelled.toStorage());
    final blockedUsers = await countBlockedUsers();

    final ofTotalRow =
        await _db.rawQuery('SELECT COUNT(*) AS c FROM order_feedback');
    final orderFeedbackTotal = Sqflite.firstIntValue(ofTotalRow) ?? 0;
    final ofAvgRow =
        await _db.rawQuery('SELECT AVG(rating) AS a FROM order_feedback');
    final orderFeedbackAvgRating =
        (ofAvgRow.first['a'] as num?)?.toDouble() ?? 0;
    final orderFeedbackComplaints = await countOrderFeedbackByType('complaint');
    final orderFeedbackPraises = await countOrderFeedbackByType('praise');
    final legacyComplaints = await countFeedback(FeedbackKind.complaint);

    final aucRow = await _db.rawQuery(
      '''
SELECT COUNT(*) AS c FROM jobs
WHERE IFNULL(auction_bid_count, 0) > 0
   OR IFNULL(auction_step, 0) > 0
   OR status = ?
''',
      [JobStatus.auctionLive.toStorage()],
    );
    final auctionsTouchedCount = Sqflite.firstIntValue(aucRow) ?? 0;

    final avgBidRow = await _db.rawQuery(
      'SELECT AVG(auction_bid_count) AS a FROM jobs WHERE IFNULL(auction_bid_count, 0) > 0',
    );
    final avgAuctionBidCount =
        (avgBidRow.first['a'] as num?)?.toDouble() ?? 0;

    final discRow = await _db.rawQuery(
      '''
SELECT AVG(start_price_cents - final_price_cents) AS a
FROM jobs
WHERE final_price_cents IS NOT NULL
  AND start_price_cents >= final_price_cents
''',
    );
    final avgFinalDiscountCents =
        (discRow.first['a'] as num?)?.toDouble() ?? 0;

    final trackRow = await _db.rawQuery(
      '''
SELECT COUNT(*) AS c FROM jobs
WHERE status IN (?, ?)
  AND courier_lat IS NOT NULL
  AND courier_lng IS NOT NULL
''',
      [JobStatus.pickedUp.toStorage(), JobStatus.delivered.toStorage()],
    );
    final activeDeliveryTrackingCount =
        Sqflite.firstIntValue(trackRow) ?? 0;

    final topCRows = await _db.rawQuery(
      '''
SELECT to_user_id AS uid, COUNT(*) AS c
FROM order_feedback
WHERE feedback_type = 'complaint'
GROUP BY to_user_id
ORDER BY c DESC
LIMIT 8
''',
    );
    final topComplaintUserIds = <({String userId, int count})>[];
    for (final m in topCRows) {
      final uid = m['uid']?.toString() ?? '';
      if (uid.isEmpty) continue;
      topComplaintUserIds.add((
        userId: uid,
        count: (m['c'] as num?)?.toInt() ?? 0,
      ));
    }

    final topKRows = await _db.rawQuery(
      '''
SELECT id AS uid, rating AS r FROM users
WHERE role = 'courier'
ORDER BY rating DESC
LIMIT 8
''',
    );
    final topCourierRatings = <({String userId, double rating})>[];
    for (final m in topKRows) {
      final uid = m['uid']?.toString() ?? '';
      if (uid.isEmpty) continue;
      topCourierRatings.add((
        userId: uid,
        rating: (m['r'] as num?)?.toDouble() ?? 0,
      ));
    }

    final ur = await _db.rawQuery(
      '''
SELECT region_code AS code, COUNT(*) AS c FROM users
WHERE region_code IS NOT NULL AND TRIM(region_code) != ''
GROUP BY region_code
ORDER BY c DESC
LIMIT 32
''',
    );
    final jr = await _db.rawQuery(
      '''
SELECT region_code AS code, COUNT(*) AS c FROM jobs
WHERE region_code IS NOT NULL AND TRIM(region_code) != ''
GROUP BY region_code
ORDER BY c DESC
LIMIT 32
''',
    );
    final ud = await _db.rawQuery(
      '''
SELECT district_code AS code, COUNT(*) AS c FROM users
WHERE district_code IS NOT NULL AND TRIM(district_code) != ''
GROUP BY district_code
ORDER BY c DESC
LIMIT 40
''',
    );
    final jd = await _db.rawQuery(
      '''
SELECT district_code AS code, COUNT(*) AS c FROM jobs
WHERE district_code IS NOT NULL AND TRIM(district_code) != ''
GROUP BY district_code
ORDER BY c DESC
LIMIT 40
''',
    );

    return AdminOperationalSnapshot(
      usersTotal: usersTotal,
      senders: senders,
      couriers: couriers,
      jobsTotal: jobsTotal,
      jobsPosted: jobsPosted,
      jobsAuctionLive: jobsAuctionLive,
      jobsAssigned: jobsAssigned,
      jobsPickedUp: jobsPickedUp,
      jobsDelivered: jobsDelivered,
      jobsCompleted: jobsCompleted,
      jobsCancelled: jobsCancelled,
      blockedUsers: blockedUsers,
      orderFeedbackTotal: orderFeedbackTotal,
      orderFeedbackAvgRating: orderFeedbackAvgRating,
      orderFeedbackComplaints: orderFeedbackComplaints,
      orderFeedbackPraises: orderFeedbackPraises,
      legacyComplaints: legacyComplaints,
      auctionsTouchedCount: auctionsTouchedCount,
      avgAuctionBidCount: avgAuctionBidCount,
      avgFinalDiscountCents: avgFinalDiscountCents,
      activeDeliveryTrackingCount: activeDeliveryTrackingCount,
      topComplaintUserIds: topComplaintUserIds,
      topCourierRatings: topCourierRatings,
      usersByRegion: _rowsToCodeCounts(ur),
      jobsByRegion: _rowsToCodeCounts(jr),
      usersByDistrict: _rowsToCodeCounts(ud),
      jobsByDistrict: _rowsToCodeCounts(jd),
    );
  }
}