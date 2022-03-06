import 'dart:collection';

import 'XUIConfigManager.dart';
import 'XUIEngine.dart';
import 'XUIFactory.dart';
import 'XUIJSInterface.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';
import 'native/register.dart';

class XUIBindingStoreFactory
{
    var dicoObjBind = LinkedHashMap<String, List<XUIBinding>>();
    var dicoObjType = LinkedHashMap<String, XUIBinding>();
    var dicoObjNameSpace = LinkedHashMap<String, String>();
}


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
      //print("*************************** > "+ prop.key+ " =>" + prop.value.content);
      // gestion des var :xxx
      if (p.cacheBindingProp==null || prop.value.content!=p.cacheBindingProp!.binding)
      {
          p.cacheBindingProp = XUIPropertyBinding("", null, prop.value.content);
      }

      var pme = MapEntry<String, XUIPropertyBinding>(prop.key, p.cacheBindingProp!);
      _addXUIBindingPhase1(pme, model, elemHtml);
    }

    if (prop.key.startsWith("@")) {
      // gestion de @event
      // si true appel de processPropertiesBindingPhase1Event 
      return true;
    }

    if (p.content is String && p.content.startsWith("{{") == true) {
      // gestion du {{value}}
      // var parseInfo = ParseInfo(prop, null, ParseInfoMode.PROP);
      // String? varNameSpace = elemHtml.searchPropertyXUI(PROP_VAR_NAMESPACE+"@0+", 0, parseInfo) as String?;

      var varName = p.content.toString().substring(2);
      varName = varName.substring(0, varName.length - 2);
      var propB = XUIPropertyBinding("", null, varName);
      var pme = MapEntry<String, XUIPropertyBinding>(prop.key, propB);
      _addXUIBindingPhase1(pme, model, elemHtml);
    }

    if (p is XUIPropertyBinding) {
      var pme = MapEntry<String, XUIPropertyBinding>(prop.key, p);
      _addXUIBindingPhase1(pme, model, elemHtml);
    }

    return false;
  }

  void processPropertiesBindingPhase1Event(
      MapEntry<String, XUIProperty> prop, XUIElementHTML elemHtml) {
    if (prop.key.startsWith("@")) {
      elemHtml.doAddEventPhase2(engine, prop.key, prop.value);
    }
  }

  void _addXUIBindingPhase1(MapEntry<String, XUIPropertyBinding> proper, XUIModel model,  XUIElementHTML elemHtml) {

    XUIPropertyBinding prop = proper.value;

    var parseInfo = ParseInfo(prop, null, ParseInfoMode.PROP);
    var name = prop.binding!;

    int isArray = name.lastIndexOf("[]");
    if (isArray <= 0) {
      //print("A ==================> "+ name + " => " + (prop.cacheBinding?.toString()??"?"));
      XUIElementHTML? p = elemHtml.parent;

      while (p != null) {
        String? varitems = p.searchPropertyXUI(PROP_VAR_ITEMS, 0, parseInfo);
        if (varitems!=null)
        {
          if (isArray<=0)
          {
              varitems=varitems.substring(varitems.indexOf(".")+1);  // retrait du scope
              name= "$varitems[].$name";
          }

        }
        p = p.parent;
      }
      prop.cacheBinding=name;

      // String? varitems = elemHtml.searchPropertyXUI(PROP_VAR_ITEMS+"@1+", 0, parseInfo);
      // if (varitems != null) {
      //   varitems = varitems.substring(varitems.indexOf(".") + 1);
      //   name = varitems + "[]." + name;
      //   //print("-------------- varitems --------------> " + name);
      //   prop.cacheBinding=name;
      // }
    }

    //if (prop.namespace==null)
   // {
      String? varNameSpace = elemHtml.searchPropertyXUI(PROP_VAR_NAMESPACE+"@0+", 0, parseInfo) as String?;
      prop.namespace=varNameSpace;
   // }

    if (prop.namespace==null)
    {
        prop.namespace="main";
    }

    if (XUIConfigManager.verboseBinding) {
      XUIConfigManager.printc("Prop key [" +
          proper.key.toString() +
          "] on var binding [" +
          (prop.namespace??"?") + "." + name +
          "] xid=" +
          model.elemXUI.xid.toString());
    }

    // affecte le binding pour la creation du JSON de binding
    bindingInfo[prop.namespace!+"."+name] =
        XUIBinding(prop.namespace!, proper.key, name, prop.content, model.elemXUI.xid!);
  }


  dynamic getEventMethodsXUI(String namespace) {
    var listEvent = [];
    engine.bindingManager.eventInfo.forEach((key, value) {
      if (value.namespace==namespace) {
        listEvent.add(value);
      }
    });
    return listEvent;
  }


  void processPhase2JS(XUIContext ctx) {

    var bindEngine = XUIBindingStoreFactory();

    doInitBindEngine(bindEngine);
    doInitBindEngineAction(bindEngine);

    if (bindEngine.dicoObjNameSpace["main"]==null)
    {
      //creation du module main m^me si vide
      bindEngine.dicoObjNameSpace["main"]="main";
    }

    List mapState= [];
    bindEngine.dicoObjNameSpace.forEach( (namespace, value) {

      StringBuffer jsonBinding = StringBuffer();
      processPhase2JSBinding(namespace, bindEngine.dicoObjBind, jsonBinding);
      bindingState bs = getBindPropertyOnRoot(namespace, jsonBinding);
      bs.actions= getEventMethodsXUI(namespace);
      mapState.add(bs);
    });


    var store = "";
    try {
      store = generateApplicationStoreJS(mapState);
     // print(store);
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

  bindingState getBindPropertyOnRoot(String namespace, StringBuffer jsonBinding) {

    bindingState bs = bindingState();

    if (XUIConfigManager.verboseBinding) {
      print("--------- namespace " + namespace + " object=" + jsonBinding.toString());
    }
        
    XUIProperty? propBinding = engine.getXUIPropertyFromDesign("root", PROP_BIND_PREFIX+"_"+namespace );
    
    if (propBinding==null && namespace=="main") {
      propBinding = engine.getXUIPropertyFromDesign("root", PROP_BIND_PREFIX );
    }
    
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
      newBinding = generateApplicationStateJS(namespace, templateBinding, PropMock);
    }
    else if (PropMock != "") {
      // toujour la valeur de la property mok si pas en mode design
      newBinding =  PropMock; 
    }
    
    bs.state= newBinding;
    bs.namespace=namespace;

    return bs;
  }

  //**************************************************************************************** */
  void doInitBindEngineAction(XUIBindingStoreFactory bindEngine) {
      this.eventInfo.forEach((p, bindInfo) {
        bindEngine.dicoObjNameSpace[bindInfo.namespace]=bindInfo.namespace;

      });
   }

  void doInitBindEngine(XUIBindingStoreFactory bindEngine) {
    this.bindingInfo.forEach((k, bindInfo) {
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

      var path = bindInfo.namespace;
      bindEngine.dicoObjNameSpace[bindInfo.namespace]=bindInfo.namespace;

      if (bindInfo.attr.contains(".")) {
        //   gestion de path
        int niv = 0;
        var listAttr = bindInfo.attr.split(".");
        int lastNiv = listAttr.length - 1;

        listAttr.forEach((attr) {
          var newPath = path + "." + attr;
          // XUIConfigManager.printc("--->" + element);
          if (niv != lastNiv) {
            if (bindEngine.dicoObjBind[path] == null) {
              bindEngine.dicoObjBind[path] = [];
            }

            bool isArray = false;
            if (newPath.endsWith("[]")) {
              newPath = newPath.substring(0, newPath.length - 2);
              isArray = true;
            }

            if (!isArray && bindEngine.dicoObjType[newPath] == null) {
              var newObj = XUIBinding(bindInfo.namespace, "?", attr, "{}", "?");
              newObj.type = "object";
              bindEngine.dicoObjBind[path]?.add(newObj);
              bindEngine.dicoObjType[newPath] = newObj;
              // XUIConfigManager.printc(
              //     "---> addObj " + element + " on path " + path);
            }
          } else {
            // ajout de l'attribut
            var newObj = XUIBinding(bindInfo.namespace,
                bindInfo.propName, attr, bindInfo.value, bindInfo.xid);
            newObj.type = bindInfo.type;
            if (bindEngine.dicoObjBind[path] == null) {
              bindEngine.dicoObjBind[path] = [];
            }
            bindEngine.dicoObjBind[path]?.add(newObj);
            // XUIConfigManager.printc("---> addAttr " + element + " on " + path);
          }

          path = newPath;
          niv++;
        });
      } else {
        // add attribut sur le root '.'
        if (bindEngine.dicoObjBind[path] == null) {
          bindEngine.dicoObjBind[path] = [];
        }

        if (bindInfo.type == "array") {
          bindEngine.dicoObjType[path + "." + bindInfo.attr] = bindInfo;
          // XUIConfigManager.printc(
          //     "---> set array " + bindInfo.attr + " on " + path);
        }

        bindEngine.dicoObjBind[path]?.add(bindInfo);
      }
    });
  }

  void processPhase2JSBinding(
      String objName,
      LinkedHashMap<String, List<XUIBinding>> dicoObjBind,
      StringBuffer jsonBinding) {

    dicoObjBind[objName]?.forEach((bindInfo) {
      var type = bindInfo.type;
      var isNotString = (type == "bool" || type == "int" || type == "dec");
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
      if ((v == null || v == "") && type == "dec") {
        v = '0.0';
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
  void addActionCodeMethod(XUIElement elem, XUIBindingEvent eventMth) {
    eventInfo[eventMth.namespace +"#"+  eventMth.name] = eventMth;

    XUIProperty? propCode = elem.propertiesXUI?["#" + eventMth.eventName];
    eventMth.code = propCode?.content ?? "";

    // print("******* EVENT ++++ " +
    //     eventMth.namespace +"#"+  eventMth.name +
    //     " on " +
    //     eventMth.xid +
    //     " execute method " +
    //     eventMth.name);
  }
}


