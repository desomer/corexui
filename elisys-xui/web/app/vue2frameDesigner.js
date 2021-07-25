/******************************** Creation du reloader **************************************/
var $xui = window.$xui;  // car module

$xui.listReloader = {};  // liste des reloader   ajouter dans le vue2frameDesigner
$xui.nbRefeshReloader = 0;

$xui.initComponentVuejs.push(() => { //register VueComponent from XUI File
    console.debug("create component v-xui-reloader")
    Vue.component("v-xui-reloader",
        {
            template: '<component v-bind:is="componentToReload"></component>',
            props: ['partid', 'modedisplay'],
            data: () => { return { componentToReload: "", id: 1 }; },
            methods: {
                doChangeComponent: function (e) {

                    var oldId = this.partid + "-" + this.id;
                    //console.debug("doChangeComponent " + oldId + " reponse **************", e);
                    delete Vue.options.components[oldId];

                    this.id++; //passe en composant suivant
                    var newId = this.partid + "-" + this.id;

                    // creation du composant 
                    Vue.component(newId,
                        {
                            template: '<div style="display:' + this.modedisplay + '">' + e.template + '</div>',
                            data: function () {
                                return $xui.rootdata;
                            },
                            computed: {
                                $xui: function () {
                                    return window.$xui;
                                },
                                ...$xui.storeDataBinding
                            },
                            methods: $xui.storeAction
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
                reload: function () {
                    //console.debug("reload **************", this.partid);
                    $xui.nbRefeshReloader++;
                    var message = {
                        action: "get template reloader",
                        xid: this.partid,
                    };
                    window.parent.postMessage(message, "*");
                }
            },
            mounted: function () {
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


document.addEventListener('dragenter', function (e) {
    var slotDroppable = e.target.closest('.xui-class-slot')
    if (slotDroppable) {
        slotDroppable.classList.add("xui-class-dragover");
    }
});

document.addEventListener('dragleave', function (e) {
    var slotDroppable = e.target.closest('.xui-class-slot')
    if (slotDroppable)
        slotDroppable.classList.remove("xui-class-dragover");
});

document.addEventListener('dragover', function (e) {
    var slotDroppable = e.target.closest('.xui-class-slot')
    if (slotDroppable)
        e.preventDefault();
});

document.addEventListener('drop', function (e) {
    var slotDroppable = e.target.closest('.xui-class-slot')
    if (slotDroppable) {
        e.preventDefault();
        var idCmp = e.dataTransfer.getData('text/plain');
        let targetAction = e.target.closest("[data-xid]");
        console.debug("drop ", idCmp, targetAction);
        var message = { action: "drop", ctrlKey: e.ctrlKey, xid: targetAction.dataset.xid, xid_slot: targetAction.dataset.xidSlot };
        window.parent.postMessage(message, "*");
    }
});

// Cet événement détecte n'importe quel drag & drop qui se termine, autant le mettre sur « document » :
document.addEventListener('dragend', function () {
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

    var message = {
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

document.addEventListener('scroll', function (event) {
    var message = {
        action: "unselect",
    };
    window.parent.postMessage(message, "*");
});

window.addEventListener('resize', function (event) {
    var message = {
        action: "unselect",
    };
    window.parent.postMessage(message, "*");
});

//********************************** DISPACH DES EVENTS PROVENANT DU DESIGNER ******************************** */
const iterateJSON = (src, dest, funct, functArray) => {
    const entries = Object.entries(src).map(([key, value]) =>
        Array.isArray(value) ? [key, value.map(e => {
            functArray(value, e);
            var nt = null;
            if (Array.isArray(dest[key])) {
                nt = dest[key][0];
            }
            iterateJSON(e, nt, funct, functArray)
        })]
            : typeof value === 'object'
                ? [key, iterateJSON(value, dest[key], funct, functArray)]
                : [key, funct(key, value, dest)]
    );
    return Object.fromEntries(entries);
};

window.addEventListener('message', function (e) {
    var data = e.data;
    if (data.action!="getInfoForSelector") {
        console.debug("--- CORE --- message ", data);
    }

    if (data.action == "changeTemplate") {

        var hasChangeBinding = false;

        if (data.param.jsonBinding != null) {  // change uniquement le json du template
            //Object.assign($xui.rootdata, data.param.jsonBinding);
            var jsonBinding = data.param.jsonBinding;
            var jsonTemplate = data.param.jsonTemplate;


            // 

            const r = iterateJSON(data.param.jsonTemplate, $xui.rootdata,
                (k, v, dest) => {
                    //console.log("k=", k, " v=", v);
                    //Vue.set($xui.rootdata, k, v);
                    if (dest[k] == null) {
                        hasChangeBinding = true;
                    }
                    return v;
                }, (a, i) => {
                    //console.log("---- array=", a, "  i=", i);
                    return i;
                });

            if (hasChangeBinding) {
                $xui.rootdata = Object.assign({}, $xui.rootdata, data.param.jsonBinding);
            }
            else {
                Object.assign($xui.rootdata, data.param.jsonBinding);
            }

            console.debug("***************** iframe assign data state ", hasChangeBinding, data.param.jsonBinding, $xui.rootdata);
        }

        if (data.param.action == "reload-json") {  
            if (hasChangeBinding)
                data.param.listReloader = null;  // recharge tout
            else
                return;  // change uniquement le json du template
        }


        if (data.param.listReloader != null) {
            var uniqReloader = [...new Set(data.param.listReloader)];
            this.console.info("+++++++++++> changeTemplate event reloader", data.param);

            for (const idReloader of uniqReloader) {
                if ($xui.listReloader[idReloader] != null)
                    $xui.listReloader[idReloader].reload();
                else
                    this.console.error("+-+-+-+-+-+-+-+-+ pb reloader inconnu", idReloader, $xui.listReloader);
            }
        }
        else {
            this.console.info("+++++++++++> changeTemplate event all loadApplicationJS", data.param);
            let styleXui = this.document.body.querySelector("#xui-style");   // retire tous le style
            if (styleXui != null) {
                this.console.debug("+++++++++++>  move style to header")
                styleXui.remove()
                this.document.head.appendChild(styleXui);
            }

            this.document.body.innerHTML = data.param.html; // change tous le body
            $xui.loadApplicationJS();
            this.console.debug("+++++++++++>  post le reloader finish vers le designer")
            var message = {
                action: "reloader finish"
            };
            window.parent.postMessage(message, "*");
        }

    }
    else if (data.action == "doChangeComponent") {
        //console.debug("load reloader", data.xid, data);
        if ($xui.listReloader[data.xid] == null)
            console.error("doChangeComponent on error", data, $xui.listReloader);
        $xui.listReloader[data.xid].doChangeComponent(data);
    }
    else if (data.action == "getInfoForSelector") {

        var ret = $xui.getInfoForSelector(data.selector, data.parent);

        var message = {
            action: "return getInfoForSelector",
            info: data,
            ret: ret
        };

        //console.debug("getInfoForSelector --------------->", message);
        window.parent.postMessage(message, "*");
    }
});

//******************************************************************************* */

$xui.updateDirectPropInnerText = (event, variable, xid, selectAll) => {
    if (selectAll)
        setTimeout(() => { document.execCommand('selectAll', false, null); }, 300);

    var message = {
        action: "updateDirectProp",
        xid: xid,
        xid_slot: xid,
        variable: variable,
        value: event.target.innerText
    };
    window.parent.postMessage(message, "*");
}

$xui.updateDirectPropBlur = () => {
    window.getSelection().removeAllRanges();
}

// ne sert plus
$xui.updateDirectPropValue = (value, variable, xid) => {
    var message = {
        action: "updateDirectProp",
        xid: xid,
        xid_slot: xid,
        variable: variable,
        value: value.target.value
    };
    window.parent.postMessage(message, "*");
}

$xui.getInfoForSelector = (selector, parent) => {
    var targetAction = document.querySelector(selector)
    if (targetAction == null) return null;
    if (parent)
        targetAction = targetAction.parentNode;

    let elemRect = targetAction.getBoundingClientRect();
    let s = getComputedStyle(targetAction);

    let margin = { mb: parseInt(s.marginBottom), mt: parseInt(s.marginTop), ml: parseInt(s.marginLeft), mr: parseInt(s.marginRight) }

    var ret = {
        selector: selector,
        parent: parent,
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