export class PageDesignManager {

    codeHtml = null;
    codeXUIdata = null;
    codeXUI = null;


    getInfoFile(mode) {

        let rootdata = $xui.rootdata;
        if ($xui.getAppState!=null)
            rootdata = $xui.getAppState().main;

        return {
            fileID: rootdata.frameName,
            file: `app/${rootdata.frameTemplate}.html`,
            xid: 'root',
            mode
        };
    }


    getPageId() {
        const rootdata = $xui.getAppState().main;
        return rootdata.frameName;
    }

    /** premier chargement de la page en full */
    loadPage(html, option) {
        const rootdata = $xui.getAppState().main;
        if (rootdata.isModePhone) {
            document.querySelector("#rootFrame").classList.remove("xui-iframe-phone");
        }
        document.querySelector("#rootFrame").style.display = 'none';
        document.querySelector("#rootFrame").srcdoc = html;
        rootdata.routeEnable = true;
        rootdata.actionEnable = true;
        $xui.saveStoreNamespace="";

        this.codeHtml = html;

        const promOnPageReady = getPromise("OnPageReady");

        promOnPageReady.then(()=> { 
            $xui.displayComponents("", "");
            $xui.displayPropertiesJS("page-0-route-0-content-slot", "page-0-route-0-content-slot");
        });

        if (option != null) {
            rootdata.listSlot.length = 0;
            rootdata.listSlot.push(...option.treeSlot);
            promOnPageReady.then(()=> { 
                this.initConfigApp(option); 
                rootdata.overlayEvent=true;
                rootdata.overlay=false;
                document.querySelector("#rootFrame").style.display = null;
            });
        }

        // activation des button undo et redo
        const name = this.getPageId();
        const version = localStorage.getItem(`xui_version_${name}`);
        if (version != null) {
            rootdata.undoDisabled = false;
            const versionMax = localStorage.getItem(`xui_version_max_${name}`);
            if (versionMax != null && parseInt(versionMax) > parseInt(version)) {
                rootdata.redoDisabled = false;
            }
        }

        if (option.action=="reloaderDisable")
        {
            setTimeout(() => {
                doPromiseJS("OnPageReady");
            }, 1000);
        }
    }


    initConfigApp(option) {
        const rootdata = $xui.getAppState().main;
        if (option.appConfig != null && option.appConfig != "") {
            const appConfig = JSON.parse(option.appConfig); 
            if (appConfig.isModePhone) {
                $xui.modePhone();
            }
            
            rootdata.stateDataSource = appConfig.dataSrc;
            rootdata.routeEnable = appConfig.routeEnable;
            rootdata.actionEnable = appConfig.actionEnable;
        }
        else
        {
            rootdata.stateDataSource = "template";
            rootdata.routeEnable = true;
            rootdata.actionEnable = true;
        }
    }

    changePageOnFrame(param) {
        const rootdata = $xui.getAppState().main;
        const rootStore = $xui.getAppState().store;
        $xui.SelectorManager.unDisplaySelector();

        const jsonListStateModule = [];

        for (let i = 0; i < rootStore.listStoreModule.length; i++) {
            const module=rootStore.listStoreModule[i];
            const stateModule = {}; 
            stateModule.stateData = rootdata.stateDataSource == "mock" ? module.stateDataMock : module.stateData;
            stateModule.nameModule = module.nameModule;
            jsonListStateModule.push(stateModule);
        }

        param.jsonListStateModule=jsonListStateModule;

        if (param.mode == "template") {
            console.debug(`************** changeTemplate ************** ${rootdata.stateDataSource}`,  param.jsonListStateModule );
            // change uniquement template de la page aprés le demarrage en mode design et les reloader
            document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "changeTemplate", "param": param }, "*");
        }
        else if (param.mode == "preview") {
            document.querySelector("#rootFrame").srcdoc = param.html;
        }
        else if (param.mode == "design") {
            // mode de demarrage
            document.querySelector("#rootFrame").srcdoc = param.html;

        } else if (param.mode == "final") {
            // ne fait rien a part afficher le code
        }

        this.codeHtml = param.html;
        this.codeXUIdata = param.xuidata;
        this.codeXUI = param.xuifile;

        rootdata.listSlot.length = 0;
        rootdata.listSlot.push(...param.treeSlot);

        if (param.action == "export") {
            this.export();
        }

        if (param.action == "clear") {
            doPromiseJS("AfterChangeSelectByXid");
        }

        if (param.action != "showCode" && param.action != "reload-json" && param.action != "reload" && param.action != "clear" && param.action != "export")
        {
            console.debug("save cause", param);
            this.store(); // save un nouvelle version
        }

        if ($xui.doStoreOnNextReload) {
            this.store(); // save un nouvelle version
            $xui.doStoreOnNextReload=false;
            setTimeout(() => {
                $xui.displayPropertiesJS("root", "root");   // reaffecte le nouveau mapping sur la page
            }, 500);
        }

        if (rootdata.idxTabMain == $xui.MainTabEnum.CODE)  // si onglet 2 actif
        {
            this.loadCode();   // affiche le code du mode (template, preview, final )
            this.loadCodeXUI();
            this.loadCodeJson();
        }

    }

    async export() {
        const q = faunadb.query;
        const client = new faunadb.Client({ secret: 'fnADgqwCPfACAEWJ2wy7Kb5jrUIN5aa4t93DOl1a' });
        const rootdata = $xui.getAppState().main;

        // client.query(
        // q.Get(q.Ref(q.Collection('Filexui'), '252953488011559426'))
        // )
        // .then((ret) => console.log(ret))


        // client.query(
        // q.Create(
        //     q.Collection('Filexui'),
        //     { data: { id: 2, html:"super" } },
        // )
        // )
        // .then((ret) => console.log(ret))

        // client.query(
        //     q.Get(
        //         q.Match(q.Index('all_filexui'))
        //     )
        //     )
        //     .then((ret) => console.log(ret))

        let ret = null;
         
        try {
            ret=  await client.query(
                q.Get(
                    q.Match(q.Index('filexuiById'), rootdata.frameName)
                )
            )
        } catch (error) {
            console.log("ret error =", error);
            if (error.requestResult.statusCode==404)
            {
                ret= await client.query(
                    q.Create(
                        q.Collection('Filexui'),
                        { data: { id: rootdata.frameName, html:"new" } },
                    )
                    )
            }
        }

 

        console.log("ret db =", ret);

        ret = await client.query(
            q.Update(
                ret.ref,
                { data: { html: $xui.pageDesignManager.codeHtml } },
            )
        )

        console.log("re save=", ret);
        rootdata.snackbar_text = "deploy terminated";
        rootdata.snackbar_timeout = 2000;
        rootdata.snackbar = true;
    }

    store() {
        const name = this.getPageId();
        let version = localStorage.getItem(`xui_version_${name}`);
        if (version == null)
            version = "0";
        let ver = parseInt(version);

        let versionMin = localStorage.getItem(`xui_version_min_${name}`);
        if (versionMin == null)
            versionMin = "0";
        let verMin = parseInt(versionMin);

        localStorage.setItem(`xui_data_${name}_${ver}`, this.codeXUIdata);
        ver++;
        localStorage.setItem(`xui_version_${name}`, `${ver}`);
        localStorage.setItem(`xui_version_max_${name}`, `${ver}`);

        if (ver > verMin + 20 )
        {
            localStorage.removeItem(`xui_data_${name}_${verMin}`);
            verMin++;
            localStorage.setItem(`xui_version_min_${name}`, `${verMin}`);
        }

        const rootdata = $xui.getAppState().main;
        rootdata.redoDisabled = true;
        rootdata.undoDisabled = false;
    }

    loadCode() {
        const codeElem = document.querySelector("#xui-code-html");
        if (codeElem != null) {
            const code = Prism.highlight(this.codeHtml, Prism.languages.html, 'html');
            codeElem.innerHTML = code;
        }
    }

    loadCodeJson() {
        const codeElem = document.querySelector("#xui-code-json");
        if (codeElem != null) {
            const code = Prism.highlight(this.codeXUIdata, Prism.languages.json, 'json');
            codeElem.innerHTML = code;
        }
    }

    loadCodeXUI() {
        const codeElem = document.querySelector("#xui-code-xui");
        if (codeElem != null) {
            const code = Prism.highlight(this.codeXUI, Prism.languages.html, 'html');
            codeElem.innerHTML = code;
        }
    }

    undo() {
        const name = this.getPageId();
        const rootdata = $xui.getAppState().main;

        let version = localStorage.getItem(`xui_version_${name}`);
        if (version == null)
            version = "0";

        let versionMin = localStorage.getItem(`xui_version_min_${name}`);
        if (versionMin == null)
            versionMin = "0";
        let verMin = parseInt(versionMin);

        let ver = parseInt(version);
        if (ver > verMin+1)
            ver--;
        else
            rootdata.undoDisabled = true;

        localStorage.setItem(`xui_version_${name}`, `${ver}`);
        $xui.refreshAction("template:reload");
        rootdata.redoDisabled = false;
    }

    redo() {
        const name = this.getPageId();
        const versionMax = localStorage.getItem(`xui_version_max_${name}`);
        const version = localStorage.getItem(`xui_version_${name}`);

        let ver = parseInt(version);
        const verMax = parseInt(versionMax);
        const rootdata = $xui.getAppState().main;
        
        if (ver < verMax) {
            ver++;
            rootdata.undoDisabled = false;
        }
        if (ver == verMax) {
            rootdata.redoDisabled = true;
        }

        localStorage.setItem(`xui_version_${name}`, `${ver}`);
        $xui.refreshAction("template:reload");
    }

    clearAll() {
        localStorage.clear();
    }
}