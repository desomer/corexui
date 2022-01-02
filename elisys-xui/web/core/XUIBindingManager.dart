import 'dart:collection';

import 'XUIConfigManager.dart';
import 'XUIEngine.dart';
import 'XUIFactory.dart';
import 'XUIJSInterface.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';
import 'native/register.dart';

class XUIBindingManager {
  XUIEngine engine;
  var bindingInfo = LinkedHashMap<String, XUIBinding>();
  var eventInfo = LinkedHashMap<String, XUIBindingEvent>();
  var afterJsonValidator = LinkedHashMap<String, StringBuffer>();
  var validatorInfo = LinkedHashMap<String, XUIBinding>();

  XUIBindingManager(this.engine);

  bool processPropertiesBindingPhase1(MapEntry<String, XUIProperty> prop,
      XUIModel model, XUIElementHTML elemHtml) {
    XUIProperty p = prop.value;

    if (prop.key.startsWith(":")) {
      // gestion du v-for    :items
      var propB = XUIPropertyBinding("", prop.value.content);
      var pme = MapEntry<String, XUIProperty>(prop.key, propB);
      _addXUIBinding(pme, model, elemHtml);
    }

    if (prop.key.startsWith("@")) {
      //print("******************* event > " + keyAttr);
      return true;
    }

    if (p.content is String && p.content.startsWith("{{") == true) {
      // gestion du {{value}}
      var varName = p.content.toString().substring(2);
      varName = varName.substring(0, varName.length - 2);
      var propB = XUIPropertyBinding("", varName);
      var pme = MapEntry<String, XUIProperty>(prop.key, propB);
      _addXUIBinding(pme, model, elemHtml);
    }

    if (p is XUIPropertyBinding) {
      _addXUIBinding(prop, model, elemHtml);
    }

    return false;
  }

  void processPropertiesBindingPhase2(
      MapEntry<String, XUIProperty> prop, XUIElementHTML elemHtml) {
    if (prop.key.startsWith("@")) {
      elemHtml.doAddEventPhase2(engine, prop.key, prop.value);
    }
  }

  void _addXUIBinding(MapEntry<String, XUIProperty> prop, XUIModel model,
      XUIElementHTML elemHtml) {
    XUIPropertyBinding p = prop.value as XUIPropertyBinding;

    var name = p.binding!;
    int isArray = name.lastIndexOf("[]");

    if (isArray <= 0) {
      String? varitems = elemHtml.searchPropertyXUI(
          ":varitems@1+", 0, ParseInfo(p, null, ParseInfoMode.PROP));
      if (varitems != null) {
        varitems = varitems.substring(varitems.indexOf(".") + 1);
        name = varitems + "[]." + name;
        //print("-------------- varitems --------------> " + name);
      }
    }

    if (XUIConfigManager.verboseBinding) {
      XUIConfigManager.printc("Prop key [" +
          prop.key.toString() +
          "] on var binding [" +
          name +
          "] xid=" +
          model.elemXUI.xid.toString());
    }

    // affecte le binding pour la creation du JSON de binding
    bindingInfo[name] =
        XUIBinding(prop.key, name, p.content, model.elemXUI.xid!);
  }

  dynamic getEventMethodsXUI() {
    var listEvent = [];
    engine.bindingManager.eventInfo.forEach((key, value) {
      listEvent.add(value);
    });
    return listEvent;
  }

  void processPhase2JS(XUIContext ctx) {
    var dicoObjBind = LinkedHashMap<String, List<XUIBinding>>();
    var dicoObjType = LinkedHashMap<String, XUIBinding>();
    StringBuffer jsonBinding = StringBuffer();

    doDicoObjectBinding(dicoObjBind, dicoObjType);
    processPhase2JSBinding("root", dicoObjBind, jsonBinding);

    XUIProperty? propBinding =
        engine.getXUIPropertyFromDesign("root", "binding");


    String PropMock = "";
    if (propBinding != null) {
      PropMock = propBinding.content.toString();
    }

    String templateBinding = "";
    if (jsonBinding.isNotEmpty) {
      templateBinding = jsonBinding.toString();
      // XUIConfigManager.printc("---> ************ TMPL *************** " +
      //     templateBinding.toString());
    }

    var newBinding = templateBinding;
    if (engine.isModeDesign()) {
      newBinding = generateApplicationStateJS(templateBinding, PropMock);
    }
    if (!engine.isModeDesign() && PropMock != "") {
      newBinding =
          PropMock; // toujour la valeur de la property mok si pas en mode design
    }

    var store = "";
    try {
      store = generateApplicationStoreJS(newBinding, getEventMethodsXUI());
    } catch (e) {
      XUIConfigManager.printc("error" + e.toString());
    }

    // XUIConfigManager.printc("---> ************ BIND STORE *************** " +
    //     engine.xuiFile.reader.id +
    //     "\n" +
    //     str);

    StringBuffer buf = NativeInjectText.getcacheText(JS_BINDING)!;
    buf.clear();
    // affecte le js du store
    buf.write(store);
  }

  //**************************************************************************************** */
  void doDicoObjectBinding(LinkedHashMap<String, List<XUIBinding>> dicoObjBind,
      LinkedHashMap<String, XUIBinding> dicoObjType) {
    this.bindingInfo.forEach((key, bindInfo) {
      String type = "?";

      SlotInfo? slotInfo = engine.getSlotInfo(bindInfo.xid, bindInfo.xid);
      if (slotInfo != null) {
        DocInfo? doc = engine.docInfo[slotInfo.docId];
        if (doc==null)
          throw new Exception("documentation introuvable " + (slotInfo.docId??"NR") + " sur xid "+ bindInfo.xid);

        DocVariables varInfo = DocVariables();
        for (DocVariables varCmp in doc.variables) {
          if (varCmp.id == bindInfo.propName) {
            varInfo = varCmp;
            break;
          }
        }

        type = varInfo.bindType != null ? varInfo.bindType! : "?";

        // XUIConfigManager.printc("/*/*/*/ xid=" +
        //     bindInfo.xid +
        //     " bind on {" +
        //     bindInfo.attr +
        //     "} as [" +
        //     type +
        //     "] doc on " +
        //     slotInfo.docId! +
        //     "#" +
        //     bindInfo.propName);
      }

      var isBool = false;
      if (bindInfo.value is bool ||
          (bindInfo.value == "true" || bindInfo.value == "false")) {
        isBool = true;
      }
      bindInfo.type = isBool ? "bool" : type;

      var path = "root";

      if (bindInfo.attr.contains(".")) {
        //   gestion de path
        int niv = 0;
        var listAttr = bindInfo.attr.split(".");
        int lastNiv = listAttr.length - 1;

        listAttr.forEach((element) {
          var newPath = path + "." + element;
          // XUIConfigManager.printc("--->" + element);
          if (niv != lastNiv) {
            if (dicoObjBind[path] == null) {
              dicoObjBind[path] = [];
            }

            bool isArray = false;
            if (newPath.endsWith("[]")) {
              newPath = newPath.substring(0, newPath.length - 2);
              isArray = true;
            }

            if (!isArray && dicoObjType[newPath] == null) {
              var newObj = XUIBinding("?", element, "{}", "?");
              newObj.type = "object";
              dicoObjBind[path]?.add(newObj);
              dicoObjType[newPath] = newObj;
              // XUIConfigManager.printc(
              //     "---> addObj " + element + " on path " + path);
            }
          } else {
            // ajout de l'attribut
            var newObj = XUIBinding(
                bindInfo.propName, element, bindInfo.value, bindInfo.xid);
            newObj.type = bindInfo.type;
            if (dicoObjBind[path] == null) {
              dicoObjBind[path] = [];
            }
            dicoObjBind[path]?.add(newObj);
            // XUIConfigManager.printc("---> addAttr " + element + " on " + path);
          }

          path = newPath;
          niv++;
        });
      } else {
        // add attribut sur le root '.'
        if (dicoObjBind[path] == null) {
          dicoObjBind[path] = [];
        }

        if (bindInfo.type == "array") {
          dicoObjType[path + "." + bindInfo.attr] = bindInfo;
          // XUIConfigManager.printc(
          //     "---> set array " + bindInfo.attr + " on " + path);
        }

        dicoObjBind[path]?.add(bindInfo);
      }
    });
  }

  void processPhase2JSBinding(
      String objName,
      LinkedHashMap<String, List<XUIBinding>> dicoObjBind,
      StringBuffer jsonBinding) {
    dicoObjBind[objName]?.forEach((bindInfo) {
      var type = bindInfo.type;
      var isNotString = (type == "bool" || type == "int");
      var v = isNotString ? (bindInfo.value) : ('"' + bindInfo.value + '"');

      if (type == "array") {
        var newjsonBinding = StringBuffer();
        processPhase2JSBinding(
            objName + "." + bindInfo.attr, dicoObjBind, newjsonBinding);
        v = "[{ " + newjsonBinding.toString() + " }]";
      }

      if ((v == null || v == "") && type == "bool") {
        v = 'false';
      }

      if ((v == null || v == "") && type == "int") {
        v = '0';
      }

      if (type == "object") {
        var newjsonBinding = StringBuffer();
        processPhase2JSBinding(
            objName + "." + bindInfo.attr, dicoObjBind, newjsonBinding);
        v = "{ " + newjsonBinding.toString() + " }";
      }

      if (type != "item-array") {
        if (jsonBinding.isNotEmpty) {
          jsonBinding.write(',');
        }
        jsonBinding.write('"' + bindInfo.attr + '": ' + v.toString());
      }
    });
  }

  //-------------------------------------- RENAME  -----------------------------------------------

  bool remaneVariable(String oldName, String newName) {
    print("ddddddddddddddddddddddd remane " + oldName + "  =>   " + newName);
    return true;
  }

  //-------------------------------------- EVENT TO METHOD  -----------------------------------------------
  void addEventMethod(XUIElement elem, XUIBindingEvent eventMth) {
    eventInfo[eventMth.name] = eventMth;

    XUIProperty? propCode = elem.propertiesXUI?["#" + eventMth.eventName];
    eventMth.code = propCode?.content ?? "";

    // print("******* EVENT ++++ " +
    //     eventMth.eventName +
    //     " on " +
    //     eventMth.xid +
    //     " execute method " +
    //     eventMth.name);
  }
}
