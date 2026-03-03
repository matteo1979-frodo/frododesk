// lib/models/week_identity.dart

/// Oggetto di dominio puro.
/// Rappresenta l'identità strutturale di una settimana.
/// NON contiene logica UI.
/// NON contiene copertura.
/// NON contiene emergenza.
/// Solo struttura temporale.

class WeekIdentity {
  final DateTime weekStart; // sempre lunedì 00:00

  WeekIdentity._(this.weekStart);

  /// Crea una WeekIdentity partendo da una data qualsiasi.
  /// Calcola automaticamente il lunedì della settimana.
  factory WeekIdentity.fromDate(DateTime anyDate) {
    final normalized = DateTime(anyDate.year, anyDate.month, anyDate.day);

    // weekday: 1 = lunedì, 7 = domenica
    final difference = normalized.weekday - DateTime.monday;

    final monday = normalized.subtract(Duration(days: difference));

    return WeekIdentity._(monday);
  }

  /// Restituisce i 7 giorni della settimana (lunedì → domenica)
  List<DateTime> get days {
    return List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
  }

  /// Naviga alla settimana successiva
  WeekIdentity nextWeek() {
    return WeekIdentity._(weekStart.add(const Duration(days: 7)));
  }

  /// Naviga alla settimana precedente
  WeekIdentity previousWeek() {
    return WeekIdentity._(weekStart.subtract(const Duration(days: 7)));
  }
}