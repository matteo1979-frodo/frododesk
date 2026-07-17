import '../../coverage_engine.dart';
import '../../day_settings_store.dart';

class CoverageGapFilter {
  const CoverageGapFilter();

  List<CoverageGapDetail> filter({
    required List<CoverageGapDetail> details,
    required DateTime selectedDay,
    required DateTime now,
    required bool uscitaAnticipataActive,
    required SchoolCoverChoice schoolInCover,
    required SchoolCoverChoice schoolOutCover,
    required SchoolCoverChoice lunchCover,
  }) {
    final selectedDate = _onlyDate(selectedDay);
    final currentDate = _onlyDate(now);

    final selectedIsToday = selectedDate == currentDate;
    final nowMinutes = now.hour * 60 + now.minute;

    return details.where((detail) {
      if (selectedIsToday) {
        final endMinutes = detail.end.hour * 60 + detail.end.minute;

        if (endMinutes <= nowMinutes) {
          return false;
        }
      }

      final label = detail.label;

      if (schoolInCover != SchoolCoverChoice.none &&
          _isSchoolInGapLabel(label)) {
        return false;
      }

      if (!uscitaAnticipataActive &&
          schoolOutCover != SchoolCoverChoice.none &&
          _isSchoolOutGapLabel(label)) {
        return false;
      }

      if (uscitaAnticipataActive &&
          lunchCover != SchoolCoverChoice.none &&
          _isLunchGapLabel(label)) {
        return false;
      }

      return true;
    }).toList();
  }

  DateTime _onlyDate(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }

  bool _isSchoolInGapLabel(String label) {
    final lower = label.toLowerCase();

    return lower.contains('alice ingresso') ||
        lower.contains('ingresso scuola');
  }

  bool _isSchoolOutGapLabel(String label) {
    final lower = label.toLowerCase();

    return lower.contains('alice uscita') || lower.contains('uscita scuola');
  }

  bool _isLunchGapLabel(String label) {
    return label.toLowerCase().contains('pranzo');
  }
}
