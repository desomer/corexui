
import 'package:html/dom.dart';

import '../XUIConfigManager.dart';
import '../XUIEngine.dart';


///------------------------------------------------------------------
class HTMLReader extends XUIReader {

  HTMLReader(String id, Provider provider) {
    this.provider=provider;
    this.id=id;
  }

 @override
 Future parseFile(XMLElemReader elemReader) async {

    var text = await provider.getResourceFutur(id);

    text = text.replaceAll("<html", "<xui-escape-html");
    text = text.replaceAll("</html", "</xui-escape-html");
    text = text.replaceAll("<body", "<xui-escape-body");
    text = text.replaceAll("</body", "</xui-escape-body");
    text = text.replaceAll("<head", "<xui-escape-head");
    text = text.replaceAll("</head", "</xui-escape-head");
    text = text.replaceAll("<script", "<xui-escape-script");
    text = text.replaceAll("</script", "</xui-escape-script");
    
  //  this.content = text;

    var document = Element.html(text);

    return _parseElem(document, null, elemReader);
  }

  Future parseString(String str, XMLElemReader elemReader) async {
    var document = Element.html(str);

    return _parseElem(document, null, elemReader);
  }

  ///------------------------------------------------------------------
  Future _parseElem(Node elem, dynamic parent, XMLElemReader elemReader) async {
    var xmlelem = XMLElem();

    if (elem is Element) {
      xmlelem.tag = elem.localName;
    } else if (elem is Text) {
      xmlelem.text = StringBuffer(elem.text);
    } 
    else if (elem is Comment)
    {
      // un commentaire = ne fait rien
      return Future.value();
    }
    else 
    {
      XUIConfigManager.printc("_parseElem ******* erreur");
    }

    xmlelem.attributs = elem.attributes;

    var e = await elemReader.parseElem(parent, xmlelem);
  
    for (var child in elem.nodes) {
      await _parseElem(child, e, elemReader);
    }

    return Future.value(e);
  }
}
