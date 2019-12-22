
import 'dart:io';

import '../XUIEngine.dart';

class ProviderFile extends Provider
{
  String path;

  ProviderFile(this.path);

  @override
  Future<String> getResourceFutur(String id) {
    return new File(path+id).readAsString();
  }
  
}