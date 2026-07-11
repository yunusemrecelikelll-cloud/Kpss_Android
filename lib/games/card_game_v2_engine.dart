import 'dart:math';
import '../models/topic.dart';

/// Kart Oyunu V2 — JS: src/js/cardgame.js `CardGameV2`.
/// Açık kartlar, 2 sütun (sol terim / sağ tanım), tek bir konuya özel.
class Match2Card {
  final int pairId;
  final String text;
  bool matched;
  Match2Card({required this.pairId, required this.text, this.matched = false});
}

class WrongPair {
  final int leftIdx;
  final int rightIdx;
  const WrongPair(this.leftIdx, this.rightIdx);
}

class Match2Result {
  final String status; // 'ignored' | 'partial' | 'match' | 'nomatch'
  final int? leftIdx;
  final int? rightIdx;
  const Match2Result(this.status, {this.leftIdx, this.rightIdx});
}

class PairTermDef {
  final int pairId;
  final String term;
  final String def;
  const PairTermDef({required this.pairId, required this.term, required this.def});
}

class CardGameV2Engine {
  final _rng = Random();

  List<Match2Card> left = [];
  List<Match2Card> right = [];
  int? selectedLeft;
  int? selectedRight;
  int mistakes = 0;
  int maxMistakes = 3;
  int pairsTotal = 0;
  int matchedCount = 0;
  WrongPair? lastWrong;

  static String _stripLeadingEmoji(String s) {
    final re = RegExp(r'^[^\p{L}\p{N}]+', unicode: true);
    return s.replaceFirst(re, '').trim();
  }

  /// JS: CardGameV2.buildPairsForTopic
  static List<PairTermDef> buildPairsForTopic(Topic topic) {
    final pairs = <PairTermDef>[];
    final pts = topic.anlatim.anahtarNoktalar;
    for (var i = 0; i < pts.length; i++) {
      final clean = _stripLeadingEmoji(pts[i]);
      final idx = clean.indexOf(':');
      if (idx > 3 && idx < clean.length - 3) {
        final term = clean.substring(0, idx).trim();
        final def = clean.substring(idx + 1).trim();
        if (term.isNotEmpty && def.isNotEmpty) {
          pairs.add(PairTermDef(pairId: i, term: term, def: def));
        }
      }
    }
    return pairs;
  }

  void start(Topic topic, {int maxMistakes = 3}) {
    final pairs = buildPairsForTopic(topic);
    left = pairs.map((p) => Match2Card(pairId: p.pairId, text: p.term)).toList()..shuffle(_rng);
    right = pairs.map((p) => Match2Card(pairId: p.pairId, text: p.def)).toList()..shuffle(_rng);
    selectedLeft = null;
    selectedRight = null;
    mistakes = 0;
    this.maxMistakes = maxMistakes;
    pairsTotal = pairs.length;
    matchedCount = 0;
    lastWrong = null;
  }

  Match2Result _tryResolve() {
    if (selectedLeft == null || selectedRight == null) return const Match2Result('partial');
    final li = selectedLeft!, ri = selectedRight!;
    final l = left[li], r = right[ri];
    if (l.pairId == r.pairId) {
      l.matched = true;
      r.matched = true;
      matchedCount++;
      selectedLeft = null;
      selectedRight = null;
      return Match2Result('match', leftIdx: li, rightIdx: ri);
    }
    mistakes++;
    lastWrong = WrongPair(li, ri);
    selectedLeft = null;
    selectedRight = null;
    return Match2Result('nomatch', leftIdx: li, rightIdx: ri);
  }

  Match2Result selectLeft(int i) {
    if (i < 0 || i >= left.length || left[i].matched) return const Match2Result('ignored');
    selectedLeft = i;
    lastWrong = null;
    return _tryResolve();
  }

  Match2Result selectRight(int i) {
    if (i < 0 || i >= right.length || right[i].matched) return const Match2Result('ignored');
    selectedRight = i;
    lastWrong = null;
    return _tryResolve();
  }

  void clearLastWrong() => lastWrong = null;

  bool get isComplete => pairsTotal > 0 && matchedCount == pairsTotal;
  bool get isFailed => mistakes >= maxMistakes;
}
