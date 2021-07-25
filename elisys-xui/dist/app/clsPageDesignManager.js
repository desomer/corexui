export class PageDesignManager {

    codeHtml = null;
    codeXUIdata = null;
    codeXUI = null;
    //db = null;

    getInfoFile(mode) {
        return {
            fileID: window.$xui.rootdata.frameName,
            file: 'app/' + window.$xui.rootdata.frameName + '.html',
            xid: 'root',
            mode: mode,
            jsonBinding: JSON.stringify($xui.rootdata.jsonEditorData)
        };
    }


    getPageId() {
        return window.$xui.rootdata.frameName;
    }

    loadPage(html, param) {
        // console.debug("load", html);
        document.querySelector("#rootFrame").srcdoc = html;

        this.codeHtml = html;

        if (param != null) {
            $xui.rootdata.listSlot.length = 0;
            $xui.rootdata.listSlot.push(...param.treeSlot);
        }

        setTimeout(() => {
            $xui.displayComponents("", "");
            $xui.displayPropertiesJS("root", "root")
        }, 100);

        var name = this.getPageId();
        var version = localStorage.getItem('xui_version_' + name);
        if (version != null) {
            $xui.rootdata.undoDisabled = false;
            var versionMax = localStorage.getItem('xui_version_max_' + name);
            if (versionMax != null) {
                if (parseInt(versionMax) > parseInt(version)) {
                    $xui.rootdata.redoDisabled = false;
                }
            }
        }
    }


    changePageOnFrame(param) {
        //console.debug("change page", param);

        $xui.unDisplaySelector();

        param.jsonTemplate = $xui.rootdata.jsonEditorData;
        if ($xui.rootdata.jsonEditorDataSrc == "mock") {
            param.jsonBinding = $xui.rootdata.jsonEditorDataMock;
        }
        else {
            param.jsonBinding = $xui.rootdata.jsonEditorData;
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

        console.debug("binding ---- ", param.binding);
        console.debug("treeSlot ---- ", param.treeSlot);

        $xui.rootdata.listSlot.length = 0;
        $xui.rootdata.listSlot.push(...param.treeSlot);

        if (param.action == "export") {
            this.export();
        }

        if (param.action == "clear") {
            $xui.doPromiseJS("changePageFinish");
        }

        if (param.action != "reload-json" && param.action != "reload" && param.action != "clear" && param.action != "export")
            this.store(); // save un nouvelle version

        if ($xui.doStoreOnNextReload) {
            this.store(); // save un nouvelle version
            $xui.doStoreOnNextReload=false;
            setTimeout(() => {
                $xui.displayPropertiesJS("root", "root");   // reaffecte le nouveau mapping sur la page
            }, 500);
        }

        if ($xui.rootdata.activeTab == 2)  // si onglet 2 actif
        {
            this.loadCode();   // affiche le code du mode (template, preview, final )
            this.loadCodeXUI();
            this.loadCodeJson();
        }

    }

    async export() {
        var q = faunadb.query;
        var client = new faunadb.Client({ secret: 'fnADgqwCPfACAEWJ2wy7Kb5jrUIN5aa4t93DOl1a' });

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

        var ret = await client.query(
            q.Get(
                q.Match(q.Index('filexuiById'), $xui.rootdata.frameName)
            )
        )
        console.log("ret=", ret);

        ret = await client.query(
            q.Update(
                ret.ref,
                { data: { html: $xui.pageDesignManager.codeHtml } },
            )
        )

        console.log("ret=", ret);
        $xui.rootdata.snackbar_text = "deploy terminated";
        $xui.rootdata.snackbar_timeout = 2000;
        $xui.rootdata.snackbar = true;
    }

    store() {
        var name = this.getPageId();
        var version = localStorage.getItem('xui_version_' + name);
        if (version == null)
            version = "0";

        var ver = parseInt(version);

        localStorage.setItem('xui_data_' + name + '_' + ver, this.codeXUIdata);
        ver++;
        localStorage.setItem('xui_version_' + name, "" + ver);
        localStorage.setItem('xui_version_max_' + name, "" + ver);

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
        var codeElem = document.querySelector("#xui-code-html");
        if (codeElem != null) {
            const code = Prism.highlight(this.codeHtml, Prism.languages.html, 'html');
            codeElem.innerHTML = code;
        }
    }

    loadCodeJson() {
        var codeElem = document.querySelector("#xui-code-json");
        if (codeElem != null) {
            const code = Prism.highlight(this.codeXUIdata, Prism.languages.json, 'json');
            codeElem.innerHTML = code;
        }
    }

    loadCodeXUI() {
        var codeElem = document.querySelector("#xui-code-xui");
        if (codeElem != null) {
            const code = Prism.highlight(this.codeXUI, Prism.languages.html, 'html');
            codeElem.innerHTML = code;
        }
    }

    undo() {
        var name = this.getPageId();
        var version = localStorage.getItem('xui_version_' + name);
        if (version == null)
            version = "0";

        var ver = parseInt(version);
        if (ver > 0)
            ver--;

        localStorage.setItem('xui_version_' + name, "" + ver);
        $xui.refreshAction("template:reload");
        $xui.rootdata.redoDisabled = false;
    }

    redo() {
        var name = this.getPageId();
        var versionMax = localStorage.getItem('xui_version_max_' + name);
        var version = localStorage.getItem('xui_version_' + name);

        var ver = parseInt(version);
        var verMax = parseInt(versionMax);
        if (ver < verMax) {
            ver++;
        }
        if (ver == verMax) {
            $xui.rootdata.redoDisabled = true;
        }

        localStorage.setItem('xui_version_' + name, "" + ver);
        $xui.refreshAction("template:reload");
    }

    clearAll() {
        localStorage.clear();
    }
}