globalThis.$xui.generateApplicationStoreJS = (state, actions) =>
{

    const jsonState = JSON.parse(`{${state}}`);
    const modulesManager = new $xui.VuexModuleManager();
	const main = modulesManager.addModule("main", jsonState);

    const module = "main";
    for (const mth of actions) {
        console.debug("/*/*/**/*/*/*/*/*/ add mth", mth);
        const m = `(p1, p2) => {\n${mth.code}\n//# sourceURL=${module}-${mth.name}.js;\n}`;
        modulesManager.modulesDesc[module].actions[mth.name]=m;
    }

    return modulesManager.getCode();
}


class VuexModuleManager {

    modulesDesc = {};
    store;
    modules = {};

    setStore(store) {
        this.store = store;
    }

    getStore() {
        return this.store;
    }

    addModule(name, state) {
        this.modulesDesc[name] = new VuexModuleDesc(name, state);
        const aModule = this.modulesDesc[name].module();
        aModule.sync = this.modulesDesc[name].sync.bind(this.modulesDesc[name]);
        aModule.syncArray = this.modulesDesc[name].syncArray.bind(this.modulesDesc[name]);
        aModule.name = name;
        this.modules[name]=aModule;
        return aModule;
    }

    addAction(namespace, name, code)
    {
        this.modulesDesc[namespace].actions[name]=code;
        const fct = eval(code);
        if (this.modules[namespace].actions==null) this.modules[namespace].actions={};
        this.modules[namespace].actions[name]=fct;
    }

    getMixin() {

        const computed = {};

        for (const [namespace, desc] of Object.entries(this.modulesDesc)) {
            computed[namespace] = function () {
                return this.$store.state[namespace];
            }
        }

        return {
            computed,
            methods: {
                $mth() {
                    console.debug("mth", arguments, this);

                    if (arguments[1].type=="click") {
                        let elem = arguments[1].target;
                        const targetAction = elem.closest("[data-for-idx]");
                        //console.debug("targetAction", targetAction);
                        if (targetAction!=null) {
                            const forMap = targetAction.parentElement.dataset.forMap;
                            const forIdx = Number.parseInt(targetAction.dataset.forIdx, 10);
                            $xui.info[forMap]=forIdx;
                        }
                    }



                    const message = {
                        action: "displayMessage",
                        value: {
                            snackbar: true,
                            text: arguments[0],
                            timeout: 2000,
                          }
                    };
                    window.parent.postMessage(message, "*");

                    if ($xui.actionEnable) {
                        this.$store.dispatch(`main/${arguments[0]}`, Array.from(arguments).slice(1), { root: true })
                    }
 
                },
                $post(action, ev) {
                    console.debug("$post", this, action, ev);
                    this.$store.dispatch(action);
                }
            },
        }
    }

    reload() {
        const modules = {}

        const newModules = {};

        for (const [namespace, desc] of Object.entries(this.modules)) {
            newModules[namespace] = desc;
        }

        this.store.hotUpdate({
            modules : newModules
        })

        const newState = {};

        for (const [namespace, desc] of Object.entries(this.modulesDesc)) {
            newState[namespace] = desc.state;
        }

        this.getStore().replaceState(newState);
    }


    getCode() {
        let result = `globalThis.initialiseAppState = () => {\n`;
        
        result += `const modulesManager = new VuexModuleManager();\n\n`;
        let listModule = "";

        for (const [namespace, desc] of Object.entries(this.modulesDesc)) {
            var stateJson = JSON.stringify(desc.state, undefined, 4);
            if (stateJson.length>2) {
                stateJson= stateJson.substring(0, stateJson.length-1);  // retrait de la dernier accolade
                stateJson+=" , ...$xui.rootdata }";
            }
            else
            {
                stateJson="$xui.rootdata";
            }
            result += `const ${namespace} = modulesManager.addModule("${namespace}", ${stateJson});\n\n`;
            listModule += `\n\t\t\t\t\t\t${namespace},`;
        }

        for (const [namespace, desc] of Object.entries(this.modulesDesc)) {
            result +=`${namespace}.actions={`;
            for (const [nameAction, code] of Object.entries(desc.actions)) {
            result += `\n  ${nameAction} : ${code},`;
            }
            result +=`}\n\n`;
        }

        result +=
            `modulesManager.setStore(new Vuex.Store({
                    modules : {${listModule}
                    },
                    plugins : [$xui.logger],
                    strict : true
            }));\n`;
        
        result += `return modulesManager;\n}\n`;
        return this.indentString(result, 8);
    }



    indentString(string, count = 1, options = {}) {
        const {
            indent = ' ',
            includeEmptyLines = false
        } = options;
    
        if (typeof string !== 'string') {
            throw new TypeError(
                `Expected \`input\` to be a \`string\`, got \`${typeof string}\``
            );
        }
    
        if (typeof count !== 'number') {
            throw new TypeError(
                `Expected \`count\` to be a \`number\`, got \`${typeof count}\``
            );
        }
    
        if (count < 0) {
            throw new RangeError(
                `Expected \`count\` to be at least 0, got \`${count}\``
            );
        }
    
        if (typeof indent !== 'string') {
            throw new TypeError(
                `Expected \`options.indent\` to be a \`string\`, got \`${typeof indent}\``
            );
        }
    
        if (count === 0) {
            return string;
        }
    
        const regex = includeEmptyLines ? /^/gm : /^(?!\s*$)/gm;
    
        return string.replace(regex, indent.repeat(count));
    }
}

class VuexModuleDesc {
    namespace;
    state;
    actions = {};

    getField;
    updateField;


    constructor(namespace, state) {
        this.namespace = namespace;
        this.state = state;
        // const { getField, updateField } = globalThis.requireXUI.requireCache('https://cdn.jsdelivr.net/npm/vuex-map-fields@1.4.1/dist/index.min.js');

        // this.getField = getField;
        // this.updateField = updateField;
    }


    module() {
        return {
            namespaced: true,
            state: this.state,
            getters: {
                getField: this.getField,
            },
            mutations: {
                updateField: this.updateField,
                // resetState(state, newState) {
                //     // Merge rather than replace so we don't lose observers
                //     // https://github.com/vuejs/vuex/issues/1118
                //     Object.assign(state, newState)
                // },
            }
        };

    }

    _arrayToObject(fields = []) {
        return fields.reduce((prev, path) => {
            //let key = path.split(`.`).slice(-1)[0];

            let key = path.replaceAll('.', '_')

            if (prev[key]) {
                throw new Error(`The key \`${key}\` is already in use.`);
            }

            prev[key] = path;

            return prev;
        }, {});
    }

    _objectEntries(obj) {
        return Object.keys(obj).map(key => [key, obj[key]]);
    }

    sync(fields) {
        const fieldsObject = Array.isArray(fields) ? this._arrayToObject(fields) : fields;
        const namespace = this.namespace;
        const obj = Object.keys(fieldsObject).reduce((prev, key) => {
            const path = fieldsObject[key];
            const field = {
                get() {
                    return this.$store.getters[`${namespace}/getField`](path);
                },
                set(value) {
                    this.$store.commit(`${namespace}/updateField`, { path, value });
                },
            };

            prev[`${namespace}$_${key}`] = field;

            return prev;
        }, {});

        return obj;
    };


    syncArray(paths) {
        const pathsObject = Array.isArray(paths) ? this._arrayToObject(paths) : paths;
        const namespace = this.namespace;
        const _objectEntries = this._objectEntries;

        const listGetterArray = Object.keys(pathsObject).reduce((entries, key) => {
            const path = pathsObject[key];

            entries[`${namespace}$_${key}`] = {
                get() {
                    const store = this.$store;
                    const rows = _objectEntries(store.getters[`${namespace}/getField`](path));

                    const itemsGetter = rows
                        .map(fieldsObject => Object.keys(fieldsObject[1]).reduce((prev, fieldKey) => {
                            // creation d'un proxy avec l'ensemble des getter 
                            const fieldPath = `${path}[${fieldsObject[0]}].${fieldKey}`;

                            return Object.defineProperty(prev, fieldKey, {
                                get() {
                                    return store.getters[`${namespace}/getField`](fieldPath);
                                },
                                set(value) {
                                    store.commit(`${namespace}/updateField`, { path: fieldPath, value });
                                },
                            });
                        }, {}));
                    return itemsGetter;
                },
            };

            return entries;
        }, {});

        return listGetterArray;
    }
}

$xui.VuexModuleManager=VuexModuleManager;
