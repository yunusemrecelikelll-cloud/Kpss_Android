/// KPSS sınav türlerine göre sınav tarihleri ve geri sayım hesaplaması.
class ExamInfo {
  final String id; // 'lisans' | 'onlisans' | 'ortaogretim'
  final String label;
  final int month; // 1-12
  final int day;

  const ExamInfo({required this.id, required this.label, required this.month, required this.day});
}

const List<ExamInfo> kExamTypes = [
  ExamInfo(id: 'lisans', label: 'Lisans', month: 9, day: 6),
  ExamInfo(id: 'onlisans', label: 'Önlisans', month: 10, day: 4),
  ExamInfo(id: 'ortaogretim', label: 'Ortaöğretim', month: 10, day: 25),
];

ExamInfo? examInfoFor(String id) {
  for (final e in kExamTypes) {
    if (e.id == id) return e;
  }
  return null;
}

/// Verilen sınav türü için bir sonraki sınav tarihini döndürür
/// (tarih geçtiyse otomatik olarak bir sonraki yıla kayar).
DateTime nextExamDate(ExamInfo info, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var date = DateTime(today.year, info.month, info.day);
  if (date.isBefore(DateTime(today.year, today.month, today.day))) {
    date = DateTime(today.year + 1, info.month, info.day);
  }
  return date;
}

/// "2 Ay 5 Gün" gibi bir geri sayım metni üretir.
String formatCountdown(DateTime target, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final from = DateTime(today.year, today.month, today.day);
  final to = DateTime(target.year, target.month, target.day);
  if (!to.isAfter(from)) return 'Sınav bugün! 🎯';

  var months = (to.year - from.year) * 12 + (to.month - from.month);
  var days = to.day - from.day;
  if (days < 0) {
    months -= 1;
    final prevMonth = DateTime(to.year, to.month, 0); // önceki ayın son günü
    days += prevMonth.day;
  }
  if (months <= 0) return '$days Gün';
  if (days <= 0) return '$months Ay';
  return '$months Ay $days Gün';
}
