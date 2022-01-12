
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


    if (oldValue == $xui.MainTabEnum.STATE)
    {
      if ($xui.rootdata.currentCodeIdx>=0)
      {
        $xui.saveCodeAction();
      }
      $xui.rootdata.currentCode="no code";
      $xui.rootdata.currentCodeName="";
      $xui.rootdata.currentCodeIdx=-1;
    }

    if (newValue == $xui.MainTabEnum.DESIGN && oldValue == $xui.MainTabEnum.STATE) {
      // retour de l'onglet jsonEditor
      const ctrlStr = `${$xui.rootdata.stateDataSource}#${JSON.stringify($xui.rootdata.stateDataMock)}`;
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
      $xui.lastEditorAppStateValue = `${$xui.rootdata.stateDataSource}#${JSON.stringify($xui.rootdata.stateDataMock)}`;

      // reaffiche l'initial State de l'application
      $xui.vuejs.$refs.root.$refs.routermain.$refs.routerview.$refs.jsonEditor.editor.set($xui.rootdata.stateData);
      $xui.rootdata.ListActions=$xui.getCodeEventXUI();
      $xui.rootdata.currentCode="no code";
      $xui.rootdata.currentCodeName="";
      $xui.rootdata.currentCodeIdx=-1;
      const idxSelected = $xui.rootdata.ListActions.findIndex(element => element.xid == $xui.rootdata.currentCodeXid);
      $xui.loadCodeAction(idxSelected);
    }

    if (newValue == $xui.MainTabEnum.CODE) {
      // onglet code
      $xui.refreshAction('showCode'); // affiche le code et le xui
    }


    if (newValue == $xui.MainTabEnum.ENV) {
      // onglet SEO
      document.getElementById("qrcode").querySelectorAll('*').forEach(n => n.remove());
      $xui.rootdata.urlApp = $xui.getUrlApp();
      new QRCode(document.getElementById("qrcode"), $xui.rootdata.urlApp);
    }

  }, { deep: true });
}

//---------------------------------------------------------------------------------------
function onChangeRightPanelTab(instanceVue) {
  instanceVue.$watch('main.idxTabProperties', (newValue, oldValue) => {

    console.debug(`The idxTabProperties name was changed from ${oldValue} to ${newValue}!`);
    if ($xui.rootdata.idxTabProperties <= 2) {
      $xui.displayPropertiesJS($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    }

    if ($xui.rootdata.idxTabProperties == 5) {

      if (!$xui.rootdata.expandAllCmp) {
        // expandAll le prtemliere fois
        $xui.rootdata.expandAllCmp = true;
        $xui.vuejs.$refs.root.$refs.routermain.$refs.routerview.$refs.treeCmp.updateAll($xui.rootdata.expandAllCmp);
      }

      // affecte le composant selectionné
      $xui.SelectorManager.displayInTree();

    }
  }, { deep: true });
}

//----------------------------------------------------------------------------------------------------------
$xui.initVuejs = (instanceVue) => {

  onChangeRightPanelTab(instanceVue);
  onChangeMainTab(instanceVue);

  $xui.router.afterEach((to, from) => {
		// console.log(`afterEach router going to ${to.fullPath} from ${from.fullPath}`);
		// console.log(to, from);
    $xui.SelectorManager.unDisplaySelector();
    $xui.vuejsAppCmpSetting = null; // recharge la liste de cmp
  });

  instanceVue.$watch('main.stateDataSource', (newValue, oldValue) => {
    if ($xui.rootdata.idxTabMain == 0 && newValue!="" ) {
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