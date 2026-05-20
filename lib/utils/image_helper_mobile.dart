import 'dart:io' as io;
import 'package:flutter/widgets.dart';

ImageProvider getPlatformImageProvider(String path) {
  return FileImage(io.File(path));
}
