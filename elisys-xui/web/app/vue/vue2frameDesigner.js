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
                    //console.debug("doChangeComponent " + oldId + " reponse **************", e);
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
                        //console.debug("nbRefeshReloader ", $xui.nbRefeshReloader);
                        if ($xui.nbRefeshReloader == 0) {
                            var message = {
                                action: "reloader finish",
                            };
                            window.parent.postMessage(message, "*");
                        }
                    });
                },
                reload() {
                    //console.debug("reload **************", this.partid);
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

document.addEventListener('pointerup', function (e) {
    //console.debug("pointerup", e);
    if (e.button != 0)
        return;

    let targetAction = e.target.closest("[data-xid]");
    if ($xui.targetActionStart != targetAction)
        return;  // ne fait rien sur le drag si drag sur le même composant  (ex : Split)

    let elemRect = targetAction.getBoundingClientRect();
    let s = getComputedStyle(targetAction);
    let margin = { mb: parseInt(s.marginBottom), mt: parseInt(s.marginTop), ml: parseInt(s.marginLeft), mr: parseInt(s.marginRight) }

    const message = {
        action: "select",
        xid: targetAction.dataset.xid,
        xid_slot: targetAction.dataset.xidSlot,
        position: {
            hasMargin: (margin.mb > 0 || margin.mt > 0 || margin.ml > 0 || margin.mr > 0),
            height: elemRect.height,
            width: elemRect.width,
            left: elemRect.left,
            top: elemRect.top,
            ...margin
        },
    };
    //console.debug("***********message", message, targetAction, targetActionStart);
    window.parent.postMessage(message, "*");
});

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
    const entry = Object.entries(src);
    const entries = entry.map(([key, value]) =>
        Array.isArray(value) ? [key, value.map(e => {
            var nt = null;
            if (Array.isArray(dest[key])) {
                nt = dest[key][value.indexOf(e)];
            }
            functArray(value, dest[key], e);
            iterateJSON(e, nt, funct, functArray)
        })]
            : typeof value === 'object'
                ? [key, iterateJSON(value, dest[key], funct, functArray)]
                : [key, funct(key, value, dest)]
    );
    return Object.fromEntries(entries);
};



window.addEventListener('message', (e) => {
    const data = e.data;
    if (data.action != "getInfoForSelector") {
        console.debug("--- CORE --- message ", data);
    }

    switch (data.action) {

        case "changeJS":
            console.debug("changeJS ", data, $xui.modulesManager);
            const module = "main";
            for (const mth of data.param.actions) {
                const m = `(p1, p2) => {\n${mth.code}\n};`;
                $xui.modulesManager.addAction(module, mth.name, `${m}\n//# sourceURL=${module}-${mth.name}.js;`);
            }
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
            let hasChangeBinding = false;
            let hasChangeValue = false;

            if (/*data.param.action == "reload-json" && data.param.listReloader == null &&*/ data.param.jsonBinding != null) {
                var jsonBinding = data.param.jsonBinding;
                var jsonTemplate = data.param.jsonTemplate;

                iterateJSON( jsonBinding, $xui.rootdata,
                    (k, v, dest) => {
                        //console.log("k=", k, " v=", v);
                        if (dest == null || dest[k] == null) {
                            hasChangeBinding = true;
                        }
                        if (dest != null && dest[k] != v) {
                            hasChangeValue = true;
                        }
                        return v;
                    }, (a, dest, i) => {
                        // console.log("---- array=", a, " array dest=", dest, "  i=", i);
                        if (dest == null) {
                            hasChangeBinding = true;
                        }
                        else {
                            if (Object.entries(a[0]).length != Object.entries(dest[0]).length)
                            {
                                hasChangeBinding = true;
                            }
                        }
                        return i;
                    });

                if (hasChangeBinding || hasChangeValue || data.param.action == "reload-json") {
                    $xui.rootdata = jsonBinding;
                    $xui.modulesManager.addModule("main", $xui.rootdata);
                    $xui.modulesManager.reload();
                }
                console.debug("***************** iframe store reload ", hasChangeBinding, hasChangeValue, data.param.jsonBinding);
            }

            if (data.param.action == "reload-json") {
                if (hasChangeBinding)
                    data.param.listReloader = null;  // recharge tout
                else
                    return;  // change uniquement le json du template
            }

            const oldrouteEnable = $xui.routeEnable;
            $xui.routeEnable = true;  // autorise le positionnements des routes durant les reloads

            doChangeContent(data);

            $xui.routeEnable = oldrouteEnable;

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
        $xui.loadApplicationJS();
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

$xui.getInfoForSelector = (selector, parent) => {
    let targetAction = document.querySelector(selector);
    if (targetAction == null) return null;
    if (parent)
        targetAction = targetAction.parentNode;

    let elemRect = targetAction.getBoundingClientRect();
    let s = getComputedStyle(targetAction);

    let margin = { mb: parseInt(s.marginBottom), mt: parseInt(s.marginTop), ml: parseInt(s.marginLeft), mr: parseInt(s.marginRight) }

    const ret = {
        selector,
        parent,
        hasMargin: (margin.mb > 0 || margin.mt > 0 || margin.ml > 0 || margin.mr > 0),
        height: elemRect.height,
        width: elemRect.width,
        left: elemRect.left,
        top: elemRect.top,
        ...margin
    };

    return ret;
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