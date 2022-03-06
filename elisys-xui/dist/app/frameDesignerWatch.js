
$xui.MainTabEnum = {
  DESIGN : 0,
  STATE : 1,
  CODE : 2,
  PLUG : 3,
  LOCAL : 4,
  ASSET : 5,
  ENV : 6
}

function onChangeMainTab(instanceVue) {
  instanceVue.$watch('main.idxTabMain', (newValue, oldValue) => {
    console.debug(`The idxTabMain name was changed from ${oldValue} to ${newValue}!`);

    $xui.SelectorManager.unDisplaySelector();
    setTimeout(() => {
      $xui.SelectorManager.unDisplaySelector();
    }, 500);

    const rootdata = $xui.getAppState().main;

    if (oldValue == $xui.MainTabEnum.STATE)
    {
      if (rootdata.currentCodeIdx>=0)
      {
        $xui.saveCodeAction();
      }
      rootdata.currentCode="no code";
      rootdata.currentCodeName="";
      rootdata.currentCodeIdx=-1;
    }

    if (newValue == $xui.MainTabEnum.DESIGN) {
      // retour de l'onglet jsonEditor
      const ctrlStr = `${rootdata.stateDataSource}#${JSON.stringify(rootdata.stateDataMock)}`;
      if ($xui.lastEditorAppStateValue != ctrlStr) {
        $xui.refreshAction('template:reload-json'); // recharge le json
        $xui.doStoreOnNextReload = true;
      }
    }

    if (newValue == $xui.MainTabEnum.DESIGN && oldValue == $xui.MainTabEnum.LOCAL) {
      const infoFile = $xui.pageDesignManager.getInfoFile("design");
      $xuicore.initPageXUI(infoFile);
    }

    if (newValue == $xui.MainTabEnum.STATE) {
      $xui.lastEditorAppStateValue = `${rootdata.stateDataSource}#${JSON.stringify(rootdata.stateDataMock)}`;

      // reaffiche l'initial State de l'application
      $xui.vuejs.$refs.root.$refs.routermain.$refs.routerview.$refs.jsonEditor.editor.set(rootdata.stateData);

      rootdata.ListActions=$xui.getCodeEventXUI();
      rootdata.currentCode="no code";
      rootdata.currentCodeName="";
      rootdata.currentCodeIdx=-1;
      const idxSelected = rootdata.ListActions.findIndex(element => element.xid == rootdata.currentCodeXid);
      $xui.loadCodeAction(idxSelected);
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
function onChangeDesignerlTab(instanceVue) {
  instanceVue.$watch('main.idxTabDesigner', (newValue, oldValue) => {
    $xui.SelectorManager.unDisplaySelector();
  }, { deep: true });
}

//----------------------------------------------------------------------------------------------------------
$xui.initVuejs = (instanceVue) => {

  onChangeRightPanelTab(instanceVue);
  onChangeMainTab(instanceVue);
  onChangeDesignerlTab(instanceVue);

  $xui.router.afterEach((to, from) => {
		// console.log(`afterEach router going to ${to.fullPath} from ${from.fullPath}`);
		// console.log(to, from);
    $xui.SelectorManager.unDisplaySelector();
    $xui.vuejsAppCmpSetting = null; // recharge la liste de cmp
  });


  instanceVue.$watch('main.stateDataSource', (newValue, oldValue) => {
    const rootdata = $xui.getAppState().main;
    if (rootdata.idxTabMain == 0 && newValue!="" ) {
      $xui.refreshAction('template:reload-json')   // recharge le json
      //$xui.doStoreOnNextReload = true;
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