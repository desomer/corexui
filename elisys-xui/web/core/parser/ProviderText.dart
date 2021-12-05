// ignore_for_file: file_names
import '../XUIEngine.dart';

class ProviderText extends Provider
{
  Map map;
  
  ProviderText(this.map);

  @override
  Future<String> getResourceFutur(String id) {
    return map[id] as Future<String>;
  }
  
}
