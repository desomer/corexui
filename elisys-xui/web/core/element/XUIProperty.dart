class XUIProperty {
  dynamic content;

  XUIProperty(v) {
    this.content = v;
  }


  static parse(StringBuffer parse, Function action) {
    int idx = 0;
    while ((idx = _parseNext(parse, idx, action)) >= 0) {}
  }

  static int _parseNext(StringBuffer parsebuilder, int idx, Function action) {
    String parse = parsebuilder.toString();
    int next = parse.indexOf("__", idx);
    int nextEnd = next;
    if (next >= 0) {
      nextEnd = parse.indexOf("__", next+1);
    }

    if (next >= 0 && nextEnd > 0) {
      String strStart = parse.substring(0, next);
      String strEnd = parse.substring(nextEnd + 2, parse.length);
      String tag = parse.substring(next + 2, nextEnd);
      tag = action(tag);
      parsebuilder.clear();
      nextEnd = (strStart + tag).length;
      parsebuilder.write(strStart + tag + strEnd);
      return nextEnd;
    } else
      return -1;
  }
}

/***************************************************************************** */
