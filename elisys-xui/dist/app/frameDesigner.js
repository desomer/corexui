//    editor en vuejs  : https://codepen.io/NicolasLrnd/pen/XPdxKv

if (typeof window.$xui === 'undefined')
    window.$xui = {};

$xui.isModePreview = false; 
$xui.modeDisplaySelection = false;

var workerEnable = false;
var monWorker = null;

if (workerEnable) {
    monWorker = new Worker('./libxuiworker.js');

    monWorker.onmessage = function (e) {
        console.log('Message depuis le worker', e);
    }
}

document.addEventListener("keydown", function (event) {

    if (event.ctrlKey && event.keyCode == 81) {
        event.stopPropagation();
        event.preventDefault();
        $xui.modePreview();
    }

});


window.addEventListener('message', function (e) {
    var data = e.data;
    if (data.action == "select") {
        $xui.displaySelectorByPosition(data.position);
        $xui.modeDisplaySelection = true;
        setTimeout(() => { $xui.displayPropertiesJS(data.xid, data.xid_slot); }, 100);
    }
    if (data.action == "drop") {
        if ($xui.dragItem != null) {
            // gestion drag de nouveau component
            $xui.displayPropertiesJS(data.xid, data.xid_slot);
            $xui.displayComponents(data.xid, data.xid_slot);
            $xui.addCmp($xui.dragItem);
        }
        if ($xui.dragMoveItem != null) {
            // gestion de drag entre slot
            if ($xui.deleteCmp()) {
                $xui.displayPropertiesJS(data.xid, data.xid_slot);

                setTimeout(() => {   // todo gestion par promise
                    $xui.moveTo();
                }, 100);
            }
        }
    }
    if (data.action == "ctrlQ") {
        $xui.modePreview();
    }

    if (data.action == "updateDirectProp")
    {
        $xui.unDisplaySelector();
        $xui.updateDirectProperty(data.value, data.variable, data.xid);
    }
});

/******************************************************************************** */

$xui.loadPageJS = (html) => {
    // console.debug("load", html);
    document.querySelector("#rootFrame").srcdoc = html;

    $xui.codeHtml = html;
    setTimeout(() => {
        $xui.displayComponents("", "");
        $xui.displayPropertiesJS("root", "root")
    }, 100);
};

$xui.changePageJS = (param) => {
    console.debug("change page", param);

    $xui.unDisplaySelector();

    if (param.mode == "template") {
        // change uniquement template de la page  
        document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "changeTemplate", "template": param.html }, "*");
    }
    else if (param.mode == "preview") {
        document.querySelector("#rootFrame").srcdoc = param.html;
    }
    else if (param.mode == "design") {
        document.querySelector("#rootFrame").srcdoc = param.html;
    }

    $xui.codeHtml = param.html;
    if ($xui.rootdata.activeTab == 1)
        $xui.loadCode(param.html);   // affiche le code du mode (template, preview, final )

};

$xui.refreshAction = (mode) => {
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: mode };
    $xui.refresh(infoFile);
};

$xui.loadCode = (strCode) => {
    $xui.unDisplaySelector();
    var codeElem = document.querySelector("#xui-code-html");
    if (codeElem != null) {
        const code = Prism.highlight(strCode, Prism.languages.html, 'html');
        codeElem.innerHTML = code;
    }
}

$xui.loadCodeYamlJS = (strCode) => {
    $xui.unDisplaySelector();
    setTimeout(() => {
        var codeElem = document.querySelector("#xui-code-yaml");
        if (codeElem != null) {
            const code = Prism.highlight(strCode, Prism.languages.yaml, 'yaml');
            codeElem.innerHTML = code;
        }
    }, 1000);
}

$xui.fullScreen = () => {
    window.$xui.unDisplaySelector();
    window.document.documentElement.requestFullscreen();
}

/************************************************************************** */
$xui.addCmp = (cmp) => {
    window.$xui.unDisplaySelector();
    console.debug("addCmp", cmp, $xui.propertiesComponent);
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
    $xui.addDesign(infoFile, $xui.propertiesComponent.xid, "<xui-design xid=" + $xui.propertiesComponent.xid + "><" + cmp.xid + " xid=\"" + $xui.getNewXid($xui.propertiesComponent, cmp) + "\"></" + cmp.xid + "></xui-design>");
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
    window.$xui.unDisplaySelector();
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
    window.$xui.unDisplaySelector();
    console.debug("moveToCmp", $xui.propertiesDesign);
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
    var info = $xui.getInfo(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    $xui.moveDesign(infoFile, null, info.xid);
}

//********************************************************************************************/

// selection par click des properties
$xui.displaySelectorByXid = (xid, xid_slot, noSelect) => {
    $xui.unDisplaySelector();

    // recherche xid simple
    var node = document.querySelector("#rootFrame").contentDocument.querySelector("[data-xid=" + xid + "]")
    if (node != null) {
        let elemRect = node.getBoundingClientRect();
        $xui.displaySelector(elemRect);
    }

    // recherche xid de slot invisible sur les div parentes
    if (node == null) {
        node = document.querySelector("#rootFrame").contentDocument.querySelector("[data-xid-slot-" + xid + "=true]")
        if (node != null) {
            let elemRect = node.getBoundingClientRect();
            $xui.displaySelector(elemRect);
        }
    }

    // recherche xid de slot invisible sur les div enfant => realise un merge des clientRect
    if (node == null) {
        var listNode = document.querySelector("#rootFrame").contentDocument.querySelectorAll("[data-xid-slot=" + xid + "]")
        if (listNode != null && listNode.length > 0) {
            // gestion des d'intersection des region des enfants
            var myRegion = null;
            for (const aNode of listNode) {
                let elemRect = aNode.getBoundingClientRect();
                if (myRegion == null)
                    myRegion = new Region2D(elemRect);
                else
                    myRegion = myRegion.union(new Region2D(elemRect));
            }

            $xui.displaySelector(myRegion.getBounds());
        }
    }

    if (!noSelect)
    {
        $xui.modeDisplaySelection = true;
        setTimeout(() => { $xui.displayPropertiesJS(xid, xid_slot); }, 100);
    }
}

$xui.dragStart = (item, e) => {
    $xui.dragItem = item;
    $xui.dragMoveItem = null;
    e.dataTransfer.setData('text/plain', "add cmp " + item.xid);
    $xui.unDisplaySelector();
}

$xui.dragMoveStart = (e) => {
    $xui.dragMoveItem = $xui.propertiesDesign;
    $xui.dragItem = null;
    e.dataTransfer.setData('text/plain', "move " + $xui.propertiesDesign.xid);
}

/******************************************************************/

$xui.unDisplaySelector = () => {
    var node = document.getElementById("xui-display-selector");
    if (node != null) {
        node.style.display = "none";
    }
};

$xui.displaySelector = (position) => {

    if ($xui.hasPropertiesChanged) {
        $xui.saveProperties().then( () =>
            {
                console.debug("auto save ok");
                if ($xui.modeDisplaySelection)
                {
                    console.debug("reselect ", $xui.propertiesDesign);
                    setTimeout( () => {   // attente prise en compte par l'iFrame
                        $xui.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot, true);
                    }, 500);
                }
            }
        )
    }

    var node = document.getElementById("xui-display-selector");
    if (node == null) {
        node = document.createElement("div");
        node.id = "xui-display-selector";
        node.classList.add("xui-style-selector");
        node.addEventListener("click", (e) => {
            e.currentTarget.style.display = "none";   // retire sur le click
            $xui.modeDisplaySelection = false;
        }, { capture: false })

        var nodeAction = document.createElement("div");
        nodeAction.id = "xui-display-selector-action";
        node.appendChild(nodeAction);
        node.setAttribute("draggable", true);

        node.addEventListener("dragstart", function (event) { $xui.dragMoveStart(event); }, false);

        document.body.appendChild(node);
    }

    var posFrame = rootFrame.getBoundingClientRect();
    node.style.height = position.height + "px";
    node.style.left = (position.left + posFrame.left) + "px";
    node.style.top = (position.top + posFrame.top) + "px";
    node.style.width = position.width + "px";
    node.style.display = null;   //affiche la div de selection

    $xui.rootdata.activeAction = 0;

    $xui.displayAction($xui.propertiesDesign.xid, null);

}

$xui.displayPropertiesJS = (xid, xid_slot) => {
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };

    var param = { infoFile: infoFile, xid: xid, xid_slot: xid_slot };

    // gestion en thread
    if (monWorker != null)
        monWorker.postMessage([param]);

    var info = $xui.getInfo(infoFile, xid, xid_slot);
    this.console.debug("select displayPropertiesJS ", info);

    $xui.getDesignProperties(infoFile, xid, xid_slot);
    // todo 
            //gerer .then($xui.loadPropertiesJS())

}

$xui.loadPropertiesJS = (prop) => {
    $xui.hasPropertiesChanged = false;
    $xui.propertiesDesign = prop;
    console.debug("loadPropertiesJS", $xui.propertiesDesign);
    $xui.rootdata.selectedxui = $xui.propertiesDesign.path;
    $xui.propertiesDesign.json = $xui.parseJson($xui.propertiesDesign.data);
    $xui.rootDataProperties = { data: $xui.propertiesDesign.json };

    if ($xui.vuejsDesign != null) {
        $xui.vuejsAppPropertiesSetting.$destroy();
    }
    $xui.vuejsAppPropertiesSetting = new Vue({
        template: "<div class='barcustom' id='AppPropertiesSetting' style='overflow-y: scroll; height: calc(100% - 38px);'>" + $xui.propertiesDesign.template + "</div>",
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
                var listOver = document.querySelectorAll(".xui-over-prop-xid");
                $xui.last=null;
                listOver.forEach((aDivOver) => {
                    aDivOver.style.border = "1px solid #bdbdbd";
                    aDivOver.addEventListener('mouseover', () => {
                        aDivOver.style.border = "1px solid #202020";
                        if ($xui.last!=aDivOver.id)  {
                            $xui.last=aDivOver.id;
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
}

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

    if (id!=null)
        dicoPromise[id]=promise;
    return promise;
}

$xui.saveProperties = () => {
    console.debug("saveProperties", $xui.propertiesDesign.json);
    $xui.hasPropertiesChanged = false;
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
    var prom = getPromise("designPromise");
    $xui.setDesignProperties(infoFile, "save", $xui.propertiesDesign.json, "designPromise");
    prom.then(xidProp => { 
        console.debug("saveProperties ok",  xidProp);
        $xui.displayPropertiesJS(xidProp, xidProp);   // reaffecte le nouveau mapping
     });
    return prom;
}

$xui.parseJson = (str) => {
    try {
        return JSON.parse(str);
    } catch (error) {
        console.debug("pb parse json", error, str);
    }
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
        template: "<div class='barcustom' id='AppComponents' style='overflow-y: scroll; height: calc(100% - 38px);'>" + $xui.propertiesComponent.template + "</div>",
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

$xui.modePreview = () => {
    $xui.isModePreview = !$xui.isModePreview;
    document.querySelector("#rootFrame").classList.toggle("xui-frame-full-screen");
    $xui.refreshAction($xui.isModePreview ? "preview" : "design");
}

$xui.modePhone = () => {
    document.querySelector("#rootFrame").classList.toggle("iframe-phone");
}

$xui.updateDirectProperty = (value, variable, xid) => {
    console.debug("updateDirectProperty", value, variable, xid, $xui.rootDataProperties);
    for (const aProp of $xui.rootDataProperties.data) {
        if (aProp.xid==xid && aProp.variable==variable)
        {
            aProp.value=value;
        }
    }
}

$xui.doPromise = (idPromise, ret) => {
    dicoPromise[idPromise].resolve_ex(ret);
}