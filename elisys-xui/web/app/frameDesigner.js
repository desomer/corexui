//    editor en vuejs  : https://codepen.io/NicolasLrnd/pen/XPdxKv

// https://stackoverflow.com/questions/45630151/is-it-possible-to-globally-remove-a-vue-component-from-the-global-registry


if (typeof window.$xui === 'undefined')
    window.$xui = {};


import("./clsPageDesignManager.js").then((module) => {
    $xui.pageDesignManager = new module.PageDesignManager();
});

import("./clsEventManager.js").then((module) => {
    new module.EventManager().init();
});

import("./clsSelectorManager.js").then((module) => {
    new module.SelectorManager().init();
});



$xui.isModePreview = false;
$xui.modeDisplaySelection = false;
$xui.editorOpenId = null;

var workerEnable = false;
var monWorker = null;

if (workerEnable) {
    monWorker = new Worker('./libxuiworker.js');

    monWorker.onmessage = function (e) {
        console.log('Message depuis le worker', e);
    }
}

/******************************************************************************** */
$xui.loadPageJS = (html) => {
    $xui.pageDesignManager.loadPage(html);
};

$xui.changePageJS = (param) => {
    $xui.pageDesignManager.changePageJS(param);
};

/******************************************************************************** */
// gestion des button refresh de la page
$xui.refreshAction = (mode) => {
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: mode };
    $xui.refresh(infoFile);    // lance le dart
};

$xui.fullScreen = () => {
    window.$xui.unDisplaySelector();
    window.document.documentElement.requestFullscreen();
}

$xui.modePreview = () => {
    $xui.isModePreview = !$xui.isModePreview;
    document.querySelector("#rootFrame").classList.toggle("xui-frame-full-screen");
    $xui.refreshAction($xui.isModePreview ? "preview" : "design");
}

$xui.modePhone = () => {
    document.querySelector("#rootFrame").classList.toggle("iframe-phone");
}

/************************************************************************** */
$xui.addCmp = (cmp) => {
    window.$xui.unDisplaySelector();
    console.debug("addCmp", cmp, $xui.propertiesComponent);
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
    const newXid = $xui.getNewXid($xui.propertiesComponent, cmp);
    const currentXid = $xui.propertiesComponent.xid;
    const template = "<xui-design xid=\"" + currentXid + "\"><" + cmp.xid + " xid=\"" + newXid + "\"></" + cmp.xid + "></xui-design>";
    $xui.addDesign(infoFile, $xui.propertiesComponent.xid, template, true);
    // todo 
    // gerer .then($xui.changePage())
}

$xui.getNewXid = (parent, cmp) => {
    var d = new Date().getTime();
    d += (parseInt(Math.random() * 100)).toString();

    var idxUUID = parent.xid.indexOf("_");
    var pxid = idxUUID == -1 ? parent.xid : (parent.xid.substring(0, idxUUID));
    var ret = pxid + "-" + cmp.xid.replace("xui-", "") + "_" + d;
    return ret;
}

$xui.deleteCmp = () => {
    $xui.unDisplaySelector();
    console.debug("deleteCmp", $xui.propertiesDesign);
    if ($xui.propertiesDesign.isSlot) {
        console.debug("deleteCmp slot impossible");
        return false;
    }
    else {
        var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
        $xui.removeDesign(infoFile, $xui.propertiesDesign.xid);
        return true;
    }

}

$xui.moveTo = () => {
    $xui.unDisplaySelector();
    console.debug("moveToCmp", $xui.propertiesDesign);
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
    var info = $xui.getInfo(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    $xui.moveDesign(infoFile, null, info.xid);
}

//********************************************************************************************/

$xui.saveProperties = () => {
    console.debug("saveProperties", $xui.propertiesDesign.json);

    $xui.hasPropertiesChanged = false;

    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
    var prom = getPromise("setDesignProperties");
    $xui.setDesignProperties(infoFile, "save", $xui.propertiesDesign.json);
    prom.then(xidProp => {
        console.debug("saveProperties ok", xidProp);
        $xui.displayPropertiesJS(xidProp, xidProp);   // reaffecte le nouveau mapping
    });
    return prom;
}

$xui.openClassEditor = (id) => {
    console.debug(id);
    $xui.editorOpenId = id;

    $xui.modeDisplaySelection = false;
    $xui.rootdata.dialogClass = true;

    // setTimeout(() => { $xui.unDisplaySelector(); }, 100);

    for (const aProperty of $xui.propertiesDesign.json) {
        if (aProperty.cat == "class" && (aProperty.xid == $xui.editorOpenId || aProperty.xid == $xui.editorOpenId)) {
            console.debug("load class", aProperty);
            new DesignClassManager().initClassSelector(aProperty.value, $xui.rootdata.listCatClass);
        }
    }

}

$xui.closeClassEditor = () => {

    for (const aProperty of $xui.propertiesDesign.json) {
        if (aProperty.cat == "class" && (aProperty.xid == $xui.editorOpenId || aProperty.xid == $xui.editorOpenId)) {
            console.debug("save class", aProperty);
            aProperty.value = new DesignClassManager().getClassTextFromSeletor(aProperty.value, $xui.rootdata.listCatClass);
            $xui.hasPropertiesChanged=true;
            $xui.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
        }
    }

}


/******************************************************************************** */

$xui.displayPropertiesJS = (xid, xid_slot) => {
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };

    var param = { infoFile: infoFile, xid: xid, xid_slot: xid_slot };

    // gestion en thread
    if (monWorker != null)
        monWorker.postMessage([param]);

   // var info = $xui.getInfo(infoFile, xid, xid_slot);

    var prom = getPromise("getDesignProperties");

    $xui.getDesignProperties(infoFile, xid, xid_slot);

    prom.then(prop => {
        $xui.hasPropertiesChanged = false;
        $xui.propertiesDesign = prop;
        $xui.rootdata.selectedxui = $xui.propertiesDesign.path;
        $xui.propertiesDesign.json = $xui.parseJson($xui.propertiesDesign.data);

        console.debug("displayPropertiesJS", $xui.propertiesDesign, $xui.propertiesDesign.json);

        $xui.rootDataProperties = { data: $xui.propertiesDesign.json };

        if ($xui.vuejsDesign != null) {
            $xui.vuejsAppPropertiesSetting.$destroy();
        }
        $xui.vuejsAppPropertiesSetting = new Vue({
            template: "<div class='barcustom' id='AppPropertiesSetting' class='xui-div-design'>" + $xui.propertiesDesign.template + "</div>",
            el: '#AppPropertiesSetting',
            vuetify: new Vuetify(),
            data: $xui.rootDataProperties,
            watch: {
                $data: {
                    handler: function (val, oldVal) {
                        //console.log("watch properties", val, this.$data)
                        $xui.hasPropertiesChanged = true;
                    },
                    deep: true
                }
            },
            computed: {
                $xui: function () {
                    return window.$xui;
                }
            },
            mounted: function () {
                this.$nextTick(function () {
                    // gestion de la selection sur le mouseover
                    var listOver = document.querySelectorAll(".xui-over-prop-xid");
                    $xui.last = null;
                    listOver.forEach((aDivOver) => {
                        aDivOver.style.border = "1px solid #bdbdbd";
                        aDivOver.addEventListener('mouseover', () => {
                            aDivOver.style.border = "1px solid #202020";
                            if ($xui.last != aDivOver.id) {
                                $xui.last = aDivOver.id;
                                //console.debug("sel over", aDivOver.id);
                                $xui.displaySelectorByXid(aDivOver.id, aDivOver.id, true);
                            }
                        });
                        aDivOver.addEventListener('mouseleave', () => {
                            aDivOver.style.border = "1px solid #bdbdbd";
                            $xui.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xid, true);
                            if (!$xui.modeDisplaySelection)
                                $xui.unDisplaySelector();
                        });
                    });
                })
            }
        });
    });

}


$xui.displayComponents = (xid, xid_slot) => {

    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };

    $xui.propertiesComponent = $xui.getComponents(infoFile, xid, xid_slot);
    //console.debug("displayComponents", $xui.propertiesComponent);
    $xui.propertiesComponent.json = $xui.parseJson($xui.propertiesComponent.data);
    $xui.rootDataComponents = { data: $xui.propertiesComponent.json, item: null };
    if ($xui.vuejsDesign != null) {
        $xui.vuejsAppCmpSetting.$destroy();
    }
    $xui.vuejsAppCmpSetting = new Vue({
        template: "<div class='barcustom' id='AppComponents' class='xui-div-design'>" + $xui.propertiesComponent.template + "</div>",
        el: '#AppComponents',
        vuetify: new Vuetify(),
        data: $xui.rootDataComponents,
        computed: {
            $xui: function () {
                return window.$xui;
            }
        }
    });

}


$xui.displayAction = (xid, xid_slot) => {
    var infoFile = { file: 'app/cmpDesignEditor.html', xid: 'bottom-editor', mode: 'final' };
    var prom = getPromise("displayActionPromise");
    $xui.getHtmlFrom(infoFile, "displayActionPromise");
    prom.then(html => {
        $xui.rootDataAction = {};
        if ($xui.vuejsAppCmpAction != null) {
            $xui.vuejsAppCmpAction.$destroy();
        }
        $xui.vuejsAppCmpAction = new Vue({
            template: "<div id='xui-display-selector-action' style='position:absolute;bottom:-20px;left: 0px;background: rgba(204, 205, 255, 1); border: 1px solid rgb(64, 37, 226); padding: 0px 5px;  z-index: 1000;'>" + html + "</div>",
            el: '#xui-display-selector-action',
            vuetify: new Vuetify(),
            data: $xui.rootDataAction,
            computed: {
                $xui: function () {
                    return window.$xui;
                }
            }
        });
    });

}

$xui.updateDirectProperty = (value, variable, xid) => {
    console.debug("updateDirectProperty", value, variable, xid, $xui.rootDataProperties);
    for (const aProp of $xui.rootDataProperties.data) {
        if (aProp.xid == xid && aProp.variable == variable) {
            aProp.value = value;
        }
    }
}

/********************************************************************************** */
var dicoPromise = {};
function getPromise(id) {

    var _resolve, _reject;

    var promise = new Promise((resolve, reject) => {
        _reject = reject;
        _resolve = resolve;
    });

    promise.resolve_ex = (value) => {
        _resolve(value);
    };

    promise.reject_ex = (value) => {
        _reject(value);
    };

    if (id != null)
        dicoPromise[id] = promise;
    return promise;
}

$xui.doPromiseJS = (idPromise, ret) => {
    dicoPromise[idPromise].resolve_ex(ret);
}


$xui.parseJson = (str) => {
    try {
        return JSON.parse(str);
    } catch (error) {
        console.debug("pb parse json", error, str);
    }
}