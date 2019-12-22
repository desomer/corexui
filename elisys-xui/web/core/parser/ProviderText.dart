
import '../XUIEngine.dart';

class ProviderText extends Provider
{
  Map map;
  
  ProviderText(this.map);

  @override
  Future<String> getResourceFutur(String id) {
    return map[id];
  }
  
}