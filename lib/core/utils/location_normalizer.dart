/// Single source of truth for region/district text → compact comparable keys.
///
/// Used for: sender pickup keys, courier work-area keys, resolver haystack,
/// and courier feed matching. Do not compare raw UI strings in business logic.
///
/// **District keys** are lowercase, no spaces (e.g. `mirzoulugbek`, `yangihayot`).
abstract final class LocationKeyNormalizer {
  LocationKeyNormalizer._();

  /// Standalone tokens dropped entirely (admin words only).
  static const Set<String> _removableStandaloneTokens = {
    'tumani',
    'tuman',
    'shahri',
    'shahar',
    'shaharcha',
    'viloyati',
    'viloyat',
    'district',
    'rayon',
    'raion',
    'city',
    'область',
    'район',
    'город',
    'г',
    'г.',
    'unknown',
    'n/a',
    'na',
  };

  /// Stripped repeatedly from the **end** of each remaining token.
  static const List<String> _trailingSuffixesLongestFirst = [
    'tumani',
    'viloyati',
    'shahri',
    'tuman',
    'shahar',
    'viloyat',
    'district',
    'rayon',
    'city',
  ];

  /// Latin / Cyrillic / common OSM spellings → one canonical **compact** district key.
  static const Map<String, String> _districtAliases = {
    // Toshkent shahri tumanlari (canonical compact keys)
    'bektemir': 'bektemir',
    'chilonzor': 'chilonzor',
    'chilanzar': 'chilonzor',
    'chilonzar': 'chilonzor',
    'mirobod': 'mirobod',
    'mirabad': 'mirobod',
    'mirzoulugbek': 'mirzoulugbek',
    'mirzoulugbektumani': 'mirzoulugbek',
    'olmazor': 'olmazor',
    'almazar': 'olmazor',
    'sergeli': 'sergeli',
    'sergelitumani': 'sergeli',
    'shayxontohur': 'shayxontohur',
    'shaykhantahur': 'shayxontohur',
    'sheyxontohur': 'shayxontohur',
    'uchtepa': 'uchtepa',
    'uchtepatumani': 'uchtepa',
    'yakkasaroy': 'yakkasaroy',
    'yakkassaray': 'yakkasaroy',
    'yaqqasaroy': 'yakkasaroy',
    'yaqqassaroy': 'yakkasaroy',
    'yashnobod': 'yashnobod',
    'yashnobadtumani': 'yashnobod',
    'yunusobod': 'yunusobod',
    'yunusabad': 'yunusobod',
    'yunusobodtumani': 'yunusobod',
    'yangihayot': 'yangihayot',
    'yangihayottumani': 'yangihayot',
    // Mahalla / eski nomlar → tuman
    'aviasozlar': 'yashnobod',
    'aviasozlarmahallasi': 'yashnobod',
    'qushbegi': 'yashnobod',
    // Ko‘p uchraydigan variantlar
    'toshkent': 'toshkent',
    'tashkent': 'toshkent',
    'toshkentshahri': 'toshkent',
    'tashkentcity': 'toshkent',
  };

  static const Map<String, String> _regionAliases = {
    'toshkentshahri': 'toshkent',
    'toshkentcity': 'toshkent',
    'tashkentcity': 'toshkent',
    'ташкент': 'toshkent',
    'гташкент': 'toshkent',
    'toshkentviloyati': 'toshkentviloyati',
    'toshkentregion': 'toshkentviloyati',
  };

  static final RegExp _junkDistrictCode = RegExp(r'^s\d+$', caseSensitive: false);

  /// True for S2, empty, unknown, etc. — not a real district label.
  static bool isUnusableDistrictRaw(String? value) {
    if (value == null || value.trim().isEmpty) return true;
    final raw = value.trim().toLowerCase();
    if (raw == 'unknown' || raw == 'n/a' || raw == 'null') return true;
    final n = normalizeLocationKey(value);
    if (n.isEmpty) return true;
    if (n.length <= 1) return true;
    if (_junkDistrictCode.hasMatch(n)) return true;
    return false;
  }

  /// Maps canonical district key → normalized substring forms accepted in haystacks.
  static final Map<String, Set<String>> _districtFormsByCanonical = () {
    final m = <String, Set<String>>{};
    void add(String canonical, String form) {
      if (form.isEmpty) return;
      m.putIfAbsent(canonical, () => <String>{}).add(form);
    }

    for (final e in _districtAliases.entries) {
      add(e.value, e.key);
      add(e.value, e.value);
    }
    return m;
  }();

  static String _foldApostrophesAndLatin(String v) {
    return v
        .replaceAll('’', "'")
        .replaceAll('`', "'")
        .replaceAll('ʻ', "'")
        .replaceAll('‘', "'")
        .replaceAll('ʼ', "'")
        .replaceAll('′', "'")
        .replaceAll('g‘', 'g')
        .replaceAll("g'", 'g')
        .replaceAll('o‘', 'o')
        .replaceAll("o'", 'o');
  }

  /// Public: normalized compact string (lowercase, no spaces, suffixes stripped).
  static String normalizeLocationKey(String? value) {
    if (value == null) return '';
    var v = value.toLowerCase().trim();
    if (v.isEmpty) return '';

    v = _foldApostrophesAndLatin(v);

    v = v.replaceAll(RegExp(r'[^a-zа-яё0-9\s]'), ' ');
    v = v.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (v.isEmpty) return '';

    final rawTokens = v.split(' ');
    final kept = <String>[];
    for (var t in rawTokens) {
      if (t.isEmpty) continue;
      if (_removableStandaloneTokens.contains(t)) continue;
      t = _stripTrailingAdminSuffixes(t);
      if (t.isEmpty) continue;
      kept.add(t);
    }
    return _mergeDistrictCompounds(kept).join();
  }

  /// [yangi] + [hayot] → single token (any order within stream).
  static List<String> _mergeDistrictCompounds(List<String> tokens) {
    if (tokens.isEmpty) return tokens;
    final out = <String>[];
    var i = 0;
    while (i < tokens.length) {
      final a = tokens[i];
      final b = i + 1 < tokens.length ? tokens[i + 1] : '';
      if ((a == 'yangi' && b == 'hayot') || (a == 'hayot' && b == 'yangi')) {
        out.add('yangihayot');
        i += 2;
        continue;
      }
      out.add(a);
      i++;
    }
    return out;
  }

  static String _stripTrailingAdminSuffixes(String token) {
    var s = token;
    var changed = true;
    while (changed) {
      changed = false;
      for (final suf in _trailingSuffixesLongestFirst) {
        if (s.endsWith(suf) && s.length > suf.length) {
          s = s.substring(0, s.length - suf.length);
          changed = true;
          break;
        }
      }
    }
    return s;
  }

  /// After [normalizeLocationKey] (compact) or on compact input.
  static String canonicalDistrictKey(String normalizedCompact) {
    if (normalizedCompact.isEmpty) return '';
    return _districtAliases[normalizedCompact] ?? normalizedCompact;
  }

  /// After [normalizeLocationKey] (compact).
  static String canonicalRegionKey(String normalizedCompact) {
    if (normalizedCompact.isEmpty) return '';
    return _regionAliases[normalizedCompact] ?? normalizedCompact;
  }

  /// True if [haystackNorm] (already normalized compact) refers to [districtCanonical].
  static bool haystackContainsDistrictKey(
    String haystackNorm,
    String districtCanonical,
  ) {
    if (haystackNorm.isEmpty || districtCanonical.isEmpty) return false;
    if (haystackNorm.contains(districtCanonical)) return true;
    final forms = _districtFormsByCanonical[districtCanonical];
    if (forms == null) return false;
    for (final f in forms) {
      if (f.isNotEmpty && haystackNorm.contains(f)) return true;
    }
    return false;
  }

  /// Raw label → canonical compact district key (empty if unusable).
  static String districtKeyFromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final n = normalizeLocationKey(raw);
    if (n.isEmpty) return '';
    if (_junkDistrictCode.hasMatch(n)) return '';
    if (n.length <= 2 && !_districtAliases.containsKey(n)) return '';
    return canonicalDistrictKey(n);
  }

  /// Convenience: raw label → canonical region key.
  static String regionKeyFromRaw(String? raw) {
    return canonicalRegionKey(normalizeLocationKey(raw));
  }

  /// Alias: canonical district key from raw display (filter / migration friendly).
  static String canonicalLocationKey(String? raw) => districtKeyFromRaw(raw);

  /// Long address blob for resolver scoring (region + district + city lines).
  static String normalizeAddressHaystack(String? blob) {
    return normalizeLocationKey(blob);
  }
}
