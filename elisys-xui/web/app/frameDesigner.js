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
    console.debug("save")
}

window.addEventListener('message', function (e) {
    var data = e.data;
    if (data.action == "select") {
        var info = $xui.getInfo(data.xid, data.xid_slot);
        $xui.propertiesDesign = $xui.getDesignProperties(data.xid, data.xid_slot);
        console.debug(data, info, $xui.propertiesDesign);
        // $xui.rootdata.selectedxui=$xui.info.xid + " > " + $xui.info.docId + " > " + $xui.info.slotname ;
        $xui.rootdata.selectedxui = $xui.propertiesDesign.data;

        var i = 0;
        var dataProp = [{ label: info.slotname, value: true }];
        template = "<v-switch dense class='ma-2' hide-details inset :label='data[" + i + "].label' v-model='data[" + i + "].value'></v-switch>";

        $xui.rootDataProperties = { data: dataProp };
        if ($xui.vuejsDesign != null) {
            $xui.vuejsAppPropertiesSetting.$destroy();
        }

        $xui.vuejsAppPropertiesSetting = new Vue(
            {
                template: "<div class='barcustom' id='AppPropertiesSetting' style='overflow-y: scroll; height: calc(100% - 50px);'>" + template + "</div>",
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
});