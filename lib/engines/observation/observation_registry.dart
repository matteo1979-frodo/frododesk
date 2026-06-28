import 'observation_provider.dart';

class ObservationRegistry {
  static final List<ObservationProvider> _providers = [];

  static void register(ObservationProvider provider) {
    if (_providers.any((p) => p.module == provider.module)) {
      return;
    }

    _providers.add(provider);
  }

  static List<ObservationProvider> get providers =>
      List.unmodifiable(_providers);

  static void clear() {
    _providers.clear();
  }
}
