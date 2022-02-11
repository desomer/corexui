// ignore_for_file: file_names
import 'dart:convert';

class XUIProperty {
  dynamic content;

  XUIProperty(v) {
    content = v;
  }

  static void parse(ParseInfo parseInfo, Function action) {
    int idx = 0;
    while ((idx = _parseNext(parseInfo, idx, action)) >= 0) {}
  }

  static int _parseNext(ParseInfo parseInfo, int idx, Function action) {
    final String parse = parseInfo.parsebuilder.toString();
    const String startTag = "[[";
    const String endTag = "]]";

    final int next = parse.indexOf(startTag, idx);

    int nextEnd = next;
    if (next >= 0) {
      nextEnd = parse.indexOf(endTag, next + 1);
    }

    if (next >= 0 && nextEnd > 0) {
      parseInfo.nbTag++;
      final String strStart = parse.substring(0, next);
      final String strEnd = parse.substring(nextEnd + 2, parse.length);
      String tag = parse.substring(next + 2, nextEnd);
      tag = action(tag).toString();
      parseInfo.parsebuilder.clear();
      nextEnd = (strStart + tag).length;
      parseInfo.parsebuilder.write(strStart + tag + strEnd);
      return nextEnd;
    } else {
      return -1;
    }
  }

  String toHTML(String k) {
    const HtmlEscape htmlEscape = HtmlEscape();

    final val = htmlEscape.convert(content.toString());

    return '<xui-prop id="$k" val="$val"></xui-prop>';
  }
}

///--------------------------------------------------------------------
class XUIPropertyBinding extends XUIProperty {
  String? namespace;
  String? binding;
  //String? cacheBinding;

  XUIPropertyBinding(v, n, b) : super(v) {
    namespace = n as String?;
    binding = b as String?;
  }

  @override
  String toHTML(String k) {
    const HtmlEscape htmlEscape =  HtmlEscape();

    final val = htmlEscape.convert(content.toString());

    return '<xui-prop id="$k" val="$val" binding="${binding.toString()}"></xui-prop>';
  }
}

///--------------------------------------------------------------------

enum ParseInfoMode { CONTENT, PROP, KEY, ATTR }

class ParseInfo {
  late StringBuffer parsebuilder;
  int nbTag = 0;
  late ParseInfoMode mode;
  String? context; // nom de l'attribut
  String? prefix;  //  ajoute un prefix à l'attribut   (ex : v-bind:)
  String? orTag;
  String? tagPrefix;

  ParseInfo(content, this.context, this.mode) {
    parsebuilder = StringBuffer(content.toString());
  }
}
