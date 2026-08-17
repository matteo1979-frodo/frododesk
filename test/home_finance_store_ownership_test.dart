import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String home;
  late String storeName;

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
  });

  test('Home creates exactly one FinanceStore instance', () {
    expect(RegExp(r'FinanceStore\s*\(').allMatches(home), hasLength(1));
  });

  test('initState starts finance initialization exactly once', () {
    final initStateStart = home.indexOf('void initState()');
    final initStateEnd = home.indexOf('Future<void> _loadFinanceData', initStateStart);

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
    expect(
      RegExp(
        'FinanceScreen\\s*\\(\\s*financeStore:\\s*${RegExp.escape(storeName)}\\s*\\)',
      ).allMatches(home),
      hasLength(1),
    );
  });

  test('Home passes its FinanceStore instance to SpesePage', () {
    expect(
      RegExp(
        'SpesePage\\s*\\(\\s*financeStore:\\s*${RegExp.escape(storeName)}\\s*\\)',
      ).allMatches(home),
      hasLength(1),
    );
  });
}
