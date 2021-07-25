
$xui.initVuejs = (instanceVue) => {

  instanceVue.$watch('activeAction', function (newValue, oldValue) {
    console.debug('The activeAction name was changed from ' + oldValue + ' to ' + newValue + '!');
  }, { deep: true });

  instanceVue.$watch('activeTab', function (newValue, oldValue) {
    console.debug('The activeTab name was changed from ' + oldValue + ' to ' + newValue + '!');
    $xui.unDisplaySelector();

    if (newValue == 2) {
      // onglet code
      $xui.refreshAction('showCode')   // affiche le code et le xui
    }

    if (oldValue == 1) {
      // retour de l'onglet jsonEditor
      var ctrlStr = $xui.rootdata.jsonEditorDataSrc+"#"+JSON.stringify($xui.rootdata.jsonEditorDataMock);
      if ($xui.lastEditorAppStateValue != ctrlStr) {
        $xui.refreshAction('template:reload-json')   // recharge le json
        $xui.doStoreOnNextReload = true;
      }
    }

    if (newValue == 1) {
      $xui.lastEditorAppStateValue = $xui.rootdata.jsonEditorDataSrc+"#"+JSON.stringify($xui.rootdata.jsonEditorDataMock);

      $xui.vuejs.$refs.root.$refs.routerview.$refs.jsonEditor.editor.set($xui.rootdata.jsonEditorData);
    }

  }, { deep: true });

  instanceVue.$watch('selectedClass', function (newValue, oldValue) {
    console.debug('The selectedClass name was changed from ' + oldValue + ' to ' + newValue + '!');
  }, { deep: true });


  if (false) {
    Vue.use(Vue2Editor);
    const VueEditor = Vue2Editor.VueEditor
    Vue.component(VueEditor)    //vue-editor
  }

  /************************************************************************************ */
  // var monWorker = new Worker('app/worker/workerXUI.js');

  // monWorker.postMessage([5, 7]);
  // console.log('Message envoyé au worker');

  // monWorker.onmessage = function(e) {
  //   console.log('Message reçu depuis le worker', e);
  // }
  /************************************************************************************* */

  //console.debug($xui.rootdata.listCatClass);

  // var list = "ma-2 pt-1 text-justify";
  // new DesignClassManager().initClassSelector(list, listDesignClass);
  // var txt = new DesignClassManager().getClassTextFromSeletor(list, listDesignClass);
  // console.debug(txt);
}

/***************************************************************************************/
class DesignClassManager {

  getClassTextFromSeletor(list, listDesignClass) {
    var text = "";
    for (const catDesc of listDesignClass) {
      for (const classDesc of catDesc.listClass) {
        if (classDesc.type == "check" && classDesc.sel) {
          text = text + classDesc.value + " "
        }
        else if (classDesc.type == "list" && classDesc.sel) {
          classDesc.sel = true;
          text = text + classDesc.value + (classDesc.value != "" ? "-" : "") + classDesc.vl + " "
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
        }
      }
    }

    // ensuite affecte
    var listTag = list.split(" ");
    listTag.forEach(tag => {
      a: for (const catDesc of listDesignClass) {
        for (const classDesc of catDesc.listClass) {
          if (classDesc.type == "check" && classDesc.value == tag) {
            classDesc.sel = true;
            catDesc.open = true;
            catDesc.nbint++;
            break a;
          }
          else if (classDesc.type == "list" && tag.startsWith(classDesc.value + "-")) {
            classDesc.sel = true;
            var lenTag = classDesc.value.length;
            classDesc.vl = tag.substring(lenTag + 1);
            catDesc.open = true;
            catDesc.nbint++;
            break a;
          }
          else if (classDesc.type == "list" && classDesc.value == "" && classDesc.list.indexOf(tag) >= 0) {
            classDesc.sel = true;
            classDesc.vl = tag;
            catDesc.open = true;
            catDesc.nbint++;
            break a;
          }
        }
      }
    });

    for (const catDesc of listDesignClass) {
      catDesc.nb = "" + catDesc.nbint;
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