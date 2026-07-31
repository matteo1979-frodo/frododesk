import '../../../models/support_person.dart';
import '../models/alice_summer_camp_logistics.dart';
import '../view_models/alice_summer_camp_logistics_view_model.dart';

class AliceSummerCampLogisticsViewModelBuilder {
  static const _missingSupport = 'Persona di supporto non disponibile';

  const AliceSummerCampLogisticsViewModelBuilder();

  AliceSummerCampLogisticsViewModel? build({
    required AliceSummerCampLogisticsResult result,
    required List<SupportPerson> supportPeople,
  }) {
    if (result.dropOff.status == AliceLogisticDecisionStatus.inactive &&
        result.pickUp.status == AliceLogisticDecisionStatus.inactive) {
      return null;
    }
    final names = {for (final person in supportPeople) person.id: person.name};
    final options = <AliceLogisticProviderOptionViewModel>[
      const AliceLogisticProviderOptionViewModel(
        provider: null,
        label: 'Da assegnare',
      ),
      AliceLogisticProviderOptionViewModel(
        provider: AliceLogisticProviderRef.parent(AliceLogisticParent.matteo),
        label: 'Matteo',
      ),
      AliceLogisticProviderOptionViewModel(
        provider: AliceLogisticProviderRef.parent(AliceLogisticParent.chiara),
        label: 'Chiara',
      ),
      const AliceLogisticProviderOptionViewModel(
        provider: AliceLogisticProviderRef.sandra,
        label: 'Sandra',
      ),
      ...supportPeople.map(
        (person) => AliceLogisticProviderOptionViewModel(
          provider: AliceLogisticProviderRef.supportPerson(person.id),
          label: person.name,
        ),
      ),
    ];
    return AliceSummerCampLogisticsViewModel(
      sectionTitle: 'Logistica centro estivo',
      dropOff: _leg(result.dropOff, names, options),
      pickUp: _leg(result.pickUp, names, options),
    );
  }

  AliceSummerCampLogisticLegViewModel _leg(
    AliceLogisticDecisionResult value,
    Map<String, String> supportNames,
    List<AliceLogisticProviderOptionViewModel> baseOptions,
  ) {
    final assignedName = _name(value.assignedProvider, supportNames);
    final alternatives = value.availableProviders
        .where((provider) => provider != value.assignedProvider)
        .map((provider) => _name(provider, supportNames))
        .toList(growable: false);
    final options = [...baseOptions];
    if (value.assignedProvider != null &&
        !options.any((option) => option.provider == value.assignedProvider)) {
      options.add(
        AliceLogisticProviderOptionViewModel(
          provider: value.assignedProvider,
          label: _missingSupport,
        ),
      );
    }
    final dropOff = value.leg == AliceLogisticLeg.dropOff;
    final action = dropOff ? 'accompagnare' : 'riprendere';
    final interval = '${_time(value.start)}–${_time(value.end)}';
    late String title;
    late String description;
    late String reality;
    late AliceSummerCampLogisticVisualState visual;
    switch (value.status) {
      case AliceLogisticDecisionStatus.assignedValid:
        title = dropOff ? 'Andata assegnata' : 'Ritorno assegnato';
        description = dropOff
            ? '$assignedName accompagna Alice al centro estivo.'
            : '$assignedName riprende Alice dal centro estivo.';
        reality = description;
        visual = AliceSummerCampLogisticVisualState.success;
      case AliceLogisticDecisionStatus.unassignedProviderAvailable:
        title = 'Buco logistico da assegnare';
        description = dropOff
            ? 'Devi scegliere chi accompagna Alice al centro estivo.'
            : 'Devi scegliere chi riprende Alice dal centro estivo.';
        reality = dropOff
            ? 'Accompagnamento al centro estivo da assegnare.'
            : 'Ritiro dal centro estivo da assegnare.';
        visual = AliceSummerCampLogisticVisualState.decision;
      case AliceLogisticDecisionStatus.assignedProviderUnavailable:
        title = 'Conflitto logistico';
        description =
            '$assignedName è assegnato, ma non è disponibile per $action Alice.';
        reality = '$assignedName assegnato ma non disponibile.';
        visual = AliceSummerCampLogisticVisualState.conflict;
      case AliceLogisticDecisionStatus.noProviderAvailable:
        title = 'Buco logistico';
        description = dropOff
            ? 'Nessuno è disponibile per accompagnare Alice al centro estivo.'
            : 'Nessuno è disponibile per riprendere Alice dal centro estivo.';
        reality = dropOff
            ? 'Nessuno disponibile per accompagnare Alice.'
            : 'Nessuno disponibile per riprendere Alice.';
        visual = AliceSummerCampLogisticVisualState.gap;
      case AliceLogisticDecisionStatus.inactive:
        throw StateError('Una tratta inattiva non deve essere presentata.');
    }
    return AliceSummerCampLogisticLegViewModel(
      leg: value.leg,
      fieldLabel: dropOff ? 'Accompagna' : 'Riprende',
      assignedProvider: value.assignedProvider,
      assignedProviderLabel: assignedName,
      options: List.unmodifiable(options),
      status: value.status,
      title: title,
      description: description,
      intervalLabel: interval,
      alternatives: alternatives,
      visualState: visual,
      realityText: '$interval — $reality',
    );
  }

  String _name(
    AliceLogisticProviderRef? provider,
    Map<String, String> supportNames,
  ) {
    if (provider == null) return 'Da assegnare';
    if (provider ==
        AliceLogisticProviderRef.parent(AliceLogisticParent.matteo)) {
      return 'Matteo';
    }
    if (provider ==
        AliceLogisticProviderRef.parent(AliceLogisticParent.chiara)) {
      return 'Chiara';
    }
    if (provider == AliceLogisticProviderRef.sandra) return 'Sandra';
    return supportNames[provider.providerId] ?? _missingSupport;
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
