export class PageDesignManager {

    codeHtml = null;
    codeYaml = null;
    db = null;

    loadPage(html) {
        // console.debug("load", html);
        document.querySelector("#rootFrame").srcdoc = html;

        this.codeHtml = html;
        setTimeout(() => {
            $xui.displayComponents("", "");
            $xui.displayPropertiesJS("root", "root")
        }, 100);

        var name = "frame1"
        var version = localStorage.getItem('xui_version_' + name);
        if (version != null)
        {
            $xui.rootdata.undoDisabled=false;
            var versionMax = localStorage.getItem('xui_version_max_' + name);
            if (versionMax != null)
            {
                if (parseInt(versionMax) > parseInt(version))
                {
                    $xui.rootdata.redoDisabled=false;
                }
            }
        }
    }

    changePageJS(param) {
        //console.debug("change page", param);

        $xui.unDisplaySelector();

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
        this.codeYaml = param.yaml;

        if (param.action!="reload" && param.action!="clear")
            this.store(); // save un nouvelle version

        if ($xui.rootdata.activeTab == 1)  // si onglet 1 actif
        {
            this.loadCode();   // affiche le code du mode (template, preview, final )
            this.loadCodeYaml();
        }

    }

    store() {
        var name = "frame1"
        var version = localStorage.getItem('xui_version_' + name);
        if (version == null)
            version = "0";

        var ver = parseInt(version);

        localStorage.setItem('xui_yaml_' + name + '_' + ver, this.codeYaml);
        ver++;
        localStorage.setItem('xui_version_' + name, "" + ver);
        localStorage.setItem('xui_version_max_' + name, "" + ver);

        $xui.rootdata.redoDisabled=true;
        $xui.rootdata.undoDisabled=false;

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

    loadCodeYaml() {
        var codeElem = document.querySelector("#xui-code-yaml");
        if (codeElem != null) {
            const code = Prism.highlight(this.codeYaml, Prism.languages.yaml, 'yaml');
            codeElem.innerHTML = code;
        }
    }

    undo() {
        var name = "frame1"
        var version = localStorage.getItem('xui_version_' + name);
        if (version == null)
            version = "0";

        var ver = parseInt(version);
        if (ver>0)
            ver--;

        localStorage.setItem('xui_version_' + name, "" + ver);
        $xui.refreshAction("template:reload");
        $xui.rootdata.redoDisabled=false;
    }

    redo() {
        var name = "frame1"
        var versionMax = localStorage.getItem('xui_version_max_' + name);
        var version = localStorage.getItem('xui_version_' + name);

        var ver = parseInt(version);
        var verMax = parseInt(versionMax);
        if (ver<verMax)
        {
            ver++;
        }
        if (ver==verMax) {
            $xui.rootdata.redoDisabled=true;
        }

        localStorage.setItem('xui_version_' + name, "" + ver);
        $xui.refreshAction("template:reload");
    }

    clearAll()
    {
        localStorage.clear();
    }
}