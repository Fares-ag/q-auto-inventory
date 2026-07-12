import 'dart:math' as math;

/// Parsed structured asset id: [prefix] + separator + numeric suffix.
class ParsedAssetId {
  const ParsedAssetId({
    required this.prefix,
    required this.numericValue,
    required this.digitWidth,
    required this.separator,
  });

  final String prefix;
  final int numericValue;
  final int digitWidth;
  final String separator;
}

ParsedAssetId? tryParseAssetId(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;

  var m = RegExp(r'^(.+?)([\-_])(\d+)$').firstMatch(t);
  if (m != null) {
    final prefix = m.group(1)!.trim();
    final sep = m.group(2)!;
    final numStr = m.group(3)!;
    if (prefix.isEmpty) return null;
    return ParsedAssetId(
      prefix: prefix,
      numericValue: int.tryParse(numStr) ?? 0,
      digitWidth: numStr.length,
      separator: sep,
    );
  }

  m = RegExp(r'^([A-Za-z][A-Za-z0-9]{0,19})(\d+)$').firstMatch(t);
  if (m != null) {
    final numStr = m.group(2)!;
    return ParsedAssetId(
      prefix: m.group(1)!,
      numericValue: int.tryParse(numStr) ?? 0,
      digitWidth: numStr.length,
      separator: '',
    );
  }
  return null;
}

bool prefixesMatch(String a, String b) => a.trim().toUpperCase() == b.trim().toUpperCase();

/// If [prefix] is a 4-digit calendar year (2000–2099), returns that year.
int? yearFromPrefix(String prefix) {
  final t = prefix.trim();
  if (!RegExp(r'^\d{4}$').hasMatch(t)) return null;
  final y = int.tryParse(t);
  if (y == null || y < 2000 || y > 2099) return null;
  return y;
}

/// Picks the next id after scanning live [assetIds] and the Firestore counter.
class AssetIdSuggestion {
  const AssetIdSuggestion({
    required this.id,
    required this.prefix,
    required this.nextNumber,
    required this.patternNote,
    required this.matchedAssets,
  });

  final String id;
  final String prefix;
  final int nextNumber;
  final String patternNote;
  final int matchedAssets;
}

String? dominantPrefixAmong(Iterable<String> assetIds) {
  final counts = <String, int>{};
  for (final raw in assetIds) {
    final p = tryParseAssetId(raw);
    if (p == null) continue;
    final k = p.prefix.toUpperCase();
    counts[k] = (counts[k] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

AssetIdSuggestion _buildSuggestionForPrefix({
  required List<String> assetIds,
  required String prefix,
  required int counterFloor,
  int? minNumericWidthWhenNoMatches,
}) {
  var maxNum = math.max(0, counterFloor);
  var maxWidth = 1;
  var matched = 0;
  var hyphenCount = 0;
  var underscoreCount = 0;

  for (final raw in assetIds) {
    final p = tryParseAssetId(raw);
    if (p == null) continue;
    if (!prefixesMatch(p.prefix, prefix)) continue;
    matched++;
    if (p.numericValue > maxNum) maxNum = p.numericValue;
    maxWidth = math.max(maxWidth, p.digitWidth);
    if (p.separator == '-') hyphenCount++;
    if (p.separator == '_') underscoreCount++;
  }

  if (matched == 0 &&
      minNumericWidthWhenNoMatches != null &&
      minNumericWidthWhenNoMatches > 1) {
    maxWidth = math.max(maxWidth, minNumericWidthWhenNoMatches);
  }

  final next = maxNum + 1;
  final sep = underscoreCount > hyphenCount ? '_' : '-';
  final padFromYearHint = matched == 0 &&
      minNumericWidthWhenNoMatches != null &&
      minNumericWidthWhenNoMatches > 1;
  final usePad = maxWidth > 1 && (matched > 0 || padFromYearHint);
  final body = usePad ? next.toString().padLeft(maxWidth, '0') : '$next';
  final id = sep.isEmpty ? '$prefix$body' : '$prefix$sep$body';

  final note = matched == 0
      ? counterFloor > 0
          ? 'Next after Firestore counter for $prefix (no matching IDs in the scanned list).'
          : 'Starting sequence for $prefix. Zero-padding follows existing IDs when more assets exist.'
      : 'Next in sequence for $prefix ($matched assets matched).';

  return AssetIdSuggestion(
    id: id,
    prefix: prefix,
    nextNumber: next,
    patternNote: note,
    matchedAssets: matched,
  );
}

/// When the chosen prefix is a past calendar year (e.g. 2025), use the current
/// year (2026) instead, keeping hyphen/underscore and numeric width from other
/// year-style IDs.
AssetIdSuggestion _rollYearPrefixToCurrentCalendarYear(
  AssetIdSuggestion candidate,
  List<String> assetIds,
  int currentYear,
) {
  final prefixYear = yearFromPrefix(candidate.prefix);
  if (prefixYear == null || prefixYear >= currentYear) return candidate;

  final sample = tryParseAssetId(candidate.id);
  final sep = sample?.separator;
  if (sep == null || sep.isEmpty) return candidate;

  var inheritedWidth = 1;
  for (final raw in assetIds) {
    final p = tryParseAssetId(raw);
    if (p == null) continue;
    if (p.separator != sep) continue;
    if (yearFromPrefix(p.prefix) == null) continue;
    inheritedWidth = math.max(inheritedWidth, p.digitWidth);
  }

  final rolled = _buildSuggestionForPrefix(
    assetIds: assetIds,
    prefix: '$currentYear',
    counterFloor: 0,
    minNumericWidthWhenNoMatches:
        inheritedWidth > 1 ? inheritedWidth : null,
  );

  final suffix = rolled.matchedAssets == 0
      ? ' New items use $currentYear (same width as $prefixYear-coded assets).'
      : '';

  return AssetIdSuggestion(
    id: rolled.id,
    prefix: rolled.prefix,
    nextNumber: rolled.nextNumber,
    patternNote: '${rolled.patternNote}$suffix',
    matchedAssets: rolled.matchedAssets,
  );
}

AssetIdSuggestion suggestNextAssetId({
  required Iterable<String> assetIds,
  required String counterPrefix,
  required int counterCurrentValue,
  DateTime? referenceDate,
}) {
  final list = assetIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final currentYear = (referenceDate ?? DateTime.now()).year;
  final base =
      counterPrefix.trim().isEmpty ? 'ASSET' : counterPrefix.trim();

  final primaryBuilt = _buildSuggestionForPrefix(
    assetIds: list,
    prefix: base,
    counterFloor: counterCurrentValue,
  );
  final primary = _rollYearPrefixToCurrentCalendarYear(
    primaryBuilt,
    list,
    currentYear,
  );

  if (primaryBuilt.matchedAssets > 0) return primary;

  final dom = dominantPrefixAmong(list);
  if (dom != null && !prefixesMatch(dom, base)) {
    final altBase = _buildSuggestionForPrefix(
      assetIds: list,
      prefix: dom,
      counterFloor: 0,
    );
    if (altBase.matchedAssets > 0) {
      final alt = _rollYearPrefixToCurrentCalendarYear(
        altBase,
        list,
        currentYear,
      );
      return AssetIdSuggestion(
        id: alt.id,
        prefix: alt.prefix,
        nextNumber: alt.nextNumber,
        patternNote:
            '${alt.patternNote} Inferred prefix from existing assets.',
        matchedAssets: alt.matchedAssets,
      );
    }
  }

  return primary;
}
