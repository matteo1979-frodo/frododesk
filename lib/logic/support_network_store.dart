import '../models/support_person.dart';

class SupportNetworkStore {
  final List<SupportPerson> _people = [];
  final List<String> _savedNames = [];

  List<SupportPerson> get people => List.unmodifiable(_people);
  List<String> get savedNames => List.unmodifiable(_savedNames);

  void addPerson(SupportPerson person) {
    _people.add(person);
    saveName(person.name);
  }

  void updatePerson(String id, SupportPerson updated) {
    final index = _people.indexWhere((p) => p.id == id);
    if (index == -1) return;

    _people[index] = updated;
    saveName(updated.name);
  }

  void removePerson(String id) {
    _people.removeWhere((p) => p.id == id);
  }

  void saveName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;

    final exists = _savedNames.any(
      (n) => n.toLowerCase() == clean.toLowerCase(),
    );
    if (exists) return;

    _savedNames.add(clean);
    _savedNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void removeSavedName(String name) {
    _savedNames.removeWhere(
      (n) => n.toLowerCase() == name.trim().toLowerCase(),
    );
  }
}
