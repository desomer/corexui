if (typeof window.$xui === 'undefined')
    window.$xui = {};

window.$xui.isModePreview = false;

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
        $xui.displaySelector(data.position);
        setTimeout(() => { $xui.displayPropertiesJS(data.xid, data.xid_slot); }, 100);
    }
    if (data.action == "drop") {
        $xui.displayPropertiesJS(data.xid, data.xid_slot);
        $xui.displayComponents(data.xid, data.xid_slot);
        $xui.addCmp($xui.dragItem);
    }
    if (data.action == "ctrlQ")
    {
        $xui.modePreview();
    }
});

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
        $xui.loadCode(param.html);
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

$xui.save = () => {
    console.debug("save", $xui.propertiesDesign.json);
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
    $xui.setDesignProperties(infoFile, "save", $xui.propertiesDesign.json);
}

$xui.fullScreen = () => {
    window.$xui.unDisplaySelector();
    window.document.documentElement.requestFullscreen();
}

$xui.addCmp = (cmp) => {
    window.$xui.unDisplaySelector();
    console.debug("addCmp", cmp, $xui.propertiesComponent);
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
    $xui.addDesign(infoFile, $xui.propertiesComponent.xid, "<xui-design xid=" + $xui.propertiesComponent.xid + "><" + cmp.xid + " xid=\"" + ($xui.propertiesComponent.xid + "-" + cmp.xid) + "\"></" + cmp.xid + "></xui-design>");
}

$xui.deleteCmp = () => {
    window.$xui.unDisplaySelector();
    console.debug("deleteCmp", $xui.propertiesDesign);
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
    $xui.removeDesign(infoFile, $xui.propertiesDesign.xid);
}

$xui.moveTo = () => {
    window.$xui.unDisplaySelector();
    console.debug("moveToCmp", $xui.propertiesDesign);
    var infoFile = { file: 'app/frame1.html', xid: 'root', mode: 'template' };
    var info = $xui.getInfo(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    $xui.moveDesign(infoFile, null, info.xid);
}

// selection par click des properties
$xui.selectCmp = (xid, xid_slot) => {
    $xui.unDisplaySelector();
    var node = document.querySelector("#rootFrame").contentDocument.querySelector("[data-xid=" + xid + "]")
    let elemRect = node.getBoundingClientRect();
    $xui.displaySelector(elemRect);
    setTimeout(() => { $xui.displayPropertiesJS(xid, xid_slot); }, 100);
}

$xui.dragStart = (item, e) => {
    $xui.dragItem = item;
    e.dataTransfer.setData('text/plain', "" + item.xid);
    $xui.unDisplaySelector();
}

/******************************************************************/

$xui.unDisplaySelector = () => {
    var node = document.getElementById("xui-display-selector");
    if (node != null) {
        node.style.display = "none";
    }
};

$xui.displaySelector = (position) => {

    var node = document.getElementById("xui-display-selector");
    if (node == null) {
        node = document.createElement("div");
        node.id = "xui-display-selector";
        node.classList.add("xui-style-selector");
        node.addEventListener("click", (e) => {
            e.currentTarget.style.display = "none";   // retire sur le click
        }, { capture: false })

        var nodeAction = document.createElement("div");
        nodeAction.id = "xui-display-selector-action";
        node.appendChild(nodeAction);

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

    if (monWorker != null)
        monWorker.postMessage([param]);

    var info = $xui.getInfo(infoFile, xid, xid_slot);
    this.console.debug("select ", info);

    $xui.propertiesDesign = $xui.getDesignProperties(infoFile, xid, xid_slot);
}

$xui.loadPropertiesJS = (prop) => {
    $xui.propertiesDesign = prop;
    //console.debug("displayProperties", $xui.propertiesDesign);
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
        computed: {
            $xui: function () {
                return window.$xui;
            }
        }
    });
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
    $xui.getHtmlFrom(infoFile, "callHtml");
}

$xui.callHtml = (html) => {
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
}

$xui.modePreview = () => {
    $xui.isModePreview = !$xui.isModePreview;
    document.querySelector("#rootFrame").classList.toggle("xui-frame-full-screen");
    $xui.refreshAction($xui.isModePreview ? "preview" : "design");
}