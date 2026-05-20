import 'package:flutter/widgets.dart';

ImageProvider getPlatformImageProvider(String path) {
  return NetworkImage(path);
}
