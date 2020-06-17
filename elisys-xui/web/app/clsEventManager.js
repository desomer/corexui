export class EventManager {

    init() {

        // gestion du drag de nouveau composant sur selector
        $xui.dragStart = (item, e) => {
            $xui.dragItem = item;
            $xui.dragMoveItem = null;
            e.dataTransfer.setData('text/plain', "add cmp " + item.xid);
            $xui.unDisplaySelector();
        }

        // gestion du déplacement de composant entre slot sur selector
        $xui.dragMoveStart = (e) => {
            $xui.dragMoveItem = $xui.propertiesDesign;
            $xui.dragItem = null;
            e.dataTransfer.setData('text/plain', "move " + $xui.propertiesDesign.xid);
        }

        // gestion de la fermeture par ctrl Q
        document.addEventListener("keydown", function (event) {

            if (event.ctrlKey && event.keyCode == 80) {    // ctrl + P
                // mode preview  : gestion de l'ouverture par ctrl P
                event.stopPropagation();
                event.preventDefault();
                $xui.modePreview();
            }

        });

        // gestion des evenements entre le designer et l'iframe
        window.addEventListener('message', function (e) {
            var data = e.data;
            if (data.action == "select") {
                this.console.debug(data);
                $xui.displaySelectorByPosition(data.position);
                $xui.modeDisplaySelection = true;

                // se repositionne sur l'onglet 0
                $xui.rootdata.activeAction = 0;
                // 250 = delay d'animation des v-tabs
                const delayWaitEndAnim = 250;
                setTimeout(() => { $xui.displayPropertiesJS(data.xid, data.xid_slot); }, delayWaitEndAnim);
            }
            else if (data.action == "unselect") {
                $xui.unDisplaySelector();
            }
            else if (data.action == "drop") {
                if ($xui.dragItem != null) {
                    // gestion drag de nouveau component sur l'Iframe
//                    $xui.displayPropertiesJS(data.xid, data.xid_slot);
                    $xui.displayComponents(data.xid, data.xid_slot);
                    $xui.addCmp($xui.dragItem);
                }
                if ($xui.dragMoveItem != null) {
                    // gestion de drag entre slot
                    $xui.moveTo(data);
                }
            }
            else if (data.action == "ctrlP") {
                $xui.modePreview();  // fermeture 
            }
            else if (data.action == "ctrlX") {
                $xui.cutCmp();
            }
            else if (data.action == "ctrlC") {
                alert("ctrlC");
            }
            else if (data.action == "ctrlV") {
                if (!$xui.rootdata.pasteDisabled) {
                    $xui.pasteTo();
                }
            }
            else if (data.action == "ctrlZ") {
                if (!$xui.rootdata.undoDisabled) {
                    $xui.undo();
                }
            }
            else if (data.action == "ctrlY") {
                if (!$xui.rootdata.redoDisabled) {
                    $xui.redo();
                }
            }
            else if (data.action == "DEL") {
                $xui.deleteCmp();
            }
            else if (data.action == "updateDirectProp") {
                $xui.unDisplaySelector();
                $xui.updateDirectProperty(data.value, data.variable, data.xid);
            }
            // gestion d'un hot load reloader
            else if (data.action == "load reloader") {
                var infoFileCmp = getInfoFile('template');
                infoFileCmp.part = data.xid;
                //  { file: "app/frame1.html", xid: "root", mode: 'template',  part:data.xid };
                var prom = getPromise("getVueCmp")
                $xui.getHtmlFrom(infoFileCmp, "getVueCmp");
                prom.then(template => {
                    document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "changeReloader", "xid": data.xid, "template": template }, "*");
                })
            }
            else if (data.action == "reloader finish") {
                // this.console.debug("reloader finish");
                $xui.doPromiseJS("changePageFinish");
            }
            // ajoute un composant vueJS depuis un fichier XUI (ex: xui-split-1)
            else if (data.action == "getCmpForFile") {
                //this.console.debug("***********getCmpForFile***********", data);
                var act = "returnCmpForFile_" + data.infoFileCmp.file + "_" + data.infoFileCmp.xid;

                var prom = getPromise(act)
                $xui.getHtmlFrom(data.infoFileCmp, act);
                prom.then(jsCmp => {
                    document.querySelector("#rootFrame").contentWindow.postMessage({ "action": act, jsCmp: jsCmp }, "*");
                });


            }
        });
    }
}