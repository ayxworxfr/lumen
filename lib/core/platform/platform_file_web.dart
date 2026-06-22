import 'package:flutter/material.dart';

Future<bool> isFileReadable(String path) => Future.value(false);

Widget buildFileImage(String path, {BoxFit fit = BoxFit.cover}) => Container(
  color: Colors.grey[200],
  child: const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
);
