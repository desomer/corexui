
$xui.MainTabEnum = {
  DESIGN : 0,
  STATE : 1,
  CODE : 2,
  PLUG : 3,
  LOCAL : 4,
  ASSET : 5,
  ENV : 6
}

$xui.DesignTabEnum = {
  DESIGN : 0,
  ROUTE : 1,
  DEV : 2
}

function onChangeMainTab(instanceVue) {
  instanceVue.$watch('main.idxTabMain', (newValue, oldValue) => {
    console.debug(`The idxTabMain name was changed from ${oldValue} to ${newValue}!`);
    if (oldValue==newValue) return;

    $xui.SelectorManager.unDisplaySelector();
    setTimeout(() => {
      $xui.SelectorManager.unDisplaySelector();
    }, 500);

    const rootdata = $xui.getAppState().main;
    const rootStore = $xui.getAppState().store;

    validateStoreModule(rootStore.idxTabStoreModule, oldValue == $xui.MainTabEnum.STATE, newValue != $xui.MainTabEnum.STATE );

    if (newValue == $xui.MainTabEnum.DESIGN && oldValue == $xui.MainTabEnum.LOCAL) {
      const infoFile = $xui.pageDesignManager.getInfoFile("design");
      $xuicore.initPageXUI(infoFile);
    }

    if (newValue == $xui.MainTabEnum.STATE) {
      loadStoreModule();
    }

    if (newValue == $xui.MainTabEnum.CODE) {
      // onglet code
      $xui.refreshAction('showCode'); // affiche le code et le xui
    }

    if (newValue == $xui.MainTabEnum.ENV) {
      // onglet SEO
      document.getElementById("qrcode").querySelectorAll('*').forEach(n => n.remove());
      rootdata.urlApp = $xui.getUrlApp();
      new QRCode(document.getElementById("qrcode"), rootdata.urlApp);
    }

  }, { deep: true });
}

//---------------------------------------------------------------------------------------
function loadStoreModule() {
  //const rootdata = $xui.getAppState().main;
  const storeModule = $xui.getCurrentStoreModule();
  const rootStore = $xui.getAppState().store;

  storeModule.jsonEditorOptions.onEditable = () => false; //TODO ne marche pas
  storeModule.lastEditorAppStateValue = JSON.stringify(storeModule.stateDataMock);

  // reaffiche l'initial State de l'application
  $xui.vuejs.$refs.root.$refs.routermain.$refs.routerview.$refs.jsonEditor[rootStore.idxTabStoreModule].editor.set(storeModule.stateData);
  $xui.vuejs.$refs.root.$refs.routermain.$refs.routerview.$refs.jsonEditor2[rootStore.idxTabStoreModule].editor.set(storeModule.stateDataMock);

  //TODO passer les namespace
  storeModule.ListActions = $xui.getEventMethodsXUI(storeModule.nameModule);
  storeModule.currentCode = "no code";
  storeModule.currentCodeName = "";
  storeModule.currentCodeIdx = -1;
  const idxSelected = storeModule.ListActions.findIndex(element => element.xid == storeModule.currentCodeXid);
  $xui.loadCodeAction(idxSelected);
}

function validateStoreModule(idx, bcode, bstate) {
  const rootStore = $xui.getAppState().store;
  const storeModule = rootStore.listStoreModule[idx];

  if (bcode) {
    if (storeModule.currentCodeIdx >= 0) {
      $xui.saveCodeAction(storeModule);
    }
    storeModule.currentCode = "no code";
    storeModule.currentCodeName = "";
    storeModule.currentCodeIdx = -1;
  }

  if (bstate) {
    // retour de l'onglet jsonEditor
    const ctrlStr = JSON.stringify(storeModule.stateDataMock);
    if (storeModule.lastEditorAppStateValue!=null && storeModule.lastEditorAppStateValue != ctrlStr) {
      $xui.saveStoreNamespace=storeModule.nameModule;
      $xui.doStoreOnNextReload = true;
      $xui.refreshAction('template:reload-json'); // recharge le json
    }
  }
}

//---------------------------------------------------------------------------------------
function onChangeRightPanelTab(instanceVue) {
  instanceVue.$watch('main.idxTabProperties', (newValue, oldValue) => {

    const rootdata = $xui.getAppState().main;

    console.debug(`The idxTabProperties name was changed from ${oldValue} to ${newValue}!`);
    if (rootdata.idxTabProperties <= 2) {
      $xui.displayPropertiesJS($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    }

    if (rootdata.idxTabProperties == 5) {

      if (!rootdata.expandAllCmp) {
        // expandAll le prtemliere fois
        rootdata.expandAllCmp = true;
        $xui.vuejs.$refs.root.$refs.routermain.$refs.routerview.$refs.treeCmp.updateAll(rootdata.expandAllCmp);
      }

      // affecte le composant selectionné
      $xui.SelectorManager.displayInTree();

    }
  }, { deep: true });
}

//---------------------------------------------------------------------------------------
function onChangeDesignerTab(instanceVue) {
  instanceVue.$watch('main.idxTabDesigner', (newValue, oldValue) => {
    $xui.SelectorManager.unDisplaySelector();
    const exampleCss = "// example :  .aClass {}";
    if (newValue==$xui.DesignTabEnum.DEV)
    {
      const infoFile = $xui.pageDesignManager.getInfoFile("template");
      const propValue = $xuicore.getPropertieFromXUI(infoFile, "root", "rootcss");

      const rootdata = $xui.getAppState().main;
      if (propValue==null)
        rootdata.infodev.csseditor= exampleCss;
      else
        rootdata.infodev.csseditor= propValue;
    }

    if (oldValue==$xui.DesignTabEnum.DEV)
    {
      const rootdata = $xui.getAppState().main;
      const jsonProp = [{
        xid : "root",
        variable : "rootcss",
        value : rootdata.infodev.csseditor,
        bind : "@"
      }];
      console.debug("save css");
      $xuicore.saveDesignPropertiesXUI($xui.pageDesignManager.getInfoFile("template"), jsonProp);
    }

  }, { deep: true });
}

function onChangeStoreModuleTab(instanceVue) {
  instanceVue.$watch('store.idxTabStoreModule', (newValue, oldValue) => {
    console.debug(`The idxTabStoreModule name was changed from ${oldValue} to ${newValue}!`);
    validateStoreModule(oldValue, true, true );
    loadStoreModule();
  }, { deep: true });
}



//----------------------------------------------------------------------------------------------------------
$xui.initVuejs = (instanceVue) => {

  onChangeRightPanelTab(instanceVue);
  onChangeMainTab(instanceVue);
  onChangeDesignerTab(instanceVue);
  onChangeStoreModuleTab(instanceVue);

  $xui.router.afterEach((to, from) => {
		// console.log(`afterEach router going to ${to.fullPath} from ${from.fullPath}`);
		// console.log(to, from);
    $xui.SelectorManager.unDisplaySelector();
    $xui.vuejsAppCmpSetting = null; // recharge la liste de cmp
  });


  instanceVue.$watch('main.stateDataSource', (newValue, oldValue ) => {
    const rootdata = $xui.getAppState().main;
    if (rootdata.idxTabMain == 0 && newValue!="" && ( oldValue!="" || newValue=="mock") ) {
      console.debug(` -------------- stateDataSource change  ------------------${oldValue} => ${newValue}`);
      $xui.saveStoreNamespace="";
      $xui.refreshAction('template:reload-json')   // recharge le json
    }
  });

  instanceVue.$watch('main.routeEnable', (newValue, oldValue) => {
    document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "changeConfig", "param": { routeEnable: newValue } }, "*");
  });

  instanceVue.$watch('main.actionEnable', (newValue, oldValue) => {
    document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "changeConfig", "param": { actionEnable: newValue } }, "*");
  });

  instanceVue.$watch('main.selectedClass', function (newValue, oldValue) {
    console.debug(`The selectedClass name was changed from ${oldValue} to ${newValue}!`);
  }, { deep: true });


  setTimeout(() => {
    //let winFrame = ;
    document.addEventListener( "contextmenu", function(e) {
      const rec = document.querySelector("#rootFrame").getBoundingClientRect();
      const x = e.clientX;
      const y = e.clientY;
      console.debug(rec, x, y);
      if (x>rec.x && x<(rec.x+rec.width) && y>rec.y && y<(rec.y+rec.height) )
      {
        e.preventDefault();
        $xui.OpenPopupAction(e);
      }

    });

  }, 1000);


  if (false) {
    Vue.use(Vue2Editor);
    const VueEditor = Vue2Editor.VueEditor
    Vue.component(VueEditor)    //vue-editor
  }
}

/***************************************************************************************/
class DesignClassManager {

  getClassTextFromSelector(list, listDesignClass) {
    let text = "";
    for (const catDesc of listDesignClass) {
      for (const classDesc of catDesc.listClass) {
        if (classDesc.type == "check" && classDesc.sel) {
          text = `${text + classDesc.value} `
        }
        else if (classDesc.type == "list" && classDesc.sel) {
          classDesc.sel = true;
          var v = classDesc.value + (classDesc.value != "" ? "-" : "") + classDesc.vl;
          if (v.startsWith("rounded") && v.endsWith("-md")) {
            v = v.substring(0, v.length - 3);
          }
          text = `${text + v} `
        }
      }
    }
    return text;
  }

  initClassSelector(list, listDesignClass) {

    // par de defaut à false
    for (const catDesc of listDesignClass) {
      catDesc.open = false;
      catDesc.nbint = 0;
      for (const classDesc of catDesc.listClass) {
        if (classDesc.type == "check") {
          classDesc.sel = false;
        }
        else if (classDesc.type == "list") {
          classDesc.sel = false;
          classDesc.vl = classDesc.list[0];
          classDesc.vlold = classDesc.list[0];
        }
      }
    }

    // ensuite affecte
    const listTag = list.split(" ");
    listTag.forEach(tag => {
      a: for (const catDesc of listDesignClass) {
        for (const classDesc of catDesc.listClass) {
          if (classDesc.type == "list" && tag.startsWith("rounded") && tag == classDesc.value) {
            tag = `${tag}-md`;
          }

          if (classDesc.type == "check" && classDesc.value == tag) {
            classDesc.sel = true;
            catDesc.open = true;
            catDesc.nbint++;
            break a;
          }
          else if (classDesc.type == "list" && tag.startsWith(`${classDesc.value}-`)) {
            classDesc.sel = true;
            var lenTag = classDesc.value.length;
            classDesc.vl = tag.substring(lenTag + 1);
            classDesc.vlold = classDesc.vl;
            catDesc.open = true;
            catDesc.nbint++;
            break a;
          }
          else if (classDesc.type == "list" && classDesc.value == "" && classDesc.list.includes(tag)) {
            classDesc.sel = true;
            classDesc.vl = tag;
            classDesc.vlold = classDesc.vl;
            catDesc.open = true;
            catDesc.nbint++;
            break a;
          }
        }
      }
    });

    for (const catDesc of listDesignClass) {
      catDesc.nb = `${catDesc.nbint}`;
    }

  }
}



/***************************************************************************************/
/*
<div id="example">
  <editable :content="text2" @updatekkk="text2 = $event"></editable>
  <div>
    <pre>{{$data |json }}</pre>
  </div>
</div>

var example = new Vue({
  el: '#example',
  data: {
    text2:"This text is editable!"
  }
});

*/