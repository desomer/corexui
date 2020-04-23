import 'dart:collection';

import 'package:html/dom.dart';

import '../XUIEngine.dart';

abstract class XMLElemReader {
  dynamic parseElem(dynamic parent, XMLElem element) {}
}

class XMLElem {
  String tag;
  String text;
  LinkedHashMap<dynamic, String> attributs;
}

///------------------------------------------------------------------
class HTMLReader {
  Provider provider;
  var id;
 // var content;

  HTMLReader(String id, Provider provider) {
    this.provider=provider;
    this.id=id;
  }

 Future parseElem(XMLElemReader elemReader) async {

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
      xmlelem.text = elem.text;
    } 
    else if (elem is Comment)
    {
      // un commentaire
      return Future.value();
    }
    else 
    {
      print("******* erreur");
    }

    xmlelem.attributs = elem.attributes;

    var e = await elemReader.parseElem(parent, xmlelem);
  
    for (var child in elem.nodes) {
      await _parseElem(child, e, elemReader);
    }

    return Future.value(e);
  }
}
