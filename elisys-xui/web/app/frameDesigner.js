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
    const rootdata = $xui.getAppState().main;
    rootdata.overlay=true;
    $xui.SelectorManager.unDisplaySelector();
    console.debug("doInitPage pageInfo = ", pageInfo);

    rootdata.frameName=pageInfo.frameName;
    rootdata.frameTemplate=pageInfo.frameTemplate;
    rootdata.stateData = {};
    rootdata.stateDataMock = {};
    rootdata.stateDataSource="";
    rootdata.idxTabMain=0;
    if (document.querySelector("#rootFrame")!=null)
    {
        document.querySelector("#rootFrame").style.display = 'none';
    } 
    const state = $xui.vuejs.$store.state;

    if (state.main.version==null) { // mode version 1
        $xui.router.push("/page1");
    }

    waitForXuiLib("initPageXUI", () => {

        setTimeout(() => {
            const infoFile = $xui.pageDesignManager.getInfoFile("design");
            $xuicore.initPageXUI(infoFile);
        }, 100);

    });
}


/****************************************************************************************/
// charge la page global aprés le retour du XUIEngine
$xui.loadPageJS = (html, options) => {
    console.debug("loadPageJS options ---- ", options);
    $xui.pageDesignManager.loadPage(html, options);
};

// change une partie de la page aprés le retour du XUIEngine
$xui.changePageJS = (param) => {
    console.debug("changePageJS options ---- ", param);
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

    if (infoFile.action==null)
    {
        infoFile.action="?";
    }

    $xuicore.refreshPageXUI(infoFile);
};

/************************************************* LES ACTIONS ***************************************************/

let lastActionDate = Date.now();
let lastAction = null;
let currentAction = null;

const mapAction = {
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
$xui.modeDisplaySelection = true;

$xui.setCurrentAction = (actionName) => {
    const rootdata = $xui.getAppState().main;
    if (currentAction != null) {
        throw (new SpecifiedError(`action déjà en cours ${actionName} => ${lastAction}`));
    }

    const actionDec = mapAction[actionName];

    if (actionDec != null) {
        if (actionDec.text != null) {
            rootdata.snackbar_text = actionDec.text;
            rootdata.snackbar_timeout = actionDec.timeout;
            rootdata.snackbar = true;
        }
    }
    else {
        rootdata.snackbar_text = actionName;
        rootdata.snackbar_timeout = 1000;
        rootdata.snackbar = true;
    }

    rootdata.saveLayout = true;

    lastActionDate = Date.now();
    lastAction = actionName;
    currentAction = actionName;
    console.debug(`START ACTION ------- ${actionName} ---------`)
    let selectionMode = "root";
    const undisplaySelector = true;
    let reselect = $xui.modeDisplaySelection;

    /**************************/
    if (actionName == "addCmp")
        selectionMode = "none";

    if (actionName == "saveProperties" || actionName == "OpenPopupAction")
        selectionMode = "current";

    if (actionName == "addSlot")
    {
        selectionMode = "current";
        reselect=true;
    }


    if (actionName == "moveTo")
        selectionMode = "current";
    /**************************/

    if (undisplaySelector)
        $xui.SelectorManager.unDisplaySelector();

    // setCurrentAction  => puis appel XUI
    // puis  <changePage>  (affichage du code et save localstorage)  : retour du xui
    //     => lancement des reloader sur l'iframe  par le PageDesignManager.changePageJS 
    // puis  <changePageFinish>   (apres le modif sur iframe)  : retour de l'iframe

    let prom = getPromise("AfterChangeSelectByXid");
    prom.then(() => {
        rootdata.saveLayout = false;
        currentAction = null;

        console.debug(`END changePageFinish ------ ${actionName} ------`)
        if (selectionMode == "current") {
            if (reselect)
                $xui.modeDisplaySelection = true;

            if ($xui.modeDisplaySelection) {
                setTimeout(() => {   // attente prise en compte chargement des images = taille avec image
                    if (window.$xui.config.traceReselect) {
                        console.debug("reselect after changePageFinish ", $xui.propertiesDesign);
                    }
                    $xui.SelectorManager.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot, true);
                }, 50);
            }
        }
    });

    prom = getPromise("AfterChangeDisplayProperties");
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
    const rootdata = $xui.getAppState().main;

    $xui.pageDesignManager.clearAll();
    $xui.SelectorManager.unDisplaySelector();
    rootdata.routeEnable = true;
    rootdata.actionEnable = true;
    rootdata.idxTabMain=0;
    rootdata.overlayEvent=false;
    rootdata.overlay=true;
    document.querySelector("#rootFrame").style.display = 'none';
   
    const infoFile = $xui.pageDesignManager.getInfoFile("design");
    $xuicore.initPageXUI(infoFile);

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
    const infoFile = $xui.pageDesignManager.getInfoFile("template");
    const info = $xuicore.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    const infoParent = $xuicore.getInfoXUI(infoFile, info.parentXid, info.parentXid);
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
    
    $xui.setCurrentAction("copyCmp");
    $xuicore.copyDesignXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.xid);
    const rootdata = $xui.getAppState().main;
    rootdata.pasteDisabled=false;
    return true;
}

$xui.copyCmpOnDrap = (data) => {
    if ($xui.propertiesDesign.isSlot) {
        console.debug("copyCmp slot impossible");
        return false;
    }

    $xui.setCurrentAction("copyCmp");
    $xuicore.copyDesignXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.xid);
    const rootdata = $xui.getAppState().main;
    rootdata.pasteDisabled = false;
    setTimeout(() => {
        let infoFile = $xui.pageDesignManager.getInfoFile("template");
        $xuicore.moveDesignXUI(infoFile, null, data.xid_slot);
    }, 100);
    return true;
}

$xui.cutCmp = () => {
    if ($xui.propertiesDesign.isSlot) {
        console.debug("cutCmp slot impossible");
        return false;
    }

    $xui.setCurrentAction("cutCmp");
    $xuicore.cutDesignXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.xid);
    const rootdata = $xui.getAppState().main;
    rootdata.pasteDisabled = false;
    return true;
}

$xui.pasteTo = () => {
    $xui.setCurrentAction("pasteTo");

    const infoFile = $xui.pageDesignManager.getInfoFile("template");
    const info = $xuicore.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    $xuicore.moveDesignXUI(infoFile, null, info.xid);
}

$xui.moveTo = (data) => {
    $xui.setCurrentAction("moveTo");

    const infoFile = $xui.pageDesignManager.getInfoFile("template");
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
    const infoFile = $xui.pageDesignManager.getInfoFile("template");
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
    const rootdata = $xui.getAppState().main;
    // recuperation de la configuration
    const config = {   
        routeEnable : rootdata.routeEnable,
        actionEnable: rootdata.actionEnable,
        isModePhone : rootdata.isModePhone,
        dataSrc : rootdata.stateDataSource
    }

    $xui.propertiesDesign.json.push(
    {
        xid : "root",
        variable : `appConfig`,
        value : JSON.stringify(config),
        bind : "@"
    });

    console.debug("saveProperties", $xui.propertiesDesign.json);

    $xui.hasPropertiesChanged = false;
    $xuicore.saveDesignPropertiesXUI($xui.pageDesignManager.getInfoFile("template"), $xui.propertiesDesign.json);
}



/****************************************************************************************/
$xui.generateApplicationStateJS = (namespace, StateTemplate, StateInProperty) => {
    const jsonTemplate = $xui.parseJson(`{${StateTemplate}}`);
    const jsonStateProp = $xui.parseJson(`{${StateInProperty}}`);
    let ret = null;

    const rootdata = $xui.getAppState().main;
    Object.keys(rootdata.stateData).forEach((key) => {
        delete rootdata.stateData[key];
    });
    Object.assign(rootdata.stateData, jsonTemplate);
    ret = rootdata.stateData;


    if (rootdata.stateDataSource == "mock") {
        ret = rootdata.stateDataMock;
    }

    if (StateTemplate == "" && StateInProperty == "")  // sauvegarde le mock
    {
        ret = rootdata.stateDataMock;
    }
    else {
        rootdata.stateDataMock = jsonStateProp;
    }

    const jsonState = ret;
    let str = $xuicore.getJsonValidatorXUI($xui.pageDesignManager.getInfoFile("template"));
    str = `${str}\n//# sourceURL=xui-json-validator.js;\n`;
    eval(str);

    console.debug("************ App State initial & mock", jsonTemplate, jsonStateProp);
    console.debug("************ App State source & editor", jsonState, rootdata.stateData);
    // retourne au XUI le chaine à sauvegarder sans {}
    ret = JSON.stringify(jsonState);
    return ret.substring(1, ret.length - 1);
};

//--------------------------------------------------------------------------------------------------------
/***************************************************************************************************************/
$xui.fullScreen = () => {
    $xui.SelectorManager.unDisplaySelector();
    window.document.documentElement.requestFullscreen();
}

$xui.modePreview = () => {
    const rootdata = $xui.getAppState().main;
    if (! rootdata.overlayEvent) return;
    
    $xui.isModePreview = !$xui.isModePreview;
    document.querySelector("#rootFrame").classList.toggle("xui-frame-full-screen");
    $xui.refreshAction($xui.isModePreview ? "preview" : "design");
    rootdata.overlay = $xui.isModePreview;
}

$xui.modePhone = () => {
    const rootdata = $xui.getAppState().main;
    document.querySelector("#rootFrame").classList.toggle("xui-iframe-phone");
    rootdata.isModePhone =  document.querySelector("#rootFrame").classList.contains("xui-iframe-phone");
}


$xui.getUrlApp = () => {
    let origin = window.location.origin;
    if (origin=="null")
        origin=window.parent.location.origin;

    const rootdata = $xui.getAppState().main;
    return `${origin}/load.html?id=${rootdata.frameName}`;
}

$xui.sendInTab = () => {
    window.open($xui.getUrlApp(), '_blank');
}

$xui.sendByMail = () => {
    window.open(`mailto:test@example.com?subject=app&body=${$xui.getUrlApp()}`);
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
        const rootdata = $xui.getAppState().main;
        $xui.pageDesignManager.clearAll();
        $xui.pageDesignManager.codeXUIdata = event.target.result;
        $xui.pageDesignManager.store();
        const infoFile = $xui.pageDesignManager.getInfoFile("design");
        $xuicore.initPageXUI(infoFile);
        rootdata.idxTabMain = 0;
    }
    reader.readAsText(file);
}

$xui.XUIToClipboard = () => {
    navigator.clipboard.writeText($xui.pageDesignManager.codeXUI);
    const rootdata = $xui.getAppState().main;
    rootdata.snackbar_text = "Copy to clipboard terminated";
    rootdata.snackbar_timeout = 2000;
    rootdata.snackbar = true;
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


$xui.callAPI = (api) => {
    fetch(api.base+api.url, {
        method: api.method //ou POST, PUT, DELETE, etc.
        // ,headers: {
        //   "Content-Type": "text/plain;charset=UTF-8" //pour un corps de type chaine
        // },
        // body: undefined, //ou string, FormData, Blob, BufferSource, ou URLSearchParams
        // referrer: "about:client", //ou "" (pas de réferanr) ou une url de l'origine
        // referrerPolicy: "no-referrer-when-downgrade", //ou no-referrer, origin, same-origin...
        // mode: "cors", //ou same-origin, no-cors
        // credentials: "same-origin", //ou omit, include
        // cache: "default", //ou no-store, reload, no-cache, force-cache, ou only-if-cached
        // redirect: "follow", //ou manual ou error
        // integrity: "", //ou un hash comme "sha256-abcdef1234567890"
        // keepalive: false, //ou true pour que la requête survive à la page
        // signal: undefined //ou AbortController pour annuler la requête
    })
    .then(response => response.json())
    .then(response => alert(JSON.stringify(response)))
    .catch(error => alert(`Erreur : ${error}`));

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

function jsonPathToValue(data, path) {
    if (!path) return data; // if path is undefined or empty return data
    const listpath = path.split(".");
    for (let index = 0; index < listpath.length; index++) {
       if (!listpath[index]) continue; // "a/" = "a"
       data = data[listpath[index]]; // new data is subdata of data
       if (!data) return data; // "a/b/d" = undefined
    }
    return data;
 }

 function setValueFromJsonPath (data, path, value) {
    if (!path) return data; // if path is undefined or empty return data
    const listpath = path.split(".");

    for (let index = 0; index < listpath.length; index++) {
       if (!listpath[index]) continue; // "a/" = "a"
       if (index==listpath.length-1) 
       {
            data[listpath[index]] = value;
       }
       data = data[listpath[index]]; // new data is subdata of data
       if (!data) return data; // "a/b/d" = undefined
    }
    return data;
 }



