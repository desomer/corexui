if (typeof $xui === 'undefined')
    $xui = {};


window.$xui.load = (html) => {
    // console.debug("load", html);
    document.querySelector("#rootFrame").srcdoc = html;
    $xui.loadCode(html);
};

window.$xui.loadCode = (strCode) => {
    var codeElem = document.querySelector("#xui-code-html");
    if (codeElem != null) {
        const code = Prism.highlight(strCode, Prism.languages.html, 'html');
        codeElem.innerHTML = code;
    }
}

window.$xui.changeTemplate = (param) => {
    console.debug("change template", param);
    if (param.mode == "template") {
        document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "changeTemplate", "template": param.html }, "*");
    }

    $xui.loadCode(param.html);
};

window.$xui.save = () => {
    console.debug("save", $xui.propertiesDesign.json);
    $xui.setDesignProperties("save", $xui.propertiesDesign.json);
}

window.$xui.fullScreen = () => {
    window.document.documentElement.requestFullscreen();
}


window.addEventListener('message', function (e) {
    var data = e.data;
    if (data.action == "select") {
        //  var info = $xui.getInfo(data.xid, data.xid_slot);
        $xui.displayProperties(data.xid, data.xid_slot);
    }
});

$xui.displayProperties = (xid, xid_slot) => {
    $xui.propertiesDesign = $xui.getDesignProperties(xid, xid_slot);
    console.debug($xui.propertiesDesign);
    $xui.rootdata.selectedxui = $xui.propertiesDesign.path;
    $xui.propertiesDesign.json = JSON.parse($xui.propertiesDesign.data);
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
