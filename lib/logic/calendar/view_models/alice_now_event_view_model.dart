import 'package:flutter/material.dart';

class AliceNowEventViewModel {
  final String title;
  final TimeOfDay? start;
  final TimeOfDay? end;

  const AliceNowEventViewModel({required this.title, this.start, this.end});
}
