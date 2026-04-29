/// Rappresenta una sessione di accordatura salvata nel database.
class TuningSession {
  final int? id;
  final String instrument;
  final String stringName;
  final double targetFrequency;
  final double detectedFrequency;
  final double centsOffset;
  final bool tuned;
  final String createdAt;

  TuningSession({
    this.id,
    required this.instrument,
    required this.stringName,
    required this.targetFrequency,
    required this.detectedFrequency,
    required this.centsOffset,
    required this.tuned,
    required this.createdAt,
  });

  /// Converte oggetto Dart in Map per SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'instrument': instrument,
      'string_name': stringName,
      'target_frequency': targetFrequency,
      'detected_frequency': detectedFrequency,
      'cents_offset': centsOffset,
      'tuned': tuned ? 1 : 0,
      'created_at': createdAt,
    };
  }

  /// Crea oggetto Dart da Map SQL
  factory TuningSession.fromMap(Map<String, dynamic> map) {
    return TuningSession(
      id: map['id'] as int?,
      instrument: map['instrument'] as String,
      stringName: map['string_name'] as String,
      targetFrequency: (map['target_frequency'] as num).toDouble(),
      detectedFrequency: (map['detected_frequency'] as num).toDouble(),
      centsOffset: (map['cents_offset'] as num).toDouble(),
      tuned: map['tuned'] == 1,
      createdAt: map['created_at'] as String,
    );
  }
}