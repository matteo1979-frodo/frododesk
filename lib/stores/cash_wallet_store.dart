import '../logic/persistence_store.dart';
import '../models/cash_wallet.dart';

class CashWalletStore {
  static const String _storageKey = 'cash_wallets_v1';

  final List<CashWallet> wallets = [
    const CashWallet(
      id: 'wallet_matteo',
      personId: 'matteo',
      name: 'Portafoglio Matteo',
      currentAmount: 0,
    ),
    const CashWallet(
      id: 'wallet_chiara',
      personId: 'chiara',
      name: 'Portafoglio Chiara',
      currentAmount: 0,
    ),
  ];

  List<CashWallet> get all => List.unmodifiable(wallets);

  Future<void> load() async {
    final jsonList = await PersistenceStore.loadJsonList(_storageKey);

    if (jsonList.isEmpty) return;

    wallets
      ..clear()
      ..addAll(jsonList.map(CashWallet.fromJson));
  }

  Future<void> save() async {
    final jsonList = wallets.map((wallet) => wallet.toJson()).toList();

    await PersistenceStore.saveJsonList(_storageKey, jsonList);
  }

  CashWallet? findById(String id) {
    try {
      return wallets.firstWhere((wallet) => wallet.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addCash({
    required String walletId,
    required double amount,
  }) async {
    final index = wallets.indexWhere((wallet) => wallet.id == walletId);

    if (index == -1) return;

    final old = wallets[index];

    wallets[index] = old.copyWith(currentAmount: old.currentAmount + amount);

    await save();
  }

  Future<void> removeCash({
    required String walletId,
    required double amount,
  }) async {
    final index = wallets.indexWhere((wallet) => wallet.id == walletId);

    if (index == -1) return;

    final old = wallets[index];

    wallets[index] = old.copyWith(currentAmount: old.currentAmount - amount);

    await save();
  }
}
