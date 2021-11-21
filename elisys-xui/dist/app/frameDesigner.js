//    editor en vuejs  : https://codepen.io/NicolasLrnd/pen/XPdxKv

// https://stackoverflow.com/questions/45630151/is-it-possible-to-globally-remove-a-vue-component-from-the-global-registry


if (typeof window.$xui === 'undefined')
    window.$xui = {};

if (typeof window.$xuicore === 'undefined')
    window.$xuicore = {};

window.$xui.config = {};
window.$xui.config.traceDisplayPropertiesJS = false
window.$xui.config.traceReselect = false
/****************************  CHARGEMENT DE LA PAGE *************************************/

import("./clsPageDesignManager.js").then((module) => {
    $xui.pageDesignManager = new module.PageDesignManager();

    waitForXuiLib("initPageXUI", () => {
        $xui.doPromiseJS = doPromiseJS;
    }, this);
});

import("./clsEventDesignManager.js").then((module) => {
    new module.EventManager().init();
});

import("./clsSelectorManager.js").then((module) => {
    $xui.SelectorManager=new module.SelectorManager();
});

/****************************************************************************************/
$xui.doInitPage = (pageInfo) => {
    console.debug("pageInfo = ", pageInfo);

    $xui.rootdata.frameName=pageInfo.frameName;
    $xui.rootdata.frameTemplate=pageInfo.frameTemplate;

    $xui.router.push("/page1");

    setTimeout(() => {
        const infoFile = $xui.pageDesignManager.getInfoFile("design");
        $xuicore.initPageXUI(infoFile);
    }, 100);
}

/****************************************************************************************/
$xui.generateApplicationStateJS = (StateTemplate, StateInProperty) => {
    const jsonTemplate = $xui.parseJson(`{${StateTemplate}}`);
    const jsonStateProp = $xui.parseJson(`{${StateInProperty}}`);
    var ret = null;

    Object.keys($xui.rootdata.jsonEditorData).forEach((key) => {
        delete $xui.rootdata.jsonEditorData[key];
    });
    Object.assign($xui.rootdata.jsonEditorData, jsonTemplate);
    ret = $xui.rootdata.jsonEditorData;


    if ($xui.rootdata.jsonEditorDataSrc == "mock") {
        ret = $xui.rootdata.jsonEditorDataMock;
    }

    if (StateTemplate == "" && StateInProperty == "")  // sauvegarde le mock
    {
        ret = $xui.rootdata.jsonEditorDataMock;
    }
    else {
        $xui.rootdata.jsonEditorDataMock = jsonStateProp;
    }

    console.debug("************ App State initial & mock", jsonTemplate, jsonStateProp);
    console.debug("************ App State source & editor", ret, $xui.rootdata.jsonEditorData);
    // retourne au XUI le chaine à sauvegarder 
    var ret = JSON.stringify(ret);
    return ret.substring(1, ret.length - 1);
};

/****************************************************************************************/
// charge la page global aprés le retour du XUIEngine
$xui.loadPageJS = (html, options) => {
    console.debug("loadPageJS binding ---- ", options);
    $xui.pageDesignManager.loadPage(html, options);
};

// change une partie de la page aprés le retour du XUIEngine
$xui.changePageJS = (param) => {
    $xui.pageDesignManager.changePageOnFrame(param);
    doPromiseJS("AfterChangeDisplayProperties");
};

/******************************************************************************** */
// gestion des button refresh et export de la page
$xui.refreshAction = (mode) => {
    const infoFile = $xui.pageDesignManager.getInfoFile(mode);

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

    $xuicore.refreshPageXUI(infoFile);
};

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
$xui.isModePreview = false;
$xui.modeDisplaySelection = false;


$xui.setCurrentAction = (actionName) => {

    if (currentAction != null)
        throw (new SpecifiedError(`action déjà en cours ${actionName} => ${lastAction}`));

    const actionDec = mapAction[actionName];
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
    console.debug(`START ACTION ------- ${actionName} ---------`)
    let selectionMode = "root";
    let undisplaySelector = true;
    let reselect = $xui.modeDisplaySelection;

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
        $xui.SelectorManager.unDisplaySelector();

    // setCurrentAction  => puis appel XUI
    // puis  <changePage>  (affichage du code et save localstorage)  : retour du xui
    //     => lancement des reloader sur l'iframe  par le PageDesignManager.changePageJS 
    // puis  <changePageFinish>   (apres le modif sur iframe)  : retour de l'iframe

    var prom = getPromise("AfterChangeSelectByXid");
    prom.then(() => {
        $xui.rootdata.saveLayout = false;
        currentAction = null;

        console.debug(`END changePageFinish ------ ${actionName} ------`)
        if (selectionMode == "current") {
            if (reselect)
                $xui.modeDisplaySelection = true;

            //console.debug("changePageFinish ok", $xui.modeDisplaySelection);
            if ($xui.modeDisplaySelection) {
                setTimeout(() => {   // attente prise en compte chargement des images
                    if (window.$xui.config.traceReselect) {
                        console.debug("reselect after changePageFinish ", $xui.propertiesDesign);
                    }
                    $xui.SelectorManager.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot, true);
                }, 50);
            }
        }
    });

    var prom = getPromise("AfterChangeDisplayProperties");
    prom.then(() => {
        if (selectionMode == "root") {
            $xui.displayPropertiesJS("root", "root");   // reaffecte le nouveau mapping sur la page
        }
        else if (selectionMode == "current") {
            $xui.displayPropertiesJS($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);   // reaffecte le nouveau mapping
        }
        console.debug(`END changePage ------ ${actionName} ------`)
    }
    );

    return true;
}

/***************************************************************************************************************/
$xui.clearAll = () => {
    $xui.setCurrentAction("clearAll");
    $xui.pageDesignManager.clearAll();
    $xui.rootdata.jsonEditorData = {};
    $xui.refreshAction("template:clearAll");
}

$xui.updateDirectProperty = (value, variable, xid) => {
    console.debug("updateDirectProperty", value, variable, xid, $xui.rootDataProperties);
    for (const aProp of $xui.rootDataProperties.data) {
        if (aProp.xid == xid && aProp.variable == variable) {
            aProp.value = value;
        }
    }
}

$xui.deleteCmp = () => {
    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    let info = $xuicore.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    let infoParent = $xuicore.getInfoXUI(infoFile, info.parentXid, info.parentXid);
    console.debug("info deleteCmp ", $xui.propertiesDesign, info, infoParent);

    if ($xui.propertiesDesign.isSlot || info.addRemoveAction != null) {
        if (info.addRemoveAction == "incNb") {
            $xui.setCurrentAction("deleteCmp");
            $xuicore.changeNbChildXUI(infoFile, info.xid, "delete");
            return true
        }
        console.debug(`deleteCmp slot impossible ${$xui.propertiesDesign.xid} -> ${info.docId}`);
        return false;
    }
    else {
        $xui.setCurrentAction("deleteCmp");
        $xuicore.deleteDesignXUI(infoFile, $xui.propertiesDesign.xid);
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
        $xuicore.copyDesignXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.xid);
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
        $xuicore.copyDesignXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.xid);
        $xui.rootdata.pasteDisabled = false;

        setTimeout(() => {
            let infoFile = $xui.pageDesignManager.getInfoFile("template");
            $xuicore.moveDesignXUI(infoFile, null, data.xid_slot);
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
        $xuicore.cutDesignXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.xid);
        $xui.rootdata.pasteDisabled = false;
        return true;
    }
}

$xui.pasteTo = () => {
    $xui.setCurrentAction("pasteTo");

    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    const info = $xuicore.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    $xuicore.moveDesignXUI(infoFile, null, info.xid);
}

$xui.moveTo = (data) => {
    $xui.setCurrentAction("moveTo");

    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    const info = $xuicore.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    $xuicore.moveDesignXUI(infoFile, info.xid, data.xid_slot);
}

$xui.undo = () => {
    $xui.setCurrentAction("undo");
    $xui.pageDesignManager.undo();
};

$xui.redo = () => {
    $xui.setCurrentAction("redo");
    $xui.pageDesignManager.redo();
};



$xui.addCmp = (cmp) => {
    $xui.setCurrentAction("addCmp");
    console.debug("addCmp", cmp, $xui.propertiesComponent);
    $xui.addCmpXID($xui.propertiesComponent.xid, cmp.xid);
}


/**************************************************************************************** */
///---------------------------------------------------------------------------------------
/// ajoute un composant
$xui.addCmpXID = (xidDest, idCmp) => {
    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    const newXid = $xui.getNewXid(xidDest, idCmp);
    const template = `<xui-design xid="${xidDest}"><${idCmp} xid="${newXid}"></${idCmp}></xui-design>`;
    $xuicore.addDesignXUI(infoFile, xidDest, template, true, false);
}

$xui.getNewXid = (xidParent, nameCmp) => {
    let d = new Date().getTime();
    d += (parseInt(Math.random() * 100)).toString();

    const idxUUID = xidParent.indexOf("_");
    const pxid = idxUUID == -1 ? xidParent : (xidParent.substring(0, idxUUID));
    const ret = `${pxid}-${nameCmp.replace("xui-", "")}_${d}`;
    return ret;
}

/// incremente le nb du composant
// function addSlotByVariable(infoFile, infoParent) {
//     $xui.setCurrentAction("addSlot");
//     infoFlow = $xui.getInfoXUI(infoFile, infoParent.parentXid, infoParent.parentXid);
//     for (const aProp of $xui.rootDataProperties.data) {
//         if (aProp.xid == infoFlow.xid && aProp.variable == "nb") {
//             aProp.value = "" + (parseInt(aProp.value) + 1);
//         }
//     }
//     // save properties
//     $xui.hasPropertiesChanged = false;
//     $xui.saveDesignPropertiesXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.json);
// }


/**************************************************************************************************** */

$xui.saveProperties = () => {
    $xui.setCurrentAction("saveProperties");
    console.debug("saveProperties", $xui.propertiesDesign.json);

    $xui.hasPropertiesChanged = false;
    $xuicore.saveDesignPropertiesXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.json);
}

//--------------------------------------------------------------------------------------------------------
const pause = ms => new Promise(resolve => setTimeout(resolve, ms))

function initPathTo(pathTo) {
    let parent = $xui.rootdata.activeSlot[0];
    let hasRouteDefine = false;
    do {
        if (parent.toPath != null) {

            if (parent.toPath.startsWith("router:")) {
                if (!hasRouteDefine) {
                    pathTo.unshift(parent.toPath);
                    hasRouteDefine = true;
                }

            }

            else {
                pathTo.unshift(parent.toPath);
            }
        }
        parent = parent.parent;
    } while (parent != null);
}

$xui.selectCmp = async () => {
    console.debug($xui.rootdata.activeSlot);

    if ($xui.rootdata.activeSlot.length>0)
    {
        const pathTo = [];
        initPathTo(pathTo);

        for (const action of pathTo) {
            if (action.startsWith("router:"))
            {
                const url = action.substring(7);
                await $xui.goToRoute(url);
            }
            if (action.startsWith("click:"))
            {
                var xid = action.substring(6);
                await $xui.goToClick(xid);
            }
        };

        var xid = $xui.rootdata.activeSlot[0].id;
        $xui.SelectorManager.displaySelectorByXid(xid, xid, false);
    }
}

$xui.goToClick =async (xid) => {
    const node = document.querySelector("#rootFrame").contentWindow.document.querySelectorAll(`[data-xid-slot=${xid}]`);
    node[0].click();
    await pause(300);
}

$xui.goToRoute =async (url) => {
    if (url.endsWith("/route0")) {
        url = url.substring(0, url.length - 7);
    }
    if (url.startsWith("/page0")) {
        url = url.substring(6, url.length);
    }
    if (url == "") {
        url = "/";
    }
    const router = document.querySelector("#rootFrame").contentWindow.$xui.router;

    if (router.currentRoute.path != url) {
        console.debug("route to", url, router.currentRoute.path);
        router.push(url);
        await pause(400);
    }
}

/***************************************************************************************************************/
$xui.fullScreen = () => {
    $xui.SelectorManager.unDisplaySelector();
    window.document.documentElement.requestFullscreen();
}

$xui.modePreview = () => {
    $xui.isModePreview = !$xui.isModePreview;
    document.querySelector("#rootFrame").classList.toggle("xui-frame-full-screen");
    $xui.refreshAction($xui.isModePreview ? "preview" : "design");
    $xui.rootdata.overlay = $xui.isModePreview;
}

$xui.modePhone = () => {
    document.querySelector("#rootFrame").classList.toggle("xui-iframe-phone");
}


$xui.getUrlApp = () => {
    let origin = window.location.origin;
    if (origin=="null")
        origin=window.parent.location.origin;

   return `${origin}/load.html?id=${$xui.rootdata.frameName}`;
}

$xui.sendInTab = () => {
    window.open($xui.getUrlApp(), '_blank');
}

$xui.deploy = () => {
    $xui.refreshAction("export");
}


$xui.downloadPage = () => {
    const file = new File([$xui.pageDesignManager.codeXUIdata], "export.txt", { type: "text/plain;charset=utf-8" });
    FileSaver.saveAs(file);
}

$xui.importPage = (file) => {
    console.debug(file);
    const reader = new FileReader();
    reader.onload = (event) => {
        $xui.pageDesignManager.clearAll();
        $xui.pageDesignManager.codeXUIdata = event.target.result;
        $xui.pageDesignManager.store();
        const infoFile = $xui.pageDesignManager.getInfoFile("design");
        $xuicore.initPageXUI(infoFile);
        $xui.rootdata.activeTab = 0;
    }
    reader.readAsText(file);
}


/***************************************************************************************************************/
let pageIcon = null;
let pageImage = null;

$xui.openTabUrl = (url) => {
    if (url == "pageIcon") {
        if (pageIcon == null || pageIcon.closed)
            pageIcon = window.open('https://materialdesignicons.com/', '_blank');
        pageIcon.focus()
    }
    if (url == "siteImage") {
        if (pageImage == null || pageImage.closed)
            pageImage = window.open('https://unsplash.com/', '_blank');
        pageImage.focus()
    }
};


/***************************************************************************************************************/
function compileTemplate(template) {
    return Vue.compile(template);
}


$xui.parseJson = (str) => {
    try {
        return JSON.parse(str);
    } catch (error) {
        console.debug("pb parse json", error, str);
    }
}




