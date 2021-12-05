$xui.displayPropertiesJS = (xid, xid_slot) => {
    let infoFile = $xui.pageDesignManager.getInfoFile("template");

    let idProp = "AppPropertiesSetting";
    infoFile.action = "design";

    if ($xui.rootdata.activeAction == 1) {
        idProp = "AppPropertiesStyle";
        infoFile.action = "style";
    }

    if ($xui.rootdata.activeAction == 2) {
        idProp = "AppPropertiesEvent";
        infoFile.action = "event";
    }
    
    let posScroll = -1;
    if ($xui.propertiesDesign != null && xid == $xui.propertiesDesign.xid) {
        posScroll = document.getElementById(idProp).scrollTop;
    }

    let prom = getPromise("getDesignProperties");

    $xuicore.getDesignPropertiesXUI(infoFile, xid, xid_slot);
    prom.then(prop => {
        $xui.hasPropertiesChanged = false;

        if (prop.path == "") {
            console.debug("displayPropertiesJS **** INCONNU ****", $xui.propertiesDesign);
            return;
        }

        $xui.propertiesDesign = prop;
        $xui.rootdata.selectedxui = $xui.propertiesDesign.path;
        $xui.propertiesDesign.json = $xui.parseJson($xui.propertiesDesign.data);

        if (window.$xui.config.traceDisplayPropertiesJS) {
            console.debug("displayPropertiesJS", $xui.propertiesDesign);
        }

        $xui.rootDataProperties = { data: $xui.propertiesDesign.json };
        const template = `<div id='${idProp}' class='barcustom xui-div-scroll-vertical'>${$xui.propertiesDesign.template}</div>`;
        const tmpCompiled = compileTemplate(template);

        if ($xui.vuejsAppPropertiesSetting != null) {
            $xui.vuejsAppPropertiesSetting.$destroy();
        }
        $xui.vuejsAppPropertiesSetting = new Vue({
            render: tmpCompiled.render,
            staticRenderFns: tmpCompiled.staticRenderFns,
            el: `#${idProp}`,
            vuetify: new Vuetify(),
            data: $xui.rootDataProperties,
            watch: {
                $data: {
                    handler(val, oldVal) {
                        //console.log("watch properties", val, this.$data)
                        $xui.hasPropertiesChanged = true;
                    },
                    deep: true
                }
            },
            computed: {
                $xui() {
                    return window.$xui;
                }
            },
            mounted() {
                this.$nextTick(() => {
                    if (posScroll >= 0) {
                        document.getElementById(idProp).scrollTop = posScroll;
                    }
                    // gestion de la selection sur le mouseover
                    const listOver = document.querySelectorAll(`#${idProp} .xui-over-prop-xid`);
                    $xui.lastPropOver = null;

                    listOver.forEach((aDivOver) => {
                        aDivOver.addEventListener('mouseover', (e) => {
                            if ($xui.lastPropOver != aDivOver.id) {
                                $xui.lastPropOver = aDivOver.id;
                                $xui.SelectorManager.displaySelectorByXid(aDivOver.id, aDivOver.id, true);
                            }
                        });
                        aDivOver.addEventListener('mouseleave', (e) => {
                            // pas de sauvegarde ni de selection si au dessus d'une list de combobox
                            if (e.toElement != null && e.toElement.closest('.v-select-list') != null)
                                return;

                            $xui.lastPropOver = null;
                            // lance aussi la sauvegarde
                            $xui.SelectorManager.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xid, true);
                            if (!$xui.modeDisplaySelection)
                                $xui.SelectorManager.unDisplaySelector();
                        });
                    });
                })
            }
        });
    });

    return prom;
}

/***************************************************************************************************************/
$xui.displayComponents = (xid, xid_slot) => {

    let infoFile = $xui.pageDesignManager.getInfoFile("template");

    $xui.propertiesComponent = $xuicore.getComponentsXUI(infoFile, xid, xid_slot);

    /************************************************************ */
    if ($xui.vuejsAppCmpSetting != null) {
        return; // pas de raffraichissement dynamique en fonction du composant
    }
    /************************************************************ */

    $xui.propertiesComponent.json = $xui.parseJson($xui.propertiesComponent.data);
    $xui.rootDataComponents = { data: $xui.propertiesComponent.json, item: null };
    if ($xui.vuejsAppCmpSetting != null) {
        $xui.vuejsAppCmpSetting.$destroy();
    }
    $xui.vuejsAppCmpSetting = new Vue({
        template: `<div id='AppComponents' class='xui-div-scroll-vertical barcustom'>${$xui.propertiesComponent.template}</div>`,
        el: '#AppComponents',
        vuetify: new Vuetify(),
        data: $xui.rootDataComponents,
        computed: {
            $xui() {
                return window.$xui;
            }
        }
    });

}
/***************************************************************************************************************/
$xui.getCodeEventXUI= () =>
{
    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    const ret = $xuicore.getEventMethodsXUI(infoFile);
    return ret;
}

$xui.loadCodeAction = (idx) => {
      if ($xui.rootdata.currentCodeIdx>=0)  
      {
        $xui.saveCodeAction();
      }

      if (idx<0)
        return;

      $xui.rootdata.currentCodeName = `function ${$xui.rootdata.ListActions[idx].name}()`;
      $xui.rootdata.currentCode= $xui.rootdata.ListActions[idx].code;
      $xui.rootdata.currentCodeIdx = idx;
}

$xui.highlighter = (code) => {
    return Prism.highlight(code, Prism.languages.js, "js");
}

$xui.saveCodeAction = () => {
    // $xui.setCurrentAction("saveProperties");
    // console.debug("saveProperties", $xui.propertiesDesign.json);

    // $xui.hasPropertiesChanged = false;

    const idx = $xui.rootdata.currentCodeIdx;
    $xui.rootdata.currentCodeXid= $xui.rootdata.ListActions[idx].xid;
    
    const code = $xui.rootdata.ListActions[idx].code;
    if (code==$xui.rootdata.currentCode)
        return;

    const jsonProp = [{
        xid : $xui.rootdata.ListActions[idx].xid,
        variable : `#${$xui.rootdata.ListActions[idx].eventName}`,
        value : $xui.rootdata.currentCode,
        bind : "@"
    }];

    $xui.rootdata.ListActions[idx].code = $xui.rootdata.currentCode;
    $xuicore.saveDesignPropertiesXUI($xui.pageDesignManager.getInfoFile("template"), jsonProp);
    $xui.rootdata.currentCodeIdx=-1;

    document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "changeJS", "param": { actions: $xui.rootdata.ListActions } }, "*");


    // const js = $xui.rootdata.currentCode +
    // "\n//# sourceURL=dynamicScript-"+ $xui.rootdata.ListActions[idx].name +".js;";
    // addCode(js); // Right now! Debuggable!

}

    // // Dynamically evaluate JavaScript-as-string in the browser
    // function addCode(js){
    //     eval(js);
    //   }