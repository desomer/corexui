$xui.displayPropertiesJS = (xid, xid_slot) => {
    const infoFile = $xui.pageDesignManager.getInfoFile("template");

    let idProp = "AppPropertiesSetting";
    infoFile.action = "design";
    const rootdata = $xui.getAppState().main;

    if (rootdata.idxTabProperties == 1) {
        idProp = "AppPropertiesStyle";
        infoFile.action = "style";
    }

    if (rootdata.idxTabProperties == 2) {
        idProp = "AppPropertiesEvent";
        infoFile.action = "event";
    }
    
    let posScroll = -1;
    if ($xui.propertiesDesign != null && xid == $xui.propertiesDesign.xid) {
        posScroll = document.getElementById(idProp).scrollTop;
    }

    const prom = getPromise("getDesignProperties");

    $xuicore.getDesignPropertiesXUI(infoFile, xid, xid_slot);
    prom.then(prop => {
        $xui.hasPropertiesChanged = false;

        // if (prop.path == "") {
        //     console.debug("displayPropertiesJS **** INCONNU ****", $xui.propertiesDesign);
        //     return;
        // }

        $xui.propertiesDesign = prop;
        rootdata.breadcrumb.length=0;
        rootdata.breadcrumb.push(...$xui.propertiesDesign.path);
        rootdata.dynamicSlots.length=0;
        rootdata.dynamicSlots.push(...$xui.propertiesDesign.pathConditional);
        rootdata.childrenSlots.length=0;
        rootdata.childrenSlots.push(...$xui.propertiesDesign.pathChildren);

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
                this.$nextTick(doMouveOverProperties(posScroll, idProp))
                doPromiseJS("afterDesignProperties", $xui.propertiesDesign)
            }
        });
    });

    return prom;
}

function doMouveOverProperties(posScroll, idProp)  { 
    return () => {
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
    };
}

/***************************************************************************************************************/
$xui.displayComponents = (xid, xid_slot) => {

    const infoFile = $xui.pageDesignManager.getInfoFile("template");

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
$xui.getEventMethodsXUI= (namespace) =>
{
    const infoFile = $xui.pageDesignManager.getInfoFile("template");
    const ret = $xuicore.getEventMethodsXUI(infoFile, namespace);
    return ret;
}

$xui.loadCodeAction = async (idx) => {

    const storeModule = $xui.getCurrentStoreModule();

    if (storeModule.currentCodeIdx>=0)  
    {
        const saveOk = await $xui.saveCodeAction(storeModule);
        if (!saveOk)
            return;
    }

    if (idx<0)
    {
        return;
    }

    storeModule.currentCodeName = `function ${storeModule.ListActions[idx].name}()`;
    storeModule.currentCode= storeModule.ListActions[idx].code;
    storeModule.currentCodeIdx = idx;

    const listAct = document.querySelectorAll(".xui-btn-code");
    let i = 0;
    listAct.forEach((elem) => {
    elem.classList.remove('xui-btn-code-selected');
    if (i==idx)
    {
        elem.classList.add('xui-btn-code-selected');
    }
    i++;
    });

}

// $xui.highlighter = (code) => Prism.highlight(code, Prism.languages.js, "js");

$xui.saveCodeAction = async (storeModule) => {

    const idx = storeModule.currentCodeIdx;
    storeModule.currentCodeXid= storeModule.ListActions[idx].xid;
    
    const code = storeModule.ListActions[idx].code;
    if (code==storeModule.currentCode)
        return true;

    const rootdata = $xui.getAppState().main;

    // validate JS syntaxe
    const acorn = await globalThis.requireXUI.require('https://cdn.jsdelivr.net/npm/acorn@8.7.0/dist/acorn.min.js'); // 'https://cdn.jsdelivr.net/npm/acorn-6to5@0.11.1-31/acorn_csp.min.js');
    try {
        const ok = acorn.parse("let fct = async ()=> {\n"+ storeModule.currentCode +" }", {ecmaVersion: "latest"});
        console.debug("*********** AST *************", ok);
    } catch (error) {
        console.debug("code =", storeModule.currentCode)
        console.debug(error.message, error);
        rootdata.openDialogError =true;
        rootdata.dialogError_text = error.message;
        return false;
    }

    const jsonProp = [{
        xid : storeModule.ListActions[idx].xid,
        variable : `#${storeModule.ListActions[idx].eventName}`,
        value : storeModule.currentCode,
        bind : "@"
    }];

    $xuicore.saveDesignPropertiesXUI($xui.pageDesignManager.getInfoFile("template"), jsonProp);

    storeModule.ListActions[idx].code = storeModule.currentCode;
    storeModule.currentCodeIdx=-1;

    rootdata.snackbar_text = `Change mth ${storeModule.nameModule}/${storeModule.ListActions[idx].name}`;
    rootdata.snackbar_timeout = 2000;
    rootdata.snackbar = true;

    document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "changeJS", "param": {namespace : storeModule.nameModule ,  actions: storeModule.ListActions } }, "*");
    return true;
}

