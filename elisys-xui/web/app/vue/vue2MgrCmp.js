export class ComponentManager {

    debug = false;

    static getComponentFromTemplate(idTemplate) {
        const template = document.querySelector(`#${idTemplate}`);
        if (template == null)
            return {
                template: `<div>no template ${idTemplate}</div>`
            };
        else
          {
                return {
                    template: template.innerHTML,
                    mixins: [$xui.mixinStore],
                }
          }
    }

    static getRouteFromTemplate(idPage, idTemplate) {
        const page = document.querySelector(`#${idPage}`);
        const template = page.content.querySelector(`#${idTemplate}`);
        template.remove();
        if (template == null)
            return {
                template: `<div>no template ${idTemplate}</div>`
            };
        else
          {
                return {
                    template: template.innerHTML,
                    mixins: [$xui.mixinStore],
                }
          }
    }

    // static getRoute(path, file, xid) {
    //     return {
    //         path: path, component: () => {
    //             return new Promise((resolve, reject) => {
    //                 console.debug("create route " + path + " to " + xid);
    //                 new vue2CmpMgr.ComponentManager().getVueTemplate(file, xid, 'final',
    //                     (str) => {
    //                         resolve({ template: str });
    //                     }
    //                 );
    //             })
    //         }
    //     }
    // }

    getVueTemplate(file, xid, mode, aPromise) {

        if (window.parent == window) { // test si loader
            window.waitForXuiLib("getHtmlFromXUI", () => {
                if (this.debug) console.debug("getVueTemplate local ", xid)
                const infoFileCmp = { file, xid, mode };
                const prom = getPromise(`getVueCmp${xid}`);
                $xuicore.getHtmlFromXUI(infoFileCmp, `getVueCmp${xid}`);
                prom.then(jsCmp => {
                    if (this.debug) console.debug("returnCmpForFile ", jsCmp)
                    aPromise(jsCmp);
                });
            }, this);

        } else {
            if (this.debug) console.debug("getVueTemplate on parent ", xid)
            const infoFileCmp = { file, xid, mode };
            const message = {
                action: "getCmpForFile",
                infoFileCmp: infoFileCmp
            };
            window.parent.postMessage(message, "*");

            window.addEventListener('message', function (e) {
                const data = e.data;
                if (data.action == `returnCmpForFile_${file}_${xid}`) {
                    if (this.debug) console.debug("returnCmpForFile ", data)
                    aPromise(data.jsCmp);
                }
            }.bind(this));
        }
    }

    //------------------------------------------------------------------
    registerVueComponent(idCmp, file, xid) {

        if (this.debug) console.debug(`create component from import ${idCmp}`);  // voir xui-split-1

        Vue.component(idCmp, (resolve, reject) => {
            this.getVueTemplate(file, xid, "final", (str) => {
                this.initComponentFromImport(str, resolve);
            })
        });

    }

    //------------------------------------------------------------------
    initComponentFromImport(jsCmp, resolve) {
        const dataUri = ComponentManager.esm`${jsCmp}`;
        import(dataUri)
            .then((namespaceObject) => {
                if (this.debug) console.debug("addVueComponent", namespaceObject.default);
                const cmp = {
                    data: function () {
                        return $xui.rootdataComponent;
                    },
                    computed: {
                        $xui: function () {
                            return window.$xui;
                        },
                        ...$xui.computeDataBinding
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