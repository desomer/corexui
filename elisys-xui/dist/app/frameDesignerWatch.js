
$xui.initVuejs = (instanceVue) => {

  instanceVue.$watch('activeAction', function (newValue, oldValue) {
    console.debug('The activeAction name was changed from ' + oldValue + ' to ' + newValue + '!');
  }, { deep: true });

  instanceVue.$watch('activeTab', function (newValue, oldValue) {
    console.debug('The activeTab name was changed from ' + oldValue + ' to ' + newValue + '!');
    if (newValue == 1) {
      // onglet code
      $xui.refreshAction('final')   // affiche le code et le yaml
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
          text = text + classDesc.value + "-" + classDesc.vl + " "
        }
      }
    }
    return text;
  }

  initClassSelector(list, listDesignClass) {

    for (const catDesc of listDesignClass) {
      for (const classDesc of catDesc.listClass) {
        if (classDesc.type == "check") {
          classDesc.sel = false;
        }
        else if (classDesc.type == "list") {
          classDesc.sel = false;
          classDesc.vl = "1";
        }
      }
    }

    var listTag = list.split(" ");
    listTag.forEach(tag => {
      a: for (const catDesc of listDesignClass) {
        for (const classDesc of catDesc.listClass) {
          if (classDesc.type == "check" && classDesc.value == tag) {
            classDesc.sel = true;
            catDesc.open = true;
            break a;
          }
          else if (classDesc.type == "list" && tag.startsWith(classDesc.value + "-")) {
            classDesc.sel = true;
            var descTag = tag.split("-");
            classDesc.vl = descTag[1];
            catDesc.open = true;
            break a;
          }
        }
      }
    });
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