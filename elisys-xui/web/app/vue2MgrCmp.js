export class ComponentManager {


    getRoute(path, file, xid) {
        return {
            path: path, component: () => {
                return new Promise((resolve, reject) => {
                    console.debug("create route " + path +" to "+xid);
                    new vue2CmpMgr.ComponentManager().getVueTemplate(file, xid, 'final',
                        (str) => {
                            resolve({ template: str });
                        }
                    );
                })
            }
        }
    }

    getVueTemplate(file, xid, mode, aPromise) {

        if (window.parent==window) { // test si loader
            this.waitForGlobal("getHtmlFromXUI", function () {
                console.debug("getVueTemplate local ", xid)
                var infoFileCmp = { file: file, xid: xid, mode: mode };
                var prom = getPromise("getVueCmp"+xid)
                $xui.getHtmlFromXUI(infoFileCmp, "getVueCmp"+xid);
                prom.then(jsCmp => {
                    console.debug("returnCmpForFile ", jsCmp)
                    aPromise(jsCmp);
                });
            }.bind(this));

        } else {
            console.debug("getVueTemplate on parent ", xid)
            var infoFileCmp = { file: file, xid: xid, mode: mode };
            var message = {
                action: "getCmpForFile",
                infoFileCmp: infoFileCmp
            };
            window.parent.postMessage(message, "*");

            window.addEventListener('message', function (e) {
                var data = e.data;
                if (data.action == "returnCmpForFile_" + file + "_" + xid) {
                    console.debug("returnCmpForFile ", data)
                    aPromise(data.jsCmp);
                }
            }.bind(this));
        }
    }

    //------------------------------------------------------------------
    registerVueComponent(idCmp, file, xid) {

        console.debug("init component xui vuejs " + idCmp);

        Vue.component(idCmp, function (resolve, reject) {
            this.getVueTemplate(file, xid, "final", function (str) {
                this.initComponent(str, resolve);
            }.bind(this))
        }.bind(this));

    }
    //------------------------------------------------------------------
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