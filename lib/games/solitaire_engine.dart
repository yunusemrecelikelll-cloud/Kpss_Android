import '../models/question.dart';

/// Solitaire — JS: src/js/solitaire.js.
/// Konu bazlı, sıralı kart temizleme oyunu: kart = soru, %70 üstü doğruysa "geçti".
class SolitaireCard {
  final Question q;
  String status; // 'pending' | 'cleared' | 'wrong'
  int? given;
  SolitaireCard(this.q, {this.status = 'pending', this.given});
}

class SolitaireAnswerResult {
  final bool correct;
  final int cursor;
  const SolitaireAnswerResult({required this.correct, required this.cursor});
}

class SolitaireEngine {
  List<SolitaireCard> cards = [];
  int cursor = 0;
  int mistakes = 0;
  int maxMistakes = 999;

  void start(List<Question> questions, {int maxMistakes = 999}) {
    cards = questions.map((q) => SolitaireCard(q)).toList();
    cursor = 0;
    mistakes = 0;
    this.maxMistakes = maxMistakes;
  }

  SolitaireAnswerResult? answer(int idx) {
    if (cards.isEmpty || cursor >= cards.length) return null;
    final c = cards[cursor];
    if (c.status != 'pending') return null;
    final correct = idx == c.q.dogruIndex;
    c.status = correct ? 'cleared' : 'wrong';
    c.given = idx;
    if (!correct) mistakes++;
    return SolitaireAnswerResult(correct: correct, cursor: cursor);
  }

  void advance() {
    if (cards.isEmpty) return;
    cursor++;
  }

  bool get isFinished => cards.isNotEmpty && cursor >= cards.length;

  bool get isPassed {
    if (cards.isEmpty) return false;
    final cleared = cards.where((c) => c.status == 'cleared').length;
    return cleared / cards.length >= 0.7;
  }
}
