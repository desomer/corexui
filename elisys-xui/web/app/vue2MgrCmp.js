export class ComponentManager {

    static getComponentFromTemplate(idTemplate, computeDataBinding) {
        const template = document.querySelector("#" + idTemplate);
        if (template == null)
            return {
                template: "<div>no template</div>"
            };
        else
            return {
                template: template.innerHTML,
                data: () => { return $xui.rootdata; },
                methods : $xui.storeAction,
                computed: {
                    $xui: () => $xui,  // pour les @click="$xui.doXXX()"
                    ...computeDataBinding
                }
            }
    }

    static getRoute(path, file, xid) {
        return {
            path: path, component: () => {
                return new Promise((resolve, reject) => {
                    console.debug("create route " + path + " to " + xid);
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

        if (window.parent == window) { // test si loader
            window.waitForXuiLib("getHtmlFromXUI", function () {
                console.debug("getVueTemplate local ", xid)
                var infoFileCmp = { file: file, xid: xid, mode: mode };
                var prom = getPromise("getVueCmp" + xid)
                $xui.getHtmlFromXUI(infoFileCmp, "getVueCmp" + xid);
                prom.then(jsCmp => {
                    console.debug("returnCmpForFile ", jsCmp)
                    aPromise(jsCmp);
                });
            }.bind(this), this);

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

        console.debug("create component from import " + idCmp);  // voir xui-split-1

        Vue.component(idCmp, function (resolve, reject) {
            this.getVueTemplate(file, xid, "final", function (str) {
                this.initComponentFromImport(str, resolve);
            }.bind(this))
        }.bind(this));

    }

    //------------------------------------------------------------------
    initComponentFromImport(jsCmp, resolve) {
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
                        },
                        ...$xui.storeDataBinding
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

}