//    editor en vuejs  : https://codepen.io/NicolasLrnd/pen/XPdxKv

// https://stackoverflow.com/questions/45630151/is-it-possible-to-globally-remove-a-vue-component-from-the-global-registry


if (typeof window.$xui === 'undefined')
    window.$xui = {};


window.$xui.config = {};
window.$xui.config.traceDisplayPropertiesJS = false
window.$xui.config.traceReselect = false
/****************************  CHARGEMENT DE LA PAGE *************************************/

import("./clsPageDesignManager.js").then((module) => {
    $xui.pageDesignManager = new module.PageDesignManager();

    waitForXuiLib("initPageXUI", function () {
        var infoFile = $xui.pageDesignManager.getInfoFile("design");
        $xui.initPageXUI(infoFile);
    }, this);
});
/****************************************************************************************/
import("./clsEventDesignManager.js").then((module) => {
    new module.EventManager().init();
});

import("./clsSelectorManager.js").then((module) => {
    new module.SelectorManager().init();
});

/****************************************************************************************/
$xui.isModePreview = false;
$xui.modeDisplaySelection = false;
/******************************************************************************** */

// charge la page global aprés le retour du XUIEngine
$xui.loadPageJS = (html, options) => {
    console.debug("loadPageJS binding ---- ", options);
    $xui.pageDesignManager.loadPage(html, options);
};

// change une partie de la page aprés le retour du XUIEngine
$xui.changePageJS = (param) => {
    $xui.pageDesignManager.changePageOnFrame(param);
    $xui.doPromiseJS("changePage");
};


$xui.generateApplicationStateJS = (StateTemplate, StateInProperty) => {
    var jsonTemplate = JSON.parse("{" + StateTemplate + "}");
    var jsonStateProp = JSON.parse("{" + StateInProperty + "}");
    var ret = Object.assign(jsonTemplate, jsonStateProp);
    ret = Object.assign(ret, $xui.rootdata.jsonEditorData);

    $xui.rootdata.jsonEditorData = ret;
    console.debug("******* set app state for editor", $xui.rootdata.jsonEditorData)

    // const r = iterateJSON($xui.rootdata.jsonEditorData, template,
    //     (k,v)=>{
    //     console.log("k=", k, " v=", v);
    //     return v;
    // }, (a,i)=>{
    //     console.log("---- array=", a, "  i=", i);
    //     return i;
    // });
    

     console.debug("************ App State template & prop", jsonTemplate, jsonStateProp);
     console.debug("************ App State ret & editor", ret, $xui.rootdata.jsonEditorData);
    var ret = JSON.stringify(ret);
    return ret.substring(1, ret.length-1);
};

const iterateJSON = (src, template, funct, functArray) => {
    const entries = Object.entries(src).map(([key, value]) =>
      Array.isArray(value) ? [key, value.map(e => { 
                 functArray( value, e); 
                 var nt = null;
                 if (Array.isArray(template[key]))
                 {
                    nt=template[key][0];
                 }
                 iterateJSON(e, nt, funct, functArray) })]
        : typeof value === 'object'
        ? [key, iterateJSON(value, template, funct)]
        : [key, funct(key, value)]
    );
    return Object.fromEntries(entries);
  };

/******************************************************************************** */
// gestion des button refresh et export de la page
$xui.refreshAction = (mode) => {
    var infoFile = $xui.pageDesignManager.getInfoFile(mode);

    if (mode == "template:reload") {
        infoFile.mode = "template";
        infoFile.action = "reload";  // pas de store
    }
    if (mode == "template:reload-json") {
        infoFile.mode = "template";
        infoFile.action = "reload-json";  // pas de store
    }
    if (mode == "template:clearAll") {
        infoFile.mode = "design";
        infoFile.action = "clear";   // pas de store
    }
    if (mode == "export") {
        infoFile.mode = "final";
        infoFile.action = "export";   // pas de store
    }
    if (mode == "showCode") {
        infoFile.mode = "final";
        infoFile.action = "showCode";   // pas de store
    }

    $xui.refreshPageXUI(infoFile);
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



/************************************************* LES ACTIONS ***************************************************/

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
    "addSlot": { text: "add slot", timeout: 500 },
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
    console.debug("START ACTION ------- " + actionName + " ---------")
    var selectionMode = "root"
    var undisplaySelector = true;
    var reselect = $xui.modeDisplaySelection;

    /**************************/
    if (actionName == "addCmp")
        selectionMode = "none";

    if (actionName == "saveProperties" || actionName == "OpenPopupAction")
        selectionMode = "current";

    if (actionName == "addSlot")
        selectionMode = "current";

    if (actionName == "moveTo")
        selectionMode = "current";
    /**************************/

    if (undisplaySelector)
        $xui.unDisplaySelector();

    // setCurrentAction  => puis appel XUI
    // puis  changePage  (affichage du code et save localstorage)  : retour du xui
    //     => lancement des reloader sur l'iframe  par le PageDesignManager.changePageJS 
    // puis  changePageFinish   (apres le modif sur iframe)  : retour de l'iframe

    var prom = getPromise("changePageFinish");
    prom.then(() => {
        $xui.rootdata.saveLayout = false;
        currentAction = null;
        console.debug("END changePageFinish ------ " + actionName + " ------")
        if (selectionMode == "current") {
            if (reselect)
                $xui.modeDisplaySelection = true;

            //console.debug("changePageFinish ok", $xui.modeDisplaySelection);
            if ($xui.modeDisplaySelection) {
                setTimeout(() => {   // attente prise en compte chargement des images
                    if (window.$xui.config.traceReselect) {
                        console.debug("reselect after changePageFinish ", $xui.propertiesDesign);
                    }
                    $xui.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot, true);
                }, 50);
            }
        }
    });

    var prom = getPromise("changePage");
    prom.then(() => {
        if (selectionMode == "root") {
            $xui.displayPropertiesJS("root", "root");   // reaffecte le nouveau mapping sur la page
        }
        else if (selectionMode == "current") {
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
    $xui.rootdata.jsonEditorData="";
    $xui.refreshAction("template:clearAll");
    
}

$xui.addCmp = (cmp) => {
    $xui.setCurrentAction("addCmp");
    console.debug("addCmp", cmp, $xui.propertiesComponent);
    addCmpXID($xui.propertiesComponent.xid, cmp.xid);
}

$xui.deleteCmp = () => {
    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    let info = $xui.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    let infoParent = $xui.getInfoXUI(infoFile, info.parentXid, info.parentXid);
    console.debug("info deleteCmp ", $xui.propertiesDesign, info, infoParent);

    if ($xui.propertiesDesign.isSlot || info.addRemoveAction != null) {
        if (info.addRemoveAction == "incNb") {
            $xui.setCurrentAction("deleteCmp");
            $xui.changeNbChildXUI(infoFile, info.xid, "delete");
            return true
        }
        console.debug("deleteCmp slot impossible " + $xui.propertiesDesign.xid + " -> " + info.docId);
        return false;
    }
    else {
        $xui.setCurrentAction("deleteCmp");
        $xui.deleteDesign(infoFile, $xui.propertiesDesign.xid);
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
        $xui.copyDesign($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.xid);
        $xui.rootdata.pasteDisabled = false;
        return true;
    }
}

$xui.copyCmpOnDrap = (data) => {
    if ($xui.propertiesDesign.isSlot) {
        console.debug("copyCmp slot impossible");
        return false;
    }
    else {
        $xui.setCurrentAction("copyCmp");
        $xui.copyDesign($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.xid);
        $xui.rootdata.pasteDisabled = false;

        setTimeout(() => {
            let infoFile = $xui.pageDesignManager.getInfoFile("template");
            $xui.moveDesign(infoFile, null, data.xid_slot);
        }, 100);


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
        $xui.cutDesign($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.xid);
        $xui.rootdata.pasteDisabled = false;
        return true;
    }
}

$xui.pasteTo = () => {
    $xui.setCurrentAction("pasteTo");

    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    var info = $xui.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    $xui.moveDesign(infoFile, null, info.xid);
    // $xui.rootdata.pasteDisabled = true;
}

$xui.moveTo = (data) => {
    $xui.setCurrentAction("moveTo");

    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    var info = $xui.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    $xui.moveDesign(infoFile, info.xid, data.xid_slot);
}

/**************************************************************************************** */

$xui.closePopup = (event) => {
    var popupNode = document.getElementById("xui-display-selector-popup");
    if (popupNode.style.display == "block") {
        popupNode.style.display = "none";
    }
}

$xui.OpenPopupAction = (event) => {
    //--------------------------------------------------------
    console.debug("OpenPopupAction", event);

    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    var ret = $xui.getActionsXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot, "OpenPopupAction");
    console.debug(ret);

    $xui.rootdata.listPopupAdd.length = 0;
    $xui.rootdata.listPopupAdd.push(...ret);

    var popupNode = document.getElementById("xui-display-selector-popup");
    popupNode.style.left = (event.clientX) + "px";
    popupNode.style.top = (event.clientY) + "px";

    var hpopup = 16 + (40 * $xui.rootdata.listPopupAdd.length);

    if (event.clientY + 100 + hpopup > window.innerHeight) {
        popupNode.style.top = (event.clientY - hpopup) + "px";  // ouverture en dessus
    }

    popupNode.style.display = "block";   //affiche la div de selection des actions (itemPopup)

}

$xui.doActionPopup = (actionId) => {
    console.debug("doActionPopup", actionId);
    //--------------------------------------------------------
    let infoFile = $xui.pageDesignManager.getInfoFile("template");


    $xui.rootdata.activeAction = 1;  // affiche la liste des composants

    if (actionId.action == "incNbAfter") {
        $xui.setCurrentAction("addFlow");
        $xui.changeNbChildXUI(infoFile, actionId.xid, "after");
        console.debug("doActionPopup incNb OK");
        return true;
    }


    if (actionId.action == "incNbBefore") {
        $xui.setCurrentAction("addFlow");
        $xui.changeNbChildXUI(infoFile, actionId.xid, "prev");
        console.debug("doActionPopup incNb OK");
        return true;
    }


    let info = $xui.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    let infoParent = $xui.getInfoXUI(infoFile, info.parentXid, info.parentXid);
    console.debug("info add action ", $xui.propertiesDesign, info, infoParent);

    if (actionId.action == "addFlow") {
        $xui.setCurrentAction("addCmp");
        addCmpXID($xui.propertiesDesign.xidSlot, "xui-flow");
        console.debug("doActionPopup addFlow OK");
        return true;
    }

    if (actionId.action == "surroundRight") {
        $xui.setCurrentAction("addFlow");
        let cmp = { xid: 'xui-flow' };
        const newXid = $xui.getNewXid(info.parentXid, 'xui-flow');
        const currentXid = info.parentXid;
        const template = "<xui-design xid=\"" + currentXid + "\"><" + cmp.xid + " xid=\"" + newXid + "\"></" + cmp.xid + "></xui-design>";
        $xui.surroundDesign(infoFile, $xui.propertiesDesign.xid, template, newXid);
        return true;
    }

}


/// ajoute un composant
function addCmpXID(xidDest, idCmp) {
    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    const newXid = $xui.getNewXid(xidDest, idCmp);
    const template = "<xui-design xid=\"" + xidDest + "\"><" + idCmp + " xid=\"" + newXid + "\"></" + idCmp + "></xui-design>";
    $xui.addDesignXUI(infoFile, xidDest, template, true, false);
}

///---------------------------------------------------------------------------------------
$xui.getNewXid = (xidParent, nameCmp) => {
    var d = new Date().getTime();
    d += (parseInt(Math.random() * 100)).toString();

    var idxUUID = xidParent.indexOf("_");
    var pxid = idxUUID == -1 ? xidParent : (xidParent.substring(0, idxUUID));
    var ret = pxid + "-" + nameCmp.replace("xui-", "") + "_" + d;
    return ret;
}

/// incremente le nb du composant
function addSlotByVariable(infoFile, infoParent) {
    $xui.setCurrentAction("addSlot");
    infoFlow = $xui.getInfoXUI(infoFile, infoParent.parentXid, infoParent.parentXid);
    for (const aProp of $xui.rootDataProperties.data) {
        if (aProp.xid == infoFlow.xid && aProp.variable == "nb") {
            aProp.value = "" + (parseInt(aProp.value) + 1);
        }
    }
    // save properties
    $xui.hasPropertiesChanged = false;
    $xui.saveDesignPropertiesXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.json);
}


/**************************************************************************************************** */
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
    $xui.saveDesignPropertiesXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.json);
}

//--------------------------------------------------------------------------------------------------------
$xui.updateDirectProperty = (value, variable, xid) => {
    console.debug("updateDirectProperty", value, variable, xid, $xui.rootDataProperties);
    for (const aProp of $xui.rootDataProperties.data) {
        if (aProp.xid == xid && aProp.variable == variable) {
            aProp.value = value;
        }
    }
}


/***************************************************************************************************************/
$xui.sendInTab = () => {
    window.open(window.location.origin + '/loaderPage.html?id=' + $xui.rootdata.frameName, '_blank');
}

$xui.deploy = () => {
    $xui.refreshAction("export");
}

/***************************************************************************************************************/
var pageIcon = null;
var pageImage = null;

$xui.openTabUrl = (url) => {
    if (url == "pageIcon") {
        if (pageIcon == null || pageIcon.closed)
            pageIcon = window.open('https://cdn.materialdesignicons.com/5.9.55/', '_blank');
        pageIcon.focus()
    }
    if (url == "siteImage") {
        if (pageImage == null || pageImage.closed)
            pageImage = window.open('https://unsplash.com/', '_blank');
        pageImage.focus()
    }
};

/***************************************************************************************************************/


$xui.displayPropertiesJS = (xid, xid_slot) => {
    let infoFile = $xui.pageDesignManager.getInfoFile("template");

    //AppPropertiesBindingSetting

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

        if (window.$xui.config.traceDisplayPropertiesJS) {
            console.debug("displayPropertiesJS", $xui.propertiesDesign);
        }

        $xui.rootDataProperties = { data: $xui.propertiesDesign.json };
        var template = "<div id='AppPropertiesSetting' class='barcustom xui-div-scroll-vertical'>" + $xui.propertiesDesign.template + "</div>";
        var tmpCompiled = compileTemplate(template);

        if ($xui.vuejsAppPropertiesSetting != null) {
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

    let infoFile = $xui.pageDesignManager.getInfoFile("template");

    $xui.propertiesComponent = $xui.getComponentsXUI(infoFile, xid, xid_slot);
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
        template: "<div id='AppComponents' class='xui-div-scroll-vertical barcustom'>" + $xui.propertiesComponent.template + "</div>",
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

/*******************************************LES ACTIONS DELETE, ADD, EDIT**************************************************/
var cacheHtmlAction = null;
$xui.displayAction = (xid, xid_slot) => {
    if (cacheHtmlAction == null) {
        var infoFile = { file: 'app/cmpDesignPropEditor.html', xid: 'bottom-editor', mode: 'final' };
        var prom = getPromise("displayActionPromise");
        $xui.getHtmlFromXUI(infoFile, "displayActionPromise");
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
function compileTemplate(template) {
    return Vue.compile(template);
}

/***************************************************************************************************************/

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


