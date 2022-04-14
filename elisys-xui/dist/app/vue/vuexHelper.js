globalThis.$xui.generateApplicationStoreJS = (listState) =>
{

    const modulesManager = new $xui.VuexModuleManager($xui.vuejs);

    for (const bindstate of listState) {
        const jsonState = JSON.parse(`{${bindstate.state}}`);
        modulesManager.addModule(bindstate.namespace, jsonState);

        for (const mth of bindstate.actions) {
            const m = `async (p1, p2) => {\n${mth.code}\n//# sourceURL=${bindstate.namespace}-${mth.name}.js;\n}`;
            modulesManager.modulesDesc[bindstate.namespace].actions[mth.name]=m;
        }
    }

    ret =  modulesManager.getCode();
    //console.debug(">>>>>>>>> generateApplicationStoreJS\n");
    return ret;
}


// globalThis.$xui.getRequireModule = (url, module = {exports:{}}) =>
// {
//     const response = await fetch(url);
//     const script = await response.text();
//     const func = Function("module", "exports", script)
//     func.call(module, module, module.exports);
//     return module.exports;
// }

class VuexModuleManager {

    modulesDesc = {};
    store;
    modules = {};

    constructor(vuejs) {
        this.$vue = vuejs;
    }

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

    replaceModuleState(store, name, state) {
        if (this.modulesDesc[name]==null)
            this.modulesDesc[name] = new VuexModuleDesc(name, state);
        else
            this.modulesDesc[name].state=state;

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
                    if (arguments[1].type=="click") {
                        const elem = arguments[1].target;
                        const targetAction = elem.closest("[data-for-idx]");

                        if (targetAction!=null) {
                            const targetMap = targetAction.closest("[data-for-map]");
                            const forMap = targetMap.dataset.forMap;  // cas du XUI-FOR
                            const forIdx = Number.parseInt(targetAction.dataset.forIdx, 10);
                            $xui.info[forMap]=forIdx;
                        }
                    }

                    if (!$xui.isModeFinal) {
                        const message = {
                            action: "displayMessage",
                            value: {
                                snackbar: true,
                                text: arguments[0],
                                timeout: 2000,
                              }
                        };
                        window.parent.postMessage(message, "*");
                    }

                    if ($xui.actionEnable) {
                        this.$store.dispatch(arguments[0], Array.from(arguments).slice(1), { root: true })
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
        
        result += `const modulesManager = new VuexModuleManager($xui.vuejs);\n\n`;
        let listModule = "";

        for (const [namespace, desc] of Object.entries(this.modulesDesc)) {
            var stateJson = JSON.stringify(desc.state, undefined, 4);
            if (stateJson.length>2) {
                if (namespace=="main")
                {
                    stateJson= stateJson.substring(0, stateJson.length-1);  // retrait de la dernier accolade
                    stateJson+=" , ...$xui.rootdata }";
                }
            }
            else
            {
                stateJson="$xui.rootdata";  // pas de mapping
            }

            result += `const ${namespace} = modulesManager.addModule("${namespace}", ${stateJson});\n\n`;
            listModule += `\n\t\t\t\t\t\t${namespace},`;
        }


        //result += `try {\n`;
          

        for (const [namespace, desc] of Object.entries(this.modulesDesc)) {
            result +=`${namespace}.actions={`;
            for (const [nameAction, code] of Object.entries(desc.actions)) {
            result += `\n  ${nameAction} : ${code},`;
            }
            result +=`}\n\n`;
        }
        //result += `} catch (error) {console.error(error);}\n`;

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
