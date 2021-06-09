class XUIProperty {
  dynamic content;

  XUIProperty(v) {
    this.content = v;
  }

  static parse(ParseInfo parseInfo, Function action) {
    int idx = 0;
    while ((idx = _parseNext(parseInfo, idx, action)) >= 0) {}
  }

  static int _parseNext(ParseInfo parseInfo, int idx, Function action) {
    String parse = parseInfo.parsebuilder.toString();
    String startTag = "[[";
    String endTag = "]]";

    int next = parse.indexOf(startTag, idx);
    // if (next==-1)
    // {
    //     startTag="--";
    //     endTag= "--";
    //     next = parse.indexOf(startTag, idx);
    // }

    int nextEnd = next;
    if (next >= 0) {
      nextEnd = parse.indexOf(endTag, next + 1);
    }

    if (next >= 0 && nextEnd > 0) {
      parseInfo.nbTag++;
      String strStart = parse.substring(0, next);
      String strEnd = parse.substring(nextEnd + 2, parse.length);
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
    return '<xui-prop id="${k}" val="${content.toString()}"></xui-prop>';
  }
}

///--------------------------------------------------------------------
class XUIPropertyBinding extends XUIProperty {
  String? binding;

  XUIPropertyBinding(v, b) : super(v) {
    this.binding = b;
  }

  String toHTML(String k) {
    return '<xui-prop id="${k}" val="${content.toString()}" binding="${binding.toString()}"></xui-prop>';
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


  ParseInfo(content, String? context, ParseInfoMode mode) {
    parsebuilder = StringBuffer(content.toString());
    this.context = context;
    this.mode = mode;
  }
}
