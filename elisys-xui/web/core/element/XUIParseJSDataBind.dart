import 'dart:collection';

import 'XUIElement.dart';

class XUIParseJSDataBinding {

    HashMap<String, JSDataBindingProp> dataBindProperties;

    void parseAttr(XUIElementHTML elem ,String key, String value)
    {
        if (key.startsWith(":"))
        {
        //   print("db $key => $value");
        }

        if (key.startsWith("v-model"))
        {
        //   print("db $key => $value");
        }

        if (value.contains("{{"))
        {
        //   print("db $key => $value");
        }
    }

    void parseContent(XUIElementHTML elem, String value)
    {
      if (value.contains("{{"))
        {
         //  print("db content => $value");
        }
    }

}

class JSDataBindingProp {
    String path;
    String value;
}