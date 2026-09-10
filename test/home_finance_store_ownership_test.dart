import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String home;
  late String storeName;
  late String expenseStoreName;
  late String cashWalletStoreName;

  setUpAll(() {
    home = File('lib/screens/home_screen.dart').readAsStringSync();
    final ownership = RegExp(
      r'final\s+FinanceStore\s+(\w+)\s*=\s*FinanceStore\s*\(\s*\)\s*;',
    ).allMatches(home).toList();

    expect(
      ownership,
      hasLength(1),
      reason: 'Home must own exactly one FinanceStore instance.',
    );
    storeName = ownership.single.group(1)!;
    expenseStoreName = _singleOwnedStore(
      home,
      'ExpenseStore',
      'Home must own exactly one ExpenseStore instance.',
    );
    cashWalletStoreName = _singleOwnedStore(
      home,
      'CashWalletStore',
      'Home must own exactly one CashWalletStore instance.',
    );
  });

  test('Home creates exactly one FinanceStore instance', () {
    expect(RegExp(r'FinanceStore\s*\(').allMatches(home), hasLength(1));
  });

  test('Home creates each shared economic store exactly once', () {
    expect(RegExp(r'ExpenseStore\s*\(').allMatches(home), hasLength(1));
    expect(RegExp(r'CashWalletStore\s*\(').allMatches(home), hasLength(1));
  });

  test('initState starts finance initialization exactly once', () {
    final initStateStart = home.indexOf('void initState()');
    final initStateEnd = home.indexOf(
      'Future<void> _loadFinanceData',
      initStateStart,
    );

    expect(initStateStart, isNonNegative);
    expect(initStateEnd, greaterThan(initStateStart));
    final initState = home.substring(initStateStart, initStateEnd);
    expect(
      RegExp(r'_loadFinanceData\s*\(\s*\)\s*;').allMatches(initState),
      hasLength(1),
    );
  });

  test('Home passes its FinanceStore instance to HomeFinanceCoordinator', () {
    expect(
      RegExp(
        'HomeFinanceCoordinator\\s*\\(\\s*financeStore:\\s*'
        '${RegExp.escape(storeName)}\\s*,?\\s*\\)',
      ).allMatches(home),
      hasLength(1),
    );
  });

  test('Home passes its FinanceStore instance to FinanceScreen', () {
    final call = _constructorCall(home, 'FinanceScreen');
    expect(call, contains('financeStore: $storeName'));
    expect(call, contains('expenseStore: $expenseStoreName'));
    expect(call, contains('cashWalletStore: $cashWalletStoreName'));
  });

  test('Home passes its FinanceStore instance to SpesePage', () {
    final call = _constructorCall(home, 'SpesePage');
    expect(call, contains('financeStore: $storeName'));
    expect(call, contains('expenseStore: $expenseStoreName'));
    expect(call, contains('cashWalletStore: $cashWalletStoreName'));
  });

  test('Home loads and disposes shared economic stores exactly once', () {
    expect('$expenseStoreName.load()'.allMatches(home), hasLength(1));
    expect('$cashWalletStoreName.load()'.allMatches(home), hasLength(1));
    expect('$expenseStoreName.dispose()'.allMatches(home), hasLength(1));
    expect('$cashWalletStoreName.dispose()'.allMatches(home), hasLength(1));
  });
}

String _singleOwnedStore(String source, String type, String reason) {
  final matches = RegExp(
    'final\\s+$type\\s+(\\w+)\\s*=\\s*$type\\s*\\(\\s*\\)\\s*;',
  ).allMatches(source).toList();
  expect(matches, hasLength(1), reason: reason);
  return matches.single.group(1)!;
}

String _constructorCall(String source, String type) {
  final match = RegExp('$type\\s*\\([\\s\\S]*?\\n\\s*\\)').firstMatch(source);
  expect(match, isNotNull, reason: 'Missing $type constructor call.');
  return match!.group(0)!;
}
