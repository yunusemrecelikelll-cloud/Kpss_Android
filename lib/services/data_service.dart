import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/subject.dart';
import '../models/topic.dart';

/// Ders/konu/soru verisini assets/data/*.json içinden yükler.
/// JS tarafındaki loadAllSubjects()'in karşılığı.
class DataService {
  List<Subject>? _cache;

  Future<List<Subject>> loadAll() async {
    if (_cache != null) return _cache!;
    final subjects = <Subject>[];
    for (final meta in kSubjects) {
      try {
        final raw = await rootBundle.loadString(meta.dosya);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final konular = (json['konular'] as List? ?? const [])
            .map((k) => Topic.fromJson(k as Map<String, dynamic>))
            .toList();
        subjects.add(Subject(meta: meta, konular: konular));
      } catch (e) {
        // Bir ders yüklenemese bile uygulama diğerleriyle çalışmaya devam etsin.
        subjects.add(Subject(meta: meta, konular: const []));
      }
    }
    _cache = subjects;
    return subjects;
  }

  Subject? subjectById(List<Subject> subjects, String id) {
    for (final s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  Topic? topicById(Subject subject, String tid) {
    for (final t in subject.konular) {
      if (t.id == tid) return t;
    }
    return null;
  }
}
