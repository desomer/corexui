import 'dart:async';
import 'dart:collection';
import '../XUIEngine.dart' as Const;
import '../XUIEngine.dart';
import '../XUIFactory.dart';
import 'XUIProperty.dart';

abstract class XUIElement {
  // identifie l'implementation HTML ex: type panel (div, h1, span) input (label +
  // combo + action + desc + flag)
  String tag;

  // les attribut XHTML
  HashMap<String, XUIProperty> attributes;

  // les enfants
  List<XUIElement> children;

  // les prop xui
  HashMap<String, XUIProperty> propertiesXUI;
}

class XUIElementHTML extends XUIElement {
  XUIElementHTML parent;

  XUIElementXUI origin;
  List<XUIComponent> implementBy;
  List<XUIDesign> designBy;

  dynamic searchPropertyXUI(String tag) {
    XUIProperty prop = propertiesXUI == null ? null : propertiesXUI[tag];
    if (prop != null)
      return prop.content;
    else if (parent != null) return parent.searchPropertyXUI(tag);
  }

  dynamic processContent(String content) {
    StringBuffer buf = StringBuffer(content);
    XUIProperty.parse(buf, (String tag) {
      var ret = searchPropertyXUI(tag);
      return ret != null ? ret : "[" + tag + "]";
    });
    return buf.toString();
  }

  void toHTMLString(XUIHtmlBuffer buffer) {
    if (tag == Const.TAG_NO_DOM) {
      // cas des slot
      toChildrenHTMLString(buffer);
      return;
    }

    buffer.addTab();
    buffer.html.write('<' + this.tag);

    this.attributes?.entries?.forEach((f) {
      buffer.html.write(" ");
      buffer.html.write(f.key);
      var c = f.value.content;
      if (c != null) {
        buffer.html.write("=");
        if (c is String) {
          buffer.html.write('"' + processContent(c) + '"');
        } else
          buffer.html.write(c);
      }
    });

    buffer.html.write('>');

    bool hasChidren = this.children?.firstWhere(
            (c) => (c is! XUIElementHTMLText),
            orElse: () => null) !=
        null;

    if (hasChidren) buffer.html.write('\n');

    buffer.tab(1);
    toChildrenHTMLString(buffer);
    buffer.tab(-1);

    if (hasChidren) buffer.addTab();
    buffer.html.write('</' + this.tag + '>\n');
  }

  void toChildrenHTMLString(XUIHtmlBuffer buffer) {
    this.children?.forEach((c) {
      if (c is XUIElementHTMLText) {
        c.content.trim().isNotEmpty ? c.toHTMLString(buffer) : null;
      } else
        (c as XUIElementHTML).toHTMLString(buffer);
    });
  }
}

class XUIElementHTMLText extends XUIElementHTML {
  String content;

  @override
  void toHTMLString(XUIHtmlBuffer buffer) {
    buffer.html.write(processContent(content));
  }
}

/**
 *  provient d'un provider interne
 */
abstract class XUIElementNative extends XUIElementXUI {
  Future<XUIModel> doProcessPhase1(
      XUIResource xuifile, XUIElementHTML html) async {
    return Future.value(null);
  }

  Future doProcessPhase2(XUIResource xuifile, XUIElementHTML html) async {
    return Future.value();
  }

  void register(XUIResource reader) {
    reader.components[xid] ??= DicoOrdered()..add(XUIComponent(this, MODE_ALL));
  }
}

/** uniquement un text */
class XUIElementText extends XUIElementXUI {
  String content;
}

/**
 *   provient d'un provider fichier XUI
 */
class XUIElementXUI extends XUIElement {
  String xid;
  String idRessource;
}
