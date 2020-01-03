if (typeof $xui === 'undefined')
    $xui = {};


window.$xui.load = (html) => {
    // console.debug("load", html);
    document.querySelector("#rootFrame").srcdoc = html;
    $xui.loadCode(html);
    $xui.displayComponents("", "");
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

window.$xui.addCmp = (cmp) => {
    console.debug(cmp, $xui.propertiesComponent);
    $xui.addDesign($xui.propertiesComponent.xid, "<xui-design><"+cmp.text+" xid=\""+($xui.propertiesComponent.xid+"-"+cmp.text)+"\"></"+cmp.text+"></xui-design>")
}

window.$xui.dragStart = (item, e)=> {
    $xui.dragItem = item;
    e.dataTransfer.setData('text/plain', ""+item.text);
}

window.addEventListener('message', function (e) {
    var data = e.data;
    if (data.action == "select") {
        //  var info = $xui.getInfo(data.xid, data.xid_slot);
        $xui.displayProperties(data.xid, data.xid_slot);
    }
    if (data.action == "drop") {
        $xui.displayProperties(data.xid, data.xid_slot);
        $xui.displayComponents(data.xid, data.xid_slot);
        $xui.addCmp( $xui.dragItem);
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

$xui.displayComponents = (xid, xid_slot) => {
    $xui.propertiesComponent = $xui.getComponents(xid, xid_slot);
    console.debug($xui.propertiesComponent);
    $xui.propertiesComponent.json = JSON.parse($xui.propertiesComponent.data);
    $xui.rootDataComponents = { data: $xui.propertiesComponent.json, item:null };
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