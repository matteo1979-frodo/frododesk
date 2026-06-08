import '../logic/persistence_store.dart';

class ExpenseCategoryStore {
  static const String _storageKey = 'expense_categories_v1';

  final List<String> categories = [
    "Alimentazione",
    "Bar / caffè",
    "Scuola",
    "Mensa scuola",
    "Sandra",
    "Auto",
    "Casa",
    "Ferramenta",
    "Giardinaggio",
    "Salute",
    "Svago",
    "Contanti / non tracciato",
  ];

  List<String> get all => List.unmodifiable(categories);

  Future<void> load() async {
    final saved = await PersistenceStore.loadStringList(_storageKey);

    if (saved == null || saved.isEmpty) return;

    categories
      ..clear()
      ..addAll(saved);
  }

  Future<void> save() async {
    await PersistenceStore.saveStringList(_storageKey, categories);
  }

  Future<void> addCategory(String category) async {
    final clean = category.trim();

    if (clean.isEmpty) return;
    if (categories.contains(clean)) return;

    categories.add(clean);

    await save();
  }
}
