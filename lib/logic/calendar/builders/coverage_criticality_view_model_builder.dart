import '../../../models/coverage_criticality_detail.dart';
import '../../../models/support_person.dart';
import '../view_models/coverage_criticality_view_model.dart';

class CoverageCriticalityViewModelBuilder {
  const CoverageCriticalityViewModelBuilder();

  List<CoverageCriticalityViewModel> build({
    required List<CoverageCriticalityDetail> details,
    required List<SupportPerson> supportPeople,
  }) {
    final supportNames = {
      for (final person in supportPeople) person.id: person.name.trim(),
    };

    return details
        .map((detail) => _buildOne(detail, supportNames: supportNames))
        .toList(growable: false);
  }

  CoverageCriticalityViewModel _buildOne(
    CoverageCriticalityDetail detail, {
    required Map<String, String> supportNames,
  }) {
    final person = _adultName(detail.personId);
    final provider = _providerName(
      detail.coverageProviderId,
      source: detail.source,
      supportNames: supportNames,
    );
    final timeRange = '${_time(detail.start)}–${_time(detail.end)}';

    switch (detail.kind) {
      case CoverageCriticalityKind.recoverySacrificed:
        return CoverageCriticalityViewModel(
          detail: detail,
          title: 'Recupero post-notte sacrificato',
          text: '$person copre Alice sacrificando il recupero post-notte.',
          realityText:
              '$timeRange — Alice coperta da $person; recupero post-notte sacrificato.',
          timeRange: timeRange,
        );
      case CoverageCriticalityKind.recoveryProtected:
        return CoverageCriticalityViewModel(
          detail: detail,
          title: 'Recupero protetto',
          text: '$person può recuperare grazie a $provider.',
          realityText:
              '$timeRange — $person può recuperare grazie a $provider.',
          timeRange: timeRange,
        );
    }
  }

  String _adultName(String id) {
    switch (id) {
      case 'matteo':
        return 'Matteo';
      case 'chiara':
        return 'Chiara';
      default:
        return 'Il genitore';
    }
  }

  String _providerName(
    String? id, {
    required CoverageSource source,
    required Map<String, String> supportNames,
  }) {
    switch (id) {
      case 'matteo':
        return 'Matteo';
      case 'chiara':
        return 'Chiara';
      case CoverageProviderIds.sandraLegacy:
        return 'Sandra';
      default:
        final supportName = supportNames[id];
        if (supportName != null && supportName.isNotEmpty) {
          return supportName;
        }
        return switch (source) {
          CoverageSource.parentNormal ||
          CoverageSource.parentForced => 'l’altro genitore',
          CoverageSource.supportNetwork => 'una persona di supporto',
          CoverageSource.school ||
          CoverageSource.summerCamp ||
          CoverageSource.event ||
          CoverageSource.companion => 'un supporto disponibile',
        };
    }
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
