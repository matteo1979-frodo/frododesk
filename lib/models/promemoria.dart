class Promemoria {
  final String id;
  final String persona;
  final String testo;
  final bool done;
  final DateTime day;

  Promemoria({
    required this.id,
    required this.persona,
    required this.testo,
    required this.done,
    required this.day,
  });

  Promemoria copyWith({
    String? id,
    String? persona,
    String? testo,
    bool? done,
    DateTime? day,
  }) {
    return Promemoria(
      id: id ?? this.id,
      persona: persona ?? this.persona,
      testo: testo ?? this.testo,
      done: done ?? this.done,
      day: day ?? this.day,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'persona': persona,
      'testo': testo,
      'done': done,
      'day': day.toIso8601String(),
    };
  }

  factory Promemoria.fromJson(Map<String, dynamic> json) {
    return Promemoria(
      id: json['id'] as String,
      persona: json['persona'] as String,
      testo: json['testo'] as String,
      done: json['done'] as bool,
      day: DateTime.parse(json['day'] as String),
    );
  }
}