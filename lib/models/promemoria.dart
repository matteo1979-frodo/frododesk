class Promemoria {
  final String id;
  final String persona;
  final String testo;
  final bool done;
  final DateTime createdDay;
  final DateTime? completedDay;

  Promemoria({
    required this.id,
    required this.persona,
    required this.testo,
    required this.done,
    required this.createdDay,
    required this.completedDay,
  });

  Promemoria copyWith({
    String? id,
    String? persona,
    String? testo,
    bool? done,
    DateTime? createdDay,
    DateTime? completedDay,
    bool clearCompletedDay = false,
  }) {
    return Promemoria(
      id: id ?? this.id,
      persona: persona ?? this.persona,
      testo: testo ?? this.testo,
      done: done ?? this.done,
      createdDay: createdDay ?? this.createdDay,
      completedDay: clearCompletedDay
          ? null
          : (completedDay ?? this.completedDay),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'persona': persona,
      'testo': testo,
      'done': done,
      'createdDay': createdDay.toIso8601String(),
      'completedDay': completedDay?.toIso8601String(),
    };
  }

  factory Promemoria.fromJson(Map<String, dynamic> json) {
    return Promemoria(
      id: json['id'] as String,
      persona: json['persona'] as String,
      testo: json['testo'] as String,
      done: json['done'] as bool? ?? false,
      createdDay: DateTime.parse(json['createdDay'] as String),
      completedDay: json['completedDay'] == null
          ? null
          : DateTime.parse(json['completedDay'] as String),
    );
  }
}
