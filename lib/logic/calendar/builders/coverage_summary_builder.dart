class CoverageSummaryResult {
  final List<String> details;
  final String bannerText;

  const CoverageSummaryResult({
    required this.details,
    required this.bannerText,
  });
}

class CoverageSummaryBuilder {
  const CoverageSummaryBuilder();

  CoverageSummaryResult build({
    required bool serveSandraMattina,
    required bool serveSandraPranzo,
    required bool serveSandraSera,
    required bool coverageOk,
    required List<String> gaps,
  }) {
    final details = <String>[];

    if (serveSandraMattina) {
      details.add('Sandra serve in fascia mattina.');
    }

    if (serveSandraPranzo) {
      details.add('Sandra serve in fascia pranzo.');
    }

    if (serveSandraSera) {
      details.add('Sandra serve in fascia sera.');
    }

    if (coverageOk) {
      details.add('OK Nessun buco rilevato dal motore.');
    } else {
      details.add('Il motore ha rilevato ${gaps.length} buco/i reali.');
    }

    final bannerText = coverageOk
        ? 'Copertura OK'
        : 'BUCO (${gaps.length}): ${gaps.join(' • ')}';

    return CoverageSummaryResult(details: details, bannerText: bannerText);
  }
}
