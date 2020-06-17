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
    String startTag= "[[";
    String endTag= "]]";

    int next = parse.indexOf(startTag, idx);
    // if (next==-1)
    // {
    //     startTag="--";
    //     endTag= "--";
    //     next = parse.indexOf(startTag, idx);
    // }
    
    int nextEnd = next;
    if (next >= 0) {
      nextEnd = parse.indexOf(endTag, next+1);
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
}

///--------------------------------------------------------------------

enum ParseInfoMode { CONTENT, PROP, KEY, ATTR}

class ParseInfo
{
    StringBuffer parsebuilder;
    int nbTag=0;
    ParseInfoMode mode;
    String context; // nom de l'attibut 

    ParseInfo(String content, String context, ParseInfoMode mode)
    {
        parsebuilder = StringBuffer(content);
        this.context = context;
        this.mode=mode;
    }
}