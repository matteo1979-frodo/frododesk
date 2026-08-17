import 'package:flutter/foundation.dart';

import '../../stores/finance_store.dart';
import 'finance_lifecycle_loader.dart';

class FinanceLifecycleCoordinator {
  final FinanceLifecycleLoader _loader;

  FinanceLifecycleCoordinator({
    required FinanceStore financeStore,
    required VoidCallback refresh,
  }) : _loader = FinanceLifecycleLoader(
         financeStore: financeStore,
         refresh: refresh,
       );

  Future<void> initialize() {
    return _loader.load();
  }
}
