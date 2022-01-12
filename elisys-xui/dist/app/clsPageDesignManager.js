export class PageDesignManager {

    codeHtml = null;
    codeXUIdata = null;
    codeXUI = null;


    getInfoFile(mode) {
        return {
            fileID: window.$xui.rootdata.frameName,
            file: `app/${window.$xui.rootdata.frameTemplate}.html`,
            xid: 'root',
            mode,
            jsonBinding: JSON.stringify($xui.rootdata.stateData)
        };
    }


    getPageId() {
        return window.$xui.rootdata.frameName;
    }

    /** premier chargement de la page en full */
    loadPage(html, option) {
        if ($xui.rootdata.isModePhone) {
            document.querySelector("#rootFrame").classList.remove("xui-iframe-phone");
        }
        document.querySelector("#rootFrame").style.display = 'none';
        document.querySelector("#rootFrame").srcdoc = html;
        $xui.rootdata.routeEnable = true;
        $xui.rootdata.actionEnable = true;

        this.codeHtml = html;

        setTimeout(() => {
            $xui.displayComponents("", "");
            $xui.displayPropertiesJS("page-0-route-0-content-slot", "page-0-route-0-content-slot");
        }, 200);

        if (option != null) {
            $xui.rootdata.listSlot.length = 0;
            $xui.rootdata.listSlot.push(...option.treeSlot);
            const prom = getPromise("OnPageReady");
            prom.then(()=> { 
                this.initConfigApp(option); 
                $xui.rootdata.overlayEvent=true;
                $xui.rootdata.overlay=false;
                document.querySelector("#rootFrame").style.display = null;
            });
        }

        // activation des button undo et redo
        const name = this.getPageId();
        const version = localStorage.getItem(`xui_version_${name}`);
        if (version != null) {
            $xui.rootdata.undoDisabled = false;
            const versionMax = localStorage.getItem(`xui_version_max_${name}`);
            if (versionMax != null && parseInt(versionMax) > parseInt(version)) {
                $xui.rootdata.redoDisabled = false;
            }
        }
    }


    initConfigApp(option) {
        if (option.appConfig != null && option.appConfig != "") {
            const appConfig = JSON.parse(option.appConfig); 
            if (appConfig.isModePhone) {
                $xui.modePhone();
            }
            
            $xui.rootdata.stateDataSource = appConfig.dataSrc;
            $xui.rootdata.routeEnable = appConfig.routeEnable;
            $xui.rootdata.actionEnable = appConfig.actionEnable;

        }
        else
        {
            $xui.rootdata.stateDataSource = "template";
            $xui.rootdata.routeEnable = true;
            $xui.rootdata.actionEnable = true;
        }
    }

    changePageOnFrame(param) {

        $xui.SelectorManager.unDisplaySelector();

        param.jsonTemplate = $xui.rootdata.stateData;
        if ($xui.rootdata.stateDataSource == "mock") {
            param.jsonBinding = $xui.rootdata.stateDataMock;
        }
        else {
            param.jsonBinding = $xui.rootdata.stateData;
        }

        if (param.mode == "template") {
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

        //console.debug("binding ---- ", param.binding);
        //console.debug("treeSlot ---- ", param.treeSlot);

        $xui.rootdata.listSlot.length = 0;
        $xui.rootdata.listSlot.push(...param.treeSlot);

        if (param.action == "export") {
            this.export();
        }

        if (param.action == "clear") {
            doPromiseJS("AfterChangeSelectByXid");
            // $xui.rootdata.routeEnable = true;
            // $xui.rootdata.actionEnable = true;
            // setTimeout(() => {
            //     const infoFile = $xui.pageDesignManager.getInfoFile("design");
            //     $xuicore.initPageXUI(infoFile);
            // }, 1000);

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

        if ($xui.rootdata.idxTabMain == $xui.MainTabEnum.CODE)  // si onglet 2 actif
        {
            this.loadCode();   // affiche le code du mode (template, preview, final )
            this.loadCodeXUI();
            this.loadCodeJson();
        }

    }

    async export() {
        const q = faunadb.query;
        const client = new faunadb.Client({ secret: 'fnADgqwCPfACAEWJ2wy7Kb5jrUIN5aa4t93DOl1a' });

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
                    q.Match(q.Index('filexuiById'), $xui.rootdata.frameName)
                )
            )
        } catch (error) {
            console.log("ret error =", error);
            if (error.requestResult.statusCode==404)
            {
                ret= await client.query(
                    q.Create(
                        q.Collection('Filexui'),
                        { data: { id: $xui.rootdata.frameName, html:"new" } },
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
        $xui.rootdata.snackbar_text = "deploy terminated";
        $xui.rootdata.snackbar_timeout = 2000;
        $xui.rootdata.snackbar = true;
    }

    store() {
        const name = this.getPageId();
        let version = localStorage.getItem(`xui_version_${name}`);
        if (version == null)
            version = "0";

        let ver = parseInt(version);

        localStorage.setItem(`xui_data_${name}_${ver}`, this.codeXUIdata);
        ver++;
        localStorage.setItem(`xui_version_${name}`, `${ver}`);
        localStorage.setItem(`xui_version_max_${name}`, `${ver}`);

        $xui.rootdata.redoDisabled = true;
        $xui.rootdata.undoDisabled = false;

        // gestion du max
        // var versionMax = localStorage.getItem('xui_version_max_' + name);
        // if (versionMax == null)
        //     versionMax = "" + ver;

        // if (parseInt(versionMax) <= ver)
        //     localStorage.setItem('xui_version_max_' + name, "" + ver);

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
        let version = localStorage.getItem(`xui_version_${name}`);
        if (version == null)
            version = "0";

        let ver = parseInt(version);
        if (ver > 0)
            ver--;

        localStorage.setItem(`xui_version_${name}`, `${ver}`);
        $xui.refreshAction("template:reload");
        $xui.rootdata.redoDisabled = false;
    }

    redo() {
        const name = this.getPageId();
        const versionMax = localStorage.getItem(`xui_version_max_${name}`);
        const version = localStorage.getItem(`xui_version_${name}`);

        let ver = parseInt(version);
        const verMax = parseInt(versionMax);
        
        if (ver < verMax) {
            ver++;
        }
        if (ver == verMax) {
            $xui.rootdata.redoDisabled = true;
        }

        localStorage.setItem(`xui_version_${name}`, `${ver}`);
        $xui.refreshAction("template:reload");
    }

    clearAll() {
        localStorage.clear();
    }
}