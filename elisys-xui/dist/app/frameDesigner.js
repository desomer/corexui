//    editor en vuejs  : https://codepen.io/NicolasLrnd/pen/XPdxKv

// https://stackoverflow.com/questions/45630151/is-it-possible-to-globally-remove-a-vue-component-from-the-global-registry


if (typeof window.$xui === 'undefined')
    window.$xui = {};

/****************************************************************************************/

import("./clsPageDesignManager.js").then((module) => {
    $xui.pageDesignManager = new module.PageDesignManager();
});

import("./clsEventManager.js").then((module) => {
    new module.EventManager().init();
});

import("./clsSelectorManager.js").then((module) => {
    new module.SelectorManager().init();
});

/****************************************************************************************/
$xui.isModePreview = false;
$xui.modeDisplaySelection = false;
$xui.editorOpenId = null;

function getInfoFile(mode) {
    return { file: 'app/frame1.html', xid: 'root', mode: mode };
}

function waitForXuiLib(key, callback) {
    if ($xui[key] != null) {
        callback();
    } else {
        setTimeout(function () { waitForXuiLib(key, callback); }, 100);
    }
};

waitForXuiLib("initPageXUI", function () {
    var infoFile = getInfoFile("design");
    $xui.initPageXUI(infoFile);
});

/******************************************************************************** */

$xui.loadPageJS = (html) => {
    $xui.pageDesignManager.loadPage(html);
};

$xui.changePageJS = (param) => {
    $xui.pageDesignManager.changePageJS(param);
    $xui.doPromiseJS("changePage");
};


/******************************************************************************** */
// gestion des button refresh de la page
$xui.refreshAction = (mode) => {
    var infoFile = getInfoFile(mode);
    if (mode == "template:reload") {
        infoFile.mode = "template";
        infoFile.action = "reload";  // pas de store
    }
    if (mode == "template:clearAll") {
        infoFile.mode = "design";
        infoFile.action = "clear";   // pas de store
    }
    $xui.refreshXUI(infoFile);
};

$xui.fullScreen = () => {
    $xui.unDisplaySelector();
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

/***************************************************************************************************************/
const observer = new ReportingObserver((reports, observer) => {
    for (const report of reports) {
        console.log("******************************************", report.type, report.url, report.body, observer);
    }
}, { buffered: true });

console.log("***************start reporting ********************");
observer.observe();

window.onunhandledrejection = function (e) {
    console.log("*************** onunhandledrejection", e);
    alert('Error object: ' + e.reason.message + "\n" + e.reason.stack);
}

window.addEventListener('error', function (e) {

    console.log("*************** error", e);

})

window.onerror = function (msg, url, lineNo, columnNo, error) {
    console.log("***************error reporting OK ********************");
    var string = msg.toLowerCase();
    var substring = "script error";
    if (string.indexOf(substring) > -1) {
        alert('Script Error: See Browser Console for Detail');
    } else {
        var message = [
            'XUI reporting Message: ' + msg,
            'URL: ' + url,
            'Line: ' + lineNo,
            'Column: ' + columnNo,
            'Error object: ' + JSON.stringify(error)
        ].join(' - ');

        alert(message);
    }

    return false;
};

function wrapErrors(fn) {
    // don't wrap function more than once
    if (!fn.__wrapped__) {
        fn.__wrapped__ = function () {
            try {
                return fn.apply(this, arguments);
            } catch (e) {
                captureError(e); // report the error
                throw e; // re-throw the error
            }
        };
    }

    return fn.__wrapped__;
}

function captureError(e) {
    alert(e.message)
    console.debug("------- send info error -------", e)
}

//    wrapErrors(function () {
//    --------
//    })();

console.log("***************start reporting OK ********************");

/***************************************************************************************************************/

let lastActionDate = Date.now();
let lastAction = null;
let currentAction = null;
let mapAction = {
    "clearAll": { text: "create new page", timeout: 1000 },
    "addCmp": { text: "add component", timeout: 500 },
    "deleteCmp": { text: "delete component", timeout: 1000 },
    "cutCmp": { text: "cut component", timeout: 1000 },
    "pasteTo": { text: "paste component", timeout: 1000 },
    "copyCmp": { text: "copy component", timeout: 1000 },
    "addSlot": { text: "add slot", timeout: 1500 },
    "saveProperties": {},
    "moveTo": {}
}


$xui.setCurrentAction = (actionName) => {

    if (currentAction != null)
        throw (new SpecifiedError("action déjà en cours " + actionName + " => " + lastAction));

    var actionDec = mapAction[actionName];
    if (actionDec != null) {
        if (actionDec.text != null) {
            $xui.rootdata.snackbar_text = actionDec.text;
            $xui.rootdata.snackbar_timeout = actionDec.timeout;
            $xui.rootdata.snackbar = true;
        }
    }
    else {
        $xui.rootdata.snackbar_text = actionName;
        $xui.rootdata.snackbar_timeout = 1000;
        $xui.rootdata.snackbar = true;
    }

    $xui.rootdata.saveLayout = true;

    lastActionDate = Date.now();
    lastAction = actionName;
    currentAction = actionName;
    console.debug("START ------- " + actionName + " ---------")
    var displayMode = "root"
    var undisplaySelector = true;
    var reselect = $xui.modeDisplaySelection;

    /**************************/
    if (actionName == "addCmp")
        displayMode = "none";

    if (actionName == "saveProperties" || actionName == "addAction")
        displayMode = "current";

    if (actionName == "addSlot")
        displayMode = "current";

    if (actionName == "moveTo")
        displayMode = "current";
    /**************************/

    if (undisplaySelector)
        $xui.unDisplaySelector();

    var prom = getPromise("changePageFinish");
    prom.then(() => {
        $xui.rootdata.saveLayout = false;
        currentAction = null;
        console.debug("END changePageFinish ------ " + actionName + " ------")
        if (displayMode == "current") {
            if (reselect)
                $xui.modeDisplaySelection = true;

            console.debug("changePageFinish ok", $xui.modeDisplaySelection);
            if ($xui.modeDisplaySelection) {
                setTimeout(() => {   // attente prise en compte chargement des images
                    console.debug("reselect after change ", $xui.propertiesDesign);
                    $xui.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot, true);
                }, 50);
            }
        }
    });

    var prom = getPromise("changePage");
    prom.then(() => {
        if (displayMode == "root") {
            $xui.displayPropertiesJS("root", "root");   // reaffecte le nouveau mapping sur la page
        }
        else if (displayMode == "current") {
            $xui.displayPropertiesJS($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);   // reaffecte le nouveau mapping
        }
        console.debug("END changePage ------ " + actionName + " ------")
    }
    );

    return true;
}

/***************************************************************************************************************/
$xui.clearAll = () => {
    $xui.setCurrentAction("clearAll");
    $xui.pageDesignManager.clearAll();
    $xui.refreshAction("template:clearAll");
}

$xui.addCmp = (cmp) => {
    $xui.setCurrentAction("addCmp");
    console.debug("addCmp", cmp, $xui.propertiesComponent);
    addCmpXID($xui.propertiesComponent.xid, cmp.xid);
}

$xui.deleteCmp = () => {
    console.debug("deleteCmp", $xui.propertiesDesign);
    if ($xui.propertiesDesign.isSlot) {
        let infoFile = getInfoFile("template");
        let info = $xui.getInfo(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
        console.debug("deleteCmp slot impossible " + $xui.propertiesDesign.xid + " -> " + info.docId);
        return false;
    }
    else {
        $xui.setCurrentAction("deleteCmp");
        $xui.deleteDesign(getInfoFile("template"), $xui.propertiesDesign.xid);
        return true;
    }
}

$xui.copyCmp = () => {
    if ($xui.propertiesDesign.isSlot) {
        console.debug("copyCmp slot impossible");
        return false;
    }
    else {
        $xui.setCurrentAction("copyCmp");
        $xui.copyDesign(getInfoFile("template"), $xui.propertiesDesign.xid);
        $xui.rootdata.pasteDisabled = false;
        return true;
    }
}

$xui.cutCmp = () => {
    if ($xui.propertiesDesign.isSlot) {
        console.debug("cutCmp slot impossible");
        return false;
    }
    else {
        $xui.setCurrentAction("cutCmp");
        $xui.cutDesign(getInfoFile("template"), $xui.propertiesDesign.xid);
        $xui.rootdata.pasteDisabled = false;
        return true;
    }
}

$xui.pasteTo = () => {
    $xui.setCurrentAction("pasteTo");

    let infoFile = getInfoFile("template");
    var info = $xui.getInfo(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    $xui.moveDesign(infoFile, null, info.xid);
    // $xui.rootdata.pasteDisabled = true;
}

$xui.moveTo = (data) => {
    $xui.setCurrentAction("moveTo");

    let infoFile = getInfoFile("template");
    var info = $xui.getInfo(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    $xui.moveDesign(infoFile, info.xid, data.xid_slot);
}

$xui.addAction = () => {

    let infoFile = getInfoFile("template");
    let info = $xui.getInfo(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    let infoParent = $xui.getInfo(infoFile, info.parentXid, info.parentXid);
    console.debug("info add action ", info, infoParent);

    $xui.rootdata.activeAction = 3;

    if ($xui.propertiesDesign.isSlot) {

        if (info.docId == "xui-no-dom:xui-flow"
            || info.docId == "v-col:xui-row-grid-responsive"
            || info.docId == "v-col:xui-row-1"
            || info.docId == "v-col:xui-form-row-1"
        ) {
            addSlotByVariable(infoFile, info);
            return true
        }
        else {
            console.debug("addAction sur slot " + info.docId + " => " + info.addRemoveAction);
            if (info.addRemoveAction == "addFlow") {
                addCmpXID($xui.propertiesDesign.xidSlot, "xui-flow");
                return true;
            } else if (info.addRemoveAction == "incNb") {
                addSlotByVariable(infoFile, info);
                moveChildAfterInsert(infoFile, info)
                return true
            }

            return false;
        }
    }
    else {
        if (infoParent.docId == "xui-no-dom:xui-flow") {
            addSlotByVariable(infoFile, infoParent);
            return true
        }
        else {
            // surround
            $xui.setCurrentAction("addAction");
            let cmp = { xid: 'xui-flow' };
            const newXid = $xui.getNewXid(info.parentXid, 'xui-flow');
            const currentXid = info.parentXid;
            const template = "<xui-design xid=\"" + currentXid + "\"><" + cmp.xid + " xid=\"" + newXid + "\"></" + cmp.xid + "></xui-design>";
            $xui.surroundDesign(infoFile, $xui.propertiesDesign.xid, template, newXid);
            return true;
        }
    }
}

function moveChildAfterInsert(infoFile, info) {
    $xui.insertChild(infoFile, info.xid);
}

function addCmpXID(xidDest, idCmp) {
    let infoFile = getInfoFile("template");
    const newXid = $xui.getNewXid(xidDest, idCmp);
    const template = "<xui-design xid=\"" + xidDest + "\"><" + idCmp + " xid=\"" + newXid + "\"></" + idCmp + "></xui-design>";
    $xui.addDesign(infoFile, xidDest, template, true, false);
}

function addSlotByVariable(infoFile, infoParent) {
    $xui.setCurrentAction("addSlot");
    infoFlow = $xui.getInfo(infoFile, infoParent.parentXid, infoParent.parentXid);
    for (const aProp of $xui.rootDataProperties.data) {
        if (aProp.xid == infoFlow.xid && aProp.variable == "nb") {
            aProp.value = "" + (parseInt(aProp.value) + 1);
        }
    }
    // save properties
    $xui.hasPropertiesChanged = false;
    $xui.setDesignProperties(getInfoFile("template"), $xui.propertiesDesign.json);
}

$xui.undo = () => {
    $xui.setCurrentAction("undo");
    $xui.pageDesignManager.undo();
};

$xui.redo = () => {
    $xui.setCurrentAction("redo");
    $xui.pageDesignManager.redo();
};

$xui.saveProperties = () => {
    $xui.setCurrentAction("saveProperties");
    console.debug("saveProperties", $xui.propertiesDesign.json);

    $xui.hasPropertiesChanged = false;
    $xui.setDesignProperties(getInfoFile("template"), $xui.propertiesDesign.json);
}

/***************************************************************************************************************/
$xui.getNewXid = (xidParent, nameCmp) => {
    var d = new Date().getTime();
    d += (parseInt(Math.random() * 100)).toString();

    var idxUUID = xidParent.indexOf("_");
    var pxid = idxUUID == -1 ? xidParent : (xidParent.substring(0, idxUUID));
    var ret = pxid + "-" + nameCmp.replace("xui-", "") + "_" + d;
    return ret;
}

/***************************************************************************************************************/
var listIcon = null;
var listImage = null;
$xui.openTabUrl = (url) => {
    if (url == "listIcon") {
        if (listIcon == null || listIcon.closed)
            listIcon = window.open('https://cdn.materialdesignicons.com/5.1.45/', '_blank');
        listIcon.focus()
    }
    if (url == "siteImage") {
        if (listImage == null || listImage.closed)
            listImage = window.open('https://unsplash.com/', '_blank');
        listImage.focus()
    }
};

$xui.openClassEditor = (id) => {
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
            $xui.hasPropertiesChanged = true;
            $xui.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
        }
    }
}

/***************************************************************************************************************/
$xui.displayPropertiesJS = (xid, xid_slot) => {
    let infoFile = getInfoFile("template");

    let posScroll = -1;
    if ($xui.propertiesDesign != null && xid == $xui.propertiesDesign.xid) {
        posScroll = document.getElementById("AppPropertiesSetting").scrollTop;
    }

    let prom = getPromise("getDesignProperties");
    $xui.getDesignProperties(infoFile, xid, xid_slot);
    prom.then(prop => {
        $xui.hasPropertiesChanged = false;

        if (prop.path == "") {
            console.debug("displayPropertiesJS **** INCONNU ****", $xui.propertiesDesign);
            return;
        }

        $xui.propertiesDesign = prop;
        $xui.rootdata.selectedxui = $xui.propertiesDesign.path;
        $xui.propertiesDesign.json = $xui.parseJson($xui.propertiesDesign.data);

        console.debug("displayPropertiesJS", $xui.propertiesDesign);

        $xui.rootDataProperties = { data: $xui.propertiesDesign.json };
        var template = "<div id='AppPropertiesSetting' class='barcustom xui-div-design'>" + $xui.propertiesDesign.template + "</div>";
        var tmpCompiled = compileTemplate(template);

        if ($xui.vuejsDesign != null) {
            $xui.vuejsAppPropertiesSetting.$destroy();
        }
        $xui.vuejsAppPropertiesSetting = new Vue({
            render: tmpCompiled.render,
            staticRenderFns: tmpCompiled.staticRenderFns,
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
                    if (posScroll >= 0) {
                        document.getElementById("AppPropertiesSetting").scrollTop = posScroll;
                    }
                    // gestion de la selection sur le mouseover
                    var listOver = document.querySelectorAll(".xui-over-prop-xid");
                    $xui.lastPropOver = null;

                    listOver.forEach((aDivOver) => {
                        aDivOver.addEventListener('mouseover', (e) => {
                            if ($xui.lastPropOver != aDivOver.id) {
                                $xui.lastPropOver = aDivOver.id;
                                $xui.displaySelectorByXid(aDivOver.id, aDivOver.id, true);
                            }
                        });
                        aDivOver.addEventListener('mouseleave', (e) => {
                            // pas de sauvegarde ni de selection si au dessus d'une list de combobox
                            if (e.toElement != null && e.toElement.closest('.v-select-list') != null)
                                return;

                            $xui.lastPropOver = null;
                            // lance aussi la sauvegarde
                            $xui.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xid, true);
                            if (!$xui.modeDisplaySelection)
                                $xui.unDisplaySelector();
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

    let infoFile = getInfoFile("template");

    $xui.propertiesComponent = $xui.getComponents(infoFile, xid, xid_slot);
    //console.debug("displayComponents", $xui.propertiesComponent);

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
        template: "<div id='AppComponents' class='xui-div-design barcustom'>" + $xui.propertiesComponent.template + "</div>",
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

/***************************************************************************************************************/
var cacheHtmlAction = null;
$xui.displayAction = (xid, xid_slot) => {
    if (cacheHtmlAction == null) {
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
            cacheHtmlAction = html;
        });
    }

}

/***************************************************************************************************************/
/***************************************************************************************************************/
$xui.updateDirectProperty = (value, variable, xid) => {
    console.debug("updateDirectProperty", value, variable, xid, $xui.rootDataProperties);
    for (const aProp of $xui.rootDataProperties.data) {
        if (aProp.xid == xid && aProp.variable == variable) {
            aProp.value = value;
        }
    }
}

/***************************************************************************************************************/
var dicoPromise = {};


function compileTemplate(template) {
    return Vue.compile(template);
}

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
    if (dicoPromise[idPromise] != null) {
        dicoPromise[idPromise].resolve_ex(ret);
        dicoPromise[idPromise] = null;
    }
}


$xui.parseJson = (str) => {
    try {
        return JSON.parse(str);
    } catch (error) {
        console.debug("pb parse json", error, str);
    }
}

// Create a custom error
var SpecifiedError = function SpecifiedError(message) {
    this.name = 'SpecifiedError';
    this.message = message || '';
    this.stack = (new Error()).stack;
};

SpecifiedError.prototype = new Error();
SpecifiedError.prototype.constructor = SpecifiedError;


