import 'dart:async';
import 'package:flutter/foundation.dart';

/// CNG LIVE — Debouncer
///
/// Used by the Search screen / Search bar so Firestore queries aren't
/// fired on every keystroke — waits for a pause in typing before running
/// the callback. Also useful for any future "save on change" inputs.
///
/// Usage:
///   final _debouncer = Debouncer(delay: const Duration(milliseconds: 400));
///   onChanged: (query) => _debouncer.run(() => viewModel.search(query));
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
