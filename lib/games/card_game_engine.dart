import 'dart:math';
import '../models/subject.dart';

/// Kart Eşleştirme Oyunu (v1) — JS: src/js/cardgame.js `CardGame`.
/// Kapalı kartlar, hafıza/eşleştirme oyunu. Tüm derslerin konu anlatımlarındaki
/// "Terim: Tanım" biçimindeki anahtar noktalarından rastgele bir kart havuzu kurar.
class MatchCard {
  final int pairId;
  final String type; // 'term' | 'def'
  final String text;
  bool matched;

  MatchCard({required this.pairId, required this.type, required this.text, this.matched = false});
}

class CardFlipResult {
  final String status; // 'ignored' | 'flipped' | 'match' | 'pending-nomatch'
  const CardFlipResult(this.status);
}

class _TermDef {
  final String term;
  final String def;
  const _TermDef(this.term, this.def);
}

class CardGameEngine {
  final _rng = Random();

  List<MatchCard> cards = [];
  List<int> flipped = [];
  int moves = 0;
  int matchedCount = 0;

  String _stripLeadingEmoji(String s) {
    // JS: s.replace(/^[^\p{L}\p{N}]+/u, '').trim()
    final re = RegExp(r'^[^\p{L}\p{N}]+', unicode: true);
    return s.replaceFirst(re, '').trim();
  }

  List<_TermDef> _buildPairs(List<Subject> subjects, int count) {
    final pool = <_TermDef>[];
    for (final s in subjects) {
      for (final t in s.konular) {
        for (final raw in t.anlatim.anahtarNoktalar) {
          final clean = _stripLeadingEmoji(raw);
          final idx = clean.indexOf(':');
          if (idx > 3 && idx < clean.length - 3) {
            final term = clean.substring(0, idx).trim();
            final def = clean.substring(idx + 1).trim();
            if (term.isNotEmpty && def.isNotEmpty) pool.add(_TermDef(term, def));
          }
        }
      }
    }

    final shuffled = List<_TermDef>.of(pool)..shuffle(_rng);
    final picked = <_TermDef>[];
    final seen = <String>{};
    for (final p in shuffled) {
      if (seen.contains(p.term)) continue;
      seen.add(p.term);
      picked.add(p);
      if (picked.length >= count) break;
    }
    return picked;
  }

  void start(List<Subject> subjects, {int pairCount = 6}) {
    final pairs = _buildPairs(subjects, pairCount);
    final newCards = <MatchCard>[];
    for (var i = 0; i < pairs.length; i++) {
      newCards.add(MatchCard(pairId: i, type: 'term', text: pairs[i].term));
      newCards.add(MatchCard(pairId: i, type: 'def', text: pairs[i].def));
    }
    newCards.shuffle(_rng);
    cards = newCards;
    flipped = [];
    moves = 0;
    matchedCount = 0;
  }

  CardFlipResult flip(int cardIndex) {
    if (cardIndex < 0 || cardIndex >= cards.length) return const CardFlipResult('ignored');
    final card = cards[cardIndex];
    if (card.matched || flipped.contains(cardIndex) || flipped.length >= 2) {
      return const CardFlipResult('ignored');
    }
    flipped.add(cardIndex);
    if (flipped.length == 2) {
      moves++;
      final i1 = flipped[0], i2 = flipped[1];
      final c1 = cards[i1], c2 = cards[i2];
      if (c1.pairId == c2.pairId && c1.type != c2.type) {
        c1.matched = true;
        c2.matched = true;
        matchedCount++;
        flipped = [];
        return const CardFlipResult('match');
      }
      return const CardFlipResult('pending-nomatch');
    }
    return const CardFlipResult('flipped');
  }

  void clearPending() => flipped = [];

  bool get isComplete => cards.isNotEmpty && matchedCount == cards.length ~/ 2;
}
