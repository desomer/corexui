$xui.initVuejs = (vuejs) => {

  vuejs.$watch('activeAction', function (newValue, oldValue) {
    console.debug('The activeAction name was changed from ' + oldValue + ' to ' + newValue + '!');
  }, { deep: true });

  vuejs.$watch('activeTab', function (newValue, oldValue) {
    console.debug('The activeTab name was changed from ' + oldValue + ' to ' + newValue + '!');
    if (newValue == 1) {
      // onglet code
      $xui.refreshAction('final')   // affiche le code et le yaml
    }

  }, { deep: true });

  vuejs.$watch('selectedClass', function (newValue, oldValue) {
    console.debug('The selectedClass name was changed from ' + oldValue + ' to ' + newValue + '!');
  }, { deep: true });

  Vue.use(Vue2Editor);
  const VueEditor = Vue2Editor.VueEditor
  Vue.component(VueEditor)    //vue-editor


  var listDesignClass = [
    {
      title: "size",
      icon: "mdi-format-text",
      open: true,
      listClass: [
        { sel: false, type: 'check', text: 'fill height', value: 'fill-height' },
      ]
    },
    {
    title: "Text",
    icon: "mdi-format-text",
    open: false,
    listClass: [
      { sel: false, type: 'check', text: 'text left', value: 'text-left' },
      { sel: false, type: 'check', text: 'text center', value: 'text-center' },
      { sel: false, type: 'check', text: 'text right', value: 'text-right' },
      { sel: false, type: 'check', text: 'text justify', value: 'text-justify' },
      { sel: false, type: 'divider' },
      { sel: false, type: 'check', text: 'text no wrap', value: 'text-no-wrap' },
      { sel: false, type: 'check', text: 'text lowercase', value: 'text-lowercase' },
      { sel: false, type: 'check', text: 'text uppercase', value: 'text-uppercase' },
      { sel: false, type: 'check', text: 'text capitalize', value: 'text-capitalize' }
    ],
  },
  {
    title: "Padding",
    icon: "mdi-checkbox-intermediate",
    open: false,
    listClass: [
      { sel: false, text: 'all', value: 'pa', type: 'list', vl: '1', list: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'x', value: 'px', type: 'list', vl: '1', list: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'y', value: 'py', type: 'list', vl: '1', list: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'top', value: 'pt', type: 'list', vl: '1', list: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'bottom', value: 'pb', type: 'list', vl: '1', list: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'left', value: 'pl', type: 'list', vl: '1', list: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'right', value: 'pr', type: 'list', vl: '1', list: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
    ],
  },
  {
    title: "Margin",
    icon: "mdi-image-filter-none",
    open: false,
    listClass: [
      { sel: false, text: 'all', value: 'ma', type: 'list', vl: '0', list: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'x', value: 'mx', type: 'list', vl: '0', list: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'y', value: 'my', type: 'list', vl: '0', list: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'top', value: 'mt', type: 'list', vl: '0', list: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'bottom', value: 'mb', type: 'list', vl: '0', list: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'left', value: 'ml', type: 'list', vl: '0', list: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
      { sel: false, text: 'right', value: 'mr', type: 'list', vl: '0', list: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] },
    ],
  }
  ];



  $xui.rootdata.listCatClass.push(...listDesignClass);
  //console.debug($xui.rootdata.listCatClass);




  // var list = "ma-2 pt-1 text-justify";
  // new DesignClassManager().initClassSelector(list, listDesignClass);
  // var txt = new DesignClassManager().getClassTextFromSeletor(list, listDesignClass);
  // console.debug(txt);

  // Vue.component("toto", { template: '<span>toto</span>' });
  
  // Vue.component("v-xui-reloader2",
  //   {
  //     id : 1,
  //     template: '<component v-bind:is="conponentReload"></component>',
  //     data: () => { return { conponentReload: "" }; },
  //     methods: {
  //       reload: function () {
  //         console.debug("reload**************");

  //         var infoFileCmp = { file: "app/frame1.html", xid: "root", mode: 'template',  part:'onglet-tab-item-0' };
  //         var prom = getPromise("getVueCmp")
  //         $xui.getHtmlFrom(infoFileCmp, "getVueCmp");
  //         prom.then(template => {
  //           console.debug(template);
  //           Vue.component("toto", { template: template });
  //           this.conponentReload="toto";
  //         })

  //       }
  //     },
  //     mounted: function () {
  //       this.reload();
  //     }
  //   });


  // setTimeout(() => {
  //   //$xui.rootdata.componentTab = "v-xui-reloader";
  // }, 3000);




  // Vue.component("toto", { template: '<span>toto</span>' });
  // Vue.component("titi", { template: '<span>titi</span>' });


  // setTimeout(() => {
  //   $xui.rootdata.componentTab="toto";
  // }, 5000);

  // setTimeout(() => {
  //   $xui.rootdata.componentTab="titi";
  // }, 7000);

  // setTimeout(() => {
  //   delete Vue.options.components["toto"]
  //   $xui.rootdata.componentTab="toto";
  // }, 10000);

  // setTimeout(() => {
  //   Vue.component("tata", { template: '<span>tata</span>' });
  //   $xui.rootdata.componentTab="tata";
  // }, 12000);


  // window.fctTest = (i) => {
  //   //console.debug(i);
  //   delete Vue.options.components[$xui.rootdata.componentTab];

  //   Vue.component("toto"+i, { template: '<span>toto'+i+'</span>' });
  //   $xui.rootdata.componentTab="toto"+i;

  //   if (i < 10000) {
  //     setTimeout(() => {
  //       fctTest(i + 1);
  //     }, 100);
  //   }
  // };

  // fctTest(1);


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
class ComponentManager {

  registerVueComponent(idCmp, file, xid) {

    Vue.component(idCmp, function (resolve, reject) {

      this.waitForGlobal("getHtmlFrom", function () {

        var infoFileCmp = { file: file, xid: xid, mode: 'final' };
        var prom = getPromise("getVueCmp")
        $xui.getHtmlFrom(infoFileCmp, "getVueCmp");
        prom.then(jsCmp => {

          const dataUri = ComponentManager.esm`${jsCmp}`;
          import(dataUri)
            .then((namespaceObject) => {

              console.debug("addVueComponent", namespaceObject.default);

              var cmp = {
                data: function () {
                  return $xui.rootdata;
                },
                computed: {
                  $xui: function () {
                    return window.$xui;
                  }
                }
                , ...namespaceObject.default
              };

              resolve(cmp);
            });

        });
      }.bind(this));

    }.bind(this))

  }

  /*******************************************************************/

  static esm(templateStrings, ...substitutions) {
    let js = templateStrings.raw[0];
    for (let i = 0; i < substitutions.length; i++) {
      js += substitutions[i] + templateStrings.raw[i + 1];
    }
    return 'data:text/javascript;base64,' + btoa(js);
  }

  waitForGlobal(key, callback) {
    if ($xui[key] != null) {
      callback();
    } else {
      setTimeout(function () { this.waitForGlobal(key, callback); }.bind(this), 100);
    }
  };

}

// gestion des composants XUIvueJS (cmp-list-class)
new ComponentManager().registerVueComponent("cmp-list-class", 'app/cmpDesignClassChooser.html', "xui-list-class");






/************************************************************************************************* */

// Vue.component('spanEditable',{
//     template:'<span contenteditable="true" @input="update"></span>',
//     props:['content'],
//     mounted:function(){
//       this.$el.innerText = this.content;
//     },
//     methods:{
//       update:function(event){
//         this.$emit('updatekkk',event.target.innerText);
//       }
//     }
//   })

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