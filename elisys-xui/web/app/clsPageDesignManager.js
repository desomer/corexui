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
    }

    changePageJS(param) {
        //console.debug("change page", param);

        $xui.unDisplaySelector();

        if (param.mode == "template") {
            // change uniquement template de la page aprés le demarrage en mode design
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

        this.store();

        if ($xui.rootdata.activeTab == 1)  // si onglet 1 actif
        {
            this.loadCode();   // affiche le code du mode (template, preview, final )
            this.loadCodeYaml();
        }

    }

    store() {
        localStorage.setItem('xui', this.codeYaml);
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
}