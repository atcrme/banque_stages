import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ShowSnackBar');

void showSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 5),
}) {
  _logger.finer('Showing snackbar with message: $message');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      duration: duration,
    ),
  );
}
