export class ComponentManager {

    registerVueComponent(idCmp, file, xid) {

        console.debug("init component vuejs " + idCmp);

        Vue.component(idCmp, function (resolve, reject) {

            if ($xui.rootdata.isDesignFrame) {

                this.waitForGlobal("getHtmlFrom", function () {

                    var infoFileCmp = { file: file, xid: xid, mode: 'final' };
                    var prom = getPromise("getVueCmp")
                    $xui.getHtmlFrom(infoFileCmp, "getVueCmp");
                    prom.then(jsCmp => {

                        this.initComponent(jsCmp, resolve);

                    });
                }.bind(this));
            }
            else
            {
                var infoFileCmp = { file: file, xid: xid, mode: 'final' };
                var message = {
                    action: "getCmpForFile",
                    infoFileCmp : infoFileCmp
                };
                window.parent.postMessage(message, "*");

                window.addEventListener('message', function (e) {
                    var data = e.data;
                    if (data.action == "returnCmpForFile_"+file+"_"+xid) {
                        //console.debug("returnCmpForFile ", data)
                        this.initComponent(data.jsCmp, resolve);
                    }
                }.bind(this));
            }
        }.bind(this))

    }

    initComponent(jsCmp, resolve) {
        const dataUri = ComponentManager.esm`${jsCmp}`;
        import(dataUri)
            .then((namespaceObject) => {
                console.debug("addVueComponent", namespaceObject.default);
                var cmp = {
                    data: function () {
                        return $xui.rootdata;
                    },
                    computed: {
                        $xui: function () {
                            return window.$xui;
                        }
                    },
                    ...namespaceObject.default
                };
                resolve(cmp);
            });
    }

    /*******************************************************************/

    static esm(templateStrings, ...substitutions) {
        let js = templateStrings.raw[0];
        for (let i = 0; i < substitutions.length; i++) {
            js += substitutions[i] + templateStrings.raw[i + 1];
        }
        return 'data:text/javascript;base64,' + btoa(js);
    }

    waitForGlobal(key, callback) {
        if ($xui[key] != null) {
            callback();
        } else {
            setTimeout(function () { this.waitForGlobal(key, callback); }.bind(this), 100);
        }
    };

}