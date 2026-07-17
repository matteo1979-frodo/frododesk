
import '../../../models/turn_override.dart';
import '../../../utils/calendario_formatters.dart';
import '../../core_store.dart';

class TurnPersonSourceResult {
  final String? turnOverrideStatusText;
  final String? sourceText;

  const TurnPersonSourceResult({
    required this.turnOverrideStatusText,
    required this.sourceText,
  });
}

class TurnPersonSourceBuilder {
  const TurnPersonSourceBuilder();

  TurnPersonSourceResult build({
    required CoreStore coreStore,
    required String personKey,
    required DateTime day,
  }) {
    final person = _personIdFromKey(personKey);

    if (person == null) {
      return const TurnPersonSourceResult(
        turnOverrideStatusText: null,
        sourceText: null,
      );
    }

    final daily = coreStore.turnOverrideStore.dailyOverrideFor(
      person: person,
      day: day,
    );

    if (daily != null && daily.shift != null) {
      return TurnPersonSourceResult(
        turnOverrideStatusText:
            'Turno cambiato manualmente • '
            '${_turnOverrideShiftLabel(daily.shift!)} '
            '(solo oggi)',
        sourceText: 'Cambio turno (solo oggi)',
      );
    }

    final period = coreStore.turnOverrideStore.periodOverrideFor(
      person: person,
      day: day,
    );

    if (period != null && period.shift != null) {
      final statusText = period.endDate == null
          ? null
          : 'Turno cambiato manualmente • '
                '${_turnOverrideShiftLabel(period.shift!)} '
                '(${fmtShortDate(period.startDate)} → '
                '${fmtShortDate(period.endDate!)})';

      return TurnPersonSourceResult(
        turnOverrideStatusText: statusText,
        sourceText: 'Cambio turno (periodo)',
      );
    }

    final activeRotation = coreStore.rotationOverrideStore.activeFor(
      person: person,
      day: day,
    );

    if (activeRotation != null) {
      return const TurnPersonSourceResult(
        turnOverrideStatusText: null,
        sourceText: 'Nuova rotazione',
      );
    }

    final normalizedDay = DateTime(day.year, day.month, day.day);

    final isFourthShiftActive = coreStore.fourthShiftStore
        .isActiveForPersonOnDay(person.name, normalizedDay);

    if (isFourthShiftActive) {
      return const TurnPersonSourceResult(
        turnOverrideStatusText: null,
        sourceText: 'Quarta squadra',
      );
    }

    return const TurnPersonSourceResult(
      turnOverrideStatusText: null,
      sourceText: null,
    );
  }

  TurnPersonId? _personIdFromKey(String personKey) {
    switch (personKey) {
      case 'matteo':
        return TurnPersonId.matteo;
      case 'chiara':
        return TurnPersonId.chiara;
      default:
        return null;
    }
  }

  String _turnOverrideShiftLabel(TurnOverrideShift shift) {
    switch (shift) {
      case TurnOverrideShift.mattina:
        return 'Mattina';
      case TurnOverrideShift.pomeriggio:
        return 'Pomeriggio';
      case TurnOverrideShift.notte:
        return 'Notte';
      case TurnOverrideShift.off:
        return 'Off';
    }
  }
}
