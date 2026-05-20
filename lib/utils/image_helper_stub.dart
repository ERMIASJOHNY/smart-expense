import 'package:flutter/widgets.dart';

ImageProvider getPlatformImageProvider(String path) {
  throw UnsupportedError('Cannot create a platform image provider without platform-specific implementations.');
}
