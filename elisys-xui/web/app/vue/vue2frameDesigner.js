/******************************** Creation du reloader **************************************/
var $xui = window.$xui;  // car module

$xui.listReloader = {};  // liste des reloader   ajouter dans le vue2frameDesigner
$xui.nbRefeshReloader = 0;

$xui.initComponentVuejs.push(() => { //register VueComponent from XUI File
    //console.debug("create component v-xui-reloader")
    Vue.component("v-xui-reloader",
        {
            template: '<component v-bind:is="componentToReload"></component>',
            props: ['partid', 'modedisplay'],
            data: () => { return { componentToReload: "", id: 1 }; },
            methods: {
                doChangeComponent(e) {

                    var oldId = `${this.partid}-${this.id}`;
                    //console.debug("doChangeComponent " + oldId + " reponse **************", e)
                    delete Vue.options.components[oldId];

                    this.id++; //passe en composant suivant
                    var newId = `${this.partid}-${this.id}`;

                    // creation du composant 
                    Vue.component(newId,
                        {
                            template: `<div style="display:${this.modedisplay}">${e.template}</div>`,
                            mixins: [$xui.mixinStore],
                        }
                    );
                    this.componentToReload = newId;   // change le contenu du composant  id = componentToReload

                    this.$nextTick(function () {
                        $xui.nbRefeshReloader--;
                        //console.debug("nbRefeshReloader ", $xui.nbRefeshReloader)
                        if ($xui.nbRefeshReloader == 0) {
                            var message = {
                                action: "reloader finish",
                            };
                            window.parent.postMessage(message, "*");
                        }
                    });
                },
                reload() {
                    //console.debug("reload **************", this.partid)
                    $xui.nbRefeshReloader++;
                    var message = {
                        action: "get template reloader",
                        xid: this.partid,
                    };
                    window.parent.postMessage(message, "*");
                }
            },
            mounted() {
                this.reload();
                $xui.listReloader[this.partid] = this;  // enregistre le loader
            },
            computed: {
                $xui: () => $xui
            }
        });
}
);
/***********************************************************************************/
document.addEventListener('dragenter', (e) => {
    const slotDroppable = e.target.closest('.xui-class-slot');
    if (slotDroppable) {
        slotDroppable.classList.add("xui-class-dragover");
    }
});

document.addEventListener('dragleave', (e) => {
    const slotDroppable = e.target.closest('.xui-class-slot');
    if (slotDroppable)
        slotDroppable.classList.remove("xui-class-dragover");
});

document.addEventListener('dragover', (e) => {
    const slotDroppable = e.target.closest('.xui-class-slot');
    if (slotDroppable)
        e.preventDefault();
});

document.addEventListener('drop', (e) => {
    const slotDroppable = e.target.closest('.xui-class-slot');
    if (slotDroppable) {
        e.preventDefault();
        const idCmp = e.dataTransfer.getData('text/plain');
        let targetAction = e.target.closest("[data-xid]");

        console.debug("drop ", idCmp, targetAction);
        const message = { action: "drop", ctrlKey: e.ctrlKey, xid: targetAction.dataset.xid, xid_slot: targetAction.dataset.xidSlot };
        window.parent.postMessage(message, "*");
    }
});

// Cet événement détecte n'importe quel drag & drop qui se termine, autant le mettre sur « document » :
document.addEventListener('dragend', () => {
});

/***********************************************************************************/

document.addEventListener('pointerdown', e => {
    $xui.targetActionStart = e.target.closest("[data-xid]");
});

document.addEventListener('pointerup', (e)=> { 
    if (e.button != 0)
             return;
    selectSelector(e, "select");
    });
document.addEventListener( "contextmenu", (e)=> {
    e.preventDefault();
    selectSelector(e, "popupAction")
  });

const selectSelector = (e, action) => {
    const targetAction = e.target.closest("[data-xid]");
    if ($xui.targetActionStart != targetAction)
        return;  // ne fait rien sur le drag si drag sur le même composant  (ex : Split)

    const elemRect = targetAction.getBoundingClientRect();
    const s = getComputedStyle(targetAction);
    const margin = { mb: parseInt(s.marginBottom), mt: parseInt(s.marginTop), ml: parseInt(s.marginLeft), mr: parseInt(s.marginRight) }

    let displayMode = getDisplayInfo(s, targetAction);

    const message = {
        action: action,
        xid: targetAction.dataset.xid,
        xid_slot: targetAction.dataset.xidSlot,
        position: {
            parentDisplay: displayMode,
            hasMargin: (margin.mb > 0 || margin.mt > 0 || margin.ml > 0 || margin.mr > 0),
            height: elemRect.height,
            width: elemRect.width,
            left: elemRect.left,
            top: elemRect.top,
            clientX : e.clientX,
            clientY : e.clientY,
            ...margin
        },
    };
    window.parent.postMessage(message, "*");
}

$xui.getInfoForSelector = (selector, parent) => {
    let targetAction = document.querySelector(selector);
    if (targetAction == null) return null;
    if (parent)
        targetAction = targetAction.parentNode;

    let elemRect = targetAction.getBoundingClientRect();
    let s = getComputedStyle(targetAction);

    let displayMode = getDisplayInfo(s, targetAction);

    let margin = { mb: parseInt(s.marginBottom), mt: parseInt(s.marginTop), ml: parseInt(s.marginLeft), mr: parseInt(s.marginRight) }

    const ret = {
        selector,
        parent,
        parentDisplay: displayMode,
        hasMargin: (margin.mb > 0 || margin.mt > 0 || margin.ml > 0 || margin.mr > 0),
        height: elemRect.height,
        width: elemRect.width,
        left: elemRect.left,
        top: elemRect.top,
        ...margin
    };

    return ret;
}


const unselectSelector = (event) => {
    const message = {
        action: "unselect",
    };
    window.parent.postMessage(message, "*");
};

document.addEventListener('scroll', unselectSelector);
window.addEventListener('resize', unselectSelector);


//********************************** DISPACH DES EVENTS PROVENANT DU DESIGNER ******************************** */
const iterateJSON = (src, dest, funct, functArray) => {
    if (dest==null) {
        return
    } 

    const entry = Object.entries(src);
    const entries = entry.map(([key, value]) =>
        Array.isArray(value) && dest!=null ? [key, value.map(e => {
            var nt = null;
            if (Array.isArray(dest[key])) {
                nt = dest[key][value.indexOf(e)];
            }
            functArray(value, dest[key], e);
            iterateJSON(e, nt, funct, functArray)
        })]
            : typeof value === 'object' && dest!=null
                ? [key, iterateJSON(value, dest[key], funct, functArray)]
                : [key, funct(key, value, dest)]
    );
    return Object.fromEntries(entries);
};

function getDisplayInfo(s, targetAction) {
    let displayMode= null;

    if (s.position == "fixed") {
        displayMode = "fixed";
    }

    else {

        if (targetAction.tagName == "INPUT") {
            targetAction = targetAction.closest(".v-input");
        }
        if (targetAction.parentNode.classList!=null && targetAction.parentNode.classList.contains("v-input__slot")) {
            targetAction = targetAction.closest(".v-input");
        }

        if (targetAction.parentNode==window.document)
            return "html";


        let sp = getComputedStyle(targetAction.parentNode);
        if (sp.display == "contents")
            sp = getComputedStyle(targetAction.parentNode.parentNode);

        displayMode = sp.display;

        if (displayMode == "flex") {
            displayMode = displayMode + " " + sp.flexDirection;
        }

        // console.debug(">>>>>>>>>>>>>>>>>>>>>> parent", targetAction.parentNode);
    }

    return displayMode;
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


window.addEventListener('message', (e) => {
    const data = e.data;
    if (data.action != "getInfoForSelector" && data.action!="doChangeComponent") {
        console.debug("--- CORE --- message ", data);
    }

    switch (data.action) {

        case "changeJS":
            console.debug("changeJS ", data, $xui.modulesManager);
            const module = data.param.namespace;
            for (const mth of data.param.actions) {
                const m = `async (p1, p2) => {\n${mth.code}\n};`;
                $xui.modulesManager.addAction(module, mth.name, `${m}\n//# sourceURL=${module}-${mth.name}.js;`);
            }
            $xui.modulesManager.reload();
            break;

        case "switchValue":
            const rootdata = $xui.getAppState().main;
            const value = jsonPathToValue(rootdata, data.param.attr);
            setValueFromJsonPath(rootdata, data.param.attr, !value);
            $xui.modulesManager.addModule("main", rootdata);
            $xui.modulesManager.reload();
            break;

        case "changeConfig":
            console.debug("changeConfig ", data);
            if ('routeEnable' in data.param) {
                 $xui.routeEnable = data.param.routeEnable;  // autorisation de changement de root
            }
            if ('actionEnable' in data.param) {
                $xui.actionEnable = data.param.actionEnable;  // autorisation de changement de root
             }
            break;

        case "changeTemplate":
            changeTemplateOrState(data);
            break;

        case "doChangeComponent":
            if ($xui.listReloader[data.xid] == null)
                console.error("doChangeComponent on error", data, $xui.listReloader);
            $xui.listReloader[data.xid].doChangeComponent(data);
            break;

        case "getInfoForSelector":
            const ret = $xui.getInfoForSelector(data.selector, data.parent);

            const message = {
                action: "return getInfoForSelector",
                info: data,
                ret
            };

            window.parent.postMessage(message, "*");
            break;
    }

});

function changeTemplateOrState(data) {
    const hasChangeBinding = validStoreState(data);

    let changeContent = true;
    if (data.param.action == "reload-json") {
        if (hasChangeBinding)
            data.param.listReloader = null; // recharge tout
        else
            changeContent = false; // change uniquement le json du template
    }

    if (changeContent) {
        const oldrouteEnable = $xui.routeEnable;
        $xui.routeEnable = true; // autorise le positionnements des routes durant les reloads

        doChangeContent(data);

        $xui.routeEnable = oldrouteEnable;
    }
}

function validStoreState(data) {

    let mustBeReload = false;
    let mustBeRevalidate = false;

    if ( /*data.param.action == "reload-json" && data.param.listReloader == null &&*/ data.param.jsonListStateModule != null) {
        data.param.jsonListStateModule.forEach(module => {

            let hasChangeBinding = false;
            let hasChangeValue = false;
            const jsonBinding = module.stateData; // template ou mock
            const dataState = $xui.getAppState()[module.nameModule];
    
            iterateJSON(jsonBinding, dataState,
                (k, v, dest) => {
                    //console.log("k=", k, " v=", v)
                    if (dest == null || dest[k] == null) {
                        hasChangeBinding = true;
                    }
                    if (dest != null && dest[k] != v) {
                        hasChangeValue = true;
                    }
                    return v;
                }, (a, dest, i) => {
                    // console.log("---- array=", a, " array dest=", dest, "  i=", i)
                    if (dest == null  || (dest.length>0 && (Object.entries(a[0]).length != Object.entries(dest[0]).length))) {
                        hasChangeBinding = true;
                    }
    
                    return i;
                });
    
            if (hasChangeBinding /*|| hasChangeValue*/ || data.param.action == "reload-json") {
                $xui.modulesManager.replaceModuleState($xui.vuejs.$store, module.nameModule, jsonBinding);
                mustBeReload=true; 
            }
            if (hasChangeBinding) {
                mustBeRevalidate=true;
            }
                 
            console.debug("***************** iframe store reload ", hasChangeBinding, hasChangeValue, module.nameModule, jsonBinding);
    
        });

        if (mustBeReload)  {
            $xui.modulesManager.reload();
        }

    }
    return false; //mustBeRevalidate;
}

function doChangeContent(data) {
    if (data.param.listReloader != null) {
        const uniqReloader = [...new Set(data.param.listReloader)];
        console.info("+++++++++++> changeTemplate : only reloader", data.param);

        for (const idReloader of uniqReloader) {
            if ($xui.listReloader[idReloader] != null)
                $xui.listReloader[idReloader].reload();

            else
                console.error("+-+-+-+-+-+-+-+-+ pb reloader inconnu", idReloader, $xui.listReloader);
        }
    }
    else {
        console.info("+++++++++++> changeTemplate : all loadApplicationJS", data.param);
        let styleXui = document.body.querySelector("#xui-style"); // retire tous le style
        if (styleXui != null) {
            console.debug("+++++++++++>  move style to header");
            styleXui.remove();
            document.head.appendChild(styleXui);
        }

        document.body.innerHTML = data.param.html; // change tous le body

        // const code =  $xui.modulesManager.getCode();    // code avec le code en code
        // eval(code);

        //console.debug("++++++ initialiseAppState +++++>", globalThis.initialiseAppState);

        $xui.loadApplicationJS(true);    // true = ne change pas store
        console.debug("+++++++++++>  post le reloader finish vers le designer");
        const messageOk = {
            action: "reloader finish"
        };
        window.parent.postMessage(messageOk, "*");
    }
}

//******************************************************************************* */

$xui.updateDirectPropInnerText = (event, variable, xid, selectAll) => {
    if (selectAll)
        setTimeout(() => { document.execCommand('selectAll', false, null); }, 300);

    const message = {
        action: "updateDirectProp",
        xid,
        xid_slot: xid,
        variable,
        value: event.target.innerText
    };
    window.parent.postMessage(message, "*");
}

$xui.updateDirectPropBlur = () => {
    window.getSelection().removeAllRanges();
}

// ne sert plus
$xui.updateDirectPropValue = (value, variable, xid) => {
    const message = {
        action: "updateDirectProp",
        xid,
        xid_slot: xid,
        variable,
        value: value.target.value
    };
    window.parent.postMessage(message, "*");
}


//*************************************** POST LES KEYEVENT AU PARENT  ********************************* */
document.addEventListener("keydown", function (event) {
    var listShortCut = [
        { ctrl: true, keyCode: 80, action: "ctrlP" },  // preview
        { ctrl: true, keyCode: 67, action: "ctrlC" },
        { ctrl: true, keyCode: 88, action: "ctrlX" },
        { ctrl: true, keyCode: 86, action: "ctrlV" },
        { ctrl: true, keyCode: 90, action: "ctrlZ" },
        { ctrl: true, keyCode: 89, action: "ctrlY" },
        { ctrl: false, keyCode: 46, action: "delete" },  
        { ctrl: false, keyCode: 8, action: "delete" }   // backSpace
    ];

    //console.debug( event.keyCode );

    for (const shortKey of listShortCut) {
        if (event.ctrlKey == shortKey.ctrl && event.keyCode == shortKey.keyCode) {
            event.preventDefault();
            var message = {
                action: shortKey.action,
            };
            window.parent.postMessage(message, "*");
        }
    }

});