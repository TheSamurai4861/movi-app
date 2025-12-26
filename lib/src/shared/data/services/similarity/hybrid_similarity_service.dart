// ignore_for_file: deprecated_member_use

import 'package:movi/src/shared/domain/services/similarity_service.dart';

class HybridSimilarityService implements SimilarityService {
  const HybridSimilarityService();

  @override
  double score(String original, String result) {
    final o = _normalize(original);
    final r = _normalize(result);
    if (o.isEmpty && r.isEmpty) return 1.0;
    if (o.isEmpty || r.isEmpty) return 0.0;

    final jw = _jaroWinklerSimilarity(o, r);
    final lv = _levenshteinSimilarity(o, r);

    final s1Len = o.length;
    final s2Len = r.length;
    final avgLen = (s1Len + s2Len) / 2.0;
    final lengthDiff = (s1Len - s2Len).abs();
    final lengthRatio = avgLen > 0 ? lengthDiff / avgLen : 0.0;
    final prefixSim = _prefixSimilarity(o, r);

    double jwWeight;
    double lvWeight;
    if (avgLen < 10 || prefixSim > 0.7) {
      jwWeight = 0.7;
      lvWeight = 0.3;
    } else if (avgLen > 50) {
      jwWeight = 0.3;
      lvWeight = 0.7;
    } else if (lengthRatio > 0.5) {
      jwWeight = 0.4;
      lvWeight = 0.6;
    } else {
      jwWeight = 0.5;
      lvWeight = 0.5;
    }

    final weighted = (jw * jwWeight) + (lv * lvWeight);
    final agreement = 1.0 - (jw - lv).abs();
    final agreementBonus = agreement > 0.8 ? 0.05 : 0.0;
    final average = (jw + lv) / 2.0;
    final lowScorePenalty = average < 0.3 ? 0.05 : 0.0;

    final s = weighted + agreementBonus - lowScorePenalty;
    return s.clamp(0.0, 1.0);
  }

  String _normalize(String s) {
    final lower = s.toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    return normalized.trim();
  }

  double _prefixSimilarity(String s1, String s2) {
    final minLen = s1.length < s2.length ? s1.length : s2.length;
    if (minLen == 0) return 0.0;
    var common = 0;
    final maxCheck = minLen < 10 ? minLen : 10;
    for (var i = 0; i < maxCheck; i++) {
      if (s1.codeUnitAt(i) == s2.codeUnitAt(i)) {
        common++;
      } else {
        break;
      }
    }
    return common / maxCheck;
  }

  double _jaroWinklerSimilarity(String s1, String s2) {
    final jaro = _jaroSimilarity(s1, s2);
    if (jaro < 0.7) return jaro;
    final prefixLen = _commonPrefixLength(s1, s2);
    final clamped = prefixLen < 4 ? prefixLen : 4;
    return jaro + (0.1 * clamped * (1.0 - jaro));
  }

  int _commonPrefixLength(String s1, String s2) {
    final minLen = s1.length < s2.length ? s1.length : s2.length;
    var i = 0;
    while (i < minLen) {
      if (s1.codeUnitAt(i) != s2.codeUnitAt(i)) break;
      i++;
    }
    return i;
  }

  double _jaroSimilarity(String s1, String s2) {
    final l1 = s1.length;
    final l2 = s2.length;
    if (l1 == 0 && l2 == 0) return 1.0;
    if (l1 == 0 || l2 == 0) return 0.0;

    final matchWindow = (l1 > l2 ? l1 : l2) ~/ 2 - 1;
    final window = matchWindow < 0 ? 0 : matchWindow;
    final s1Matches = List<bool>.filled(l1, false);
    final s2Matches = List<bool>.filled(l2, false);

    var matches = 0;
    var transpositions = 0;

    for (var i = 0; i < l1; i++) {
      final start = i - window < 0 ? 0 : i - window;
      final end = i + window + 1 > l2 ? l2 : i + window + 1;
      for (var j = start; j < end; j++) {
        if (s2Matches[j]) continue;
        if (s1.codeUnitAt(i) != s2.codeUnitAt(j)) continue;
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    var k = 0;
    for (var i = 0; i < l1; i++) {
      if (!s1Matches[i]) continue;
      while (k < l2 && !s2Matches[k]) {
        k++;
      }
      if (k >= l2) break;
      if (s1.codeUnitAt(i) != s2.codeUnitAt(k)) {
        transpositions++;
      }
      k++;
    }

    final m = matches.toDouble();
    final jaro = (m / l1 + m / l2 + (m - transpositions / 2.0) / m) / 3.0;
    return jaro;
  }

  double _levenshteinSimilarity(String s1, String s2) {
    final l1 = s1.length;
    final l2 = s2.length;
    if (l1 == 0 && l2 == 0) return 1.0;
    if (l1 == 0 || l2 == 0) return 0.0;
    final dist = _levenshteinDistance(s1, s2);
    final maxLen = l1 > l2 ? l1 : l2;
    return 1.0 - dist / maxLen;
  }

  int _levenshteinDistance(String s1, String s2) {
    final l1 = s1.length;
    final l2 = s2.length;
    if (l1 == 0) return l2;
    if (l2 == 0) return l1;
    final matrix = List.generate(l1 + 1, (_) => List<int>.filled(l2 + 1, 0));
    for (var i = 0; i <= l1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= l2; j++) {
      matrix[0][j] = j;
    }
    for (var i = 1; i <= l1; i++) {
      for (var j = 1; j <= l2; j++) {
        final cost = s1.codeUnitAt(i - 1) == s2.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = matrix[i - 1][j] + 1;
        final insertion = matrix[i][j - 1] + 1;
        final substitution = matrix[i - 1][j - 1] + cost;
        final min1 = deletion < insertion ? deletion : insertion;
        matrix[i][j] = min1 < substitution ? min1 : substitution;
      }
    }
    return matrix[l1][l2];
  }
}
