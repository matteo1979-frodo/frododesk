import '../models/support_person.dart';

class SupportNetworkStore {
  final List<SupportPerson> _people = [];

  List<SupportPerson> get people => List.unmodifiable(_people);

  void addPerson(SupportPerson person) {
    _people.add(person);
  }

  void updatePerson(String id, SupportPerson updated) {
    final index = _people.indexWhere((p) => p.id == id);
    if (index == -1) return;
    _people[index] = updated;
  }

  void removePerson(String id) {
    _people.removeWhere((p) => p.id == id);
  }
}
