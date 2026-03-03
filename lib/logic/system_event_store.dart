// lib/logic/system_event_store.dart
import 'dart:math';
import '../models/system_event.dart';

class SystemEventStore {
  final List<SystemEvent> _events = [];

  /// Ritorna tutti gli eventi (read-only)
  List<SystemEvent> get allEvents => List.unmodifiable(_events);

  /// Aggiunge un evento allo store
  void addEvent({
    required DateTime day,
    required SystemEventType type,
    required SystemEventSeverity severity,
    required String title,
    Map<String, dynamic> payload = const {},
  }) {
    final event = SystemEvent(
      id: _generateId(),
      createdAt: DateTime.now(),
      day: SystemEvent.dayKey(day),
      type: type,
      severity: severity,
      title: title,
      payload: payload,
    );

    _events.add(event);
  }

  /// Eventi filtrati per giorno
  List<SystemEvent> eventsForDay(DateTime day) {
    final key = SystemEvent.dayKey(day);
    return _events.where((e) => e.day == key).toList();
  }

  /// Eventi negli ultimi N giorni (finestra mobile futura IPS)
  List<SystemEvent> eventsInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _events.where((e) => e.createdAt.isAfter(cutoff)).toList();
  }

  String _generateId() {
    final rand = Random().nextInt(999999);
    return '${DateTime.now().millisecondsSinceEpoch}_$rand';
  }
}
