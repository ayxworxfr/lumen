import 'dart:io';

import 'package:flutter/material.dart';

Future<bool> isFileReadable(String path) async {
  try {
    final file = File(path);
    return file.existsSync() && await file.length() > 0;
  } catch (_) {
    return false;
  }
}

Widget buildFileImage(String path, {BoxFit fit = BoxFit.cover}) {
  final file = File(path);
  if (!file.existsSync()) return _placeholder();
  return Image.file(file, fit: fit);
}

Widget _placeholder() => Container(
  color: Colors.grey[200],
  child: const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
);
