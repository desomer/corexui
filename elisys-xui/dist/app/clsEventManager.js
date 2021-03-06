/**
 * class de gestion des events du designer
 * 
 *          
 */

export class EventManager {

    init() {
        this.initEvent();
        this.initBuild();
    }

    initBuild() {
        window.addEventListener('message', function (e) {
            var data = e.data;
            if (data.action == "getCmpForFile") {
                var act = "returnCmpForFile_" + data.infoFileCmp.file + "_" + data.infoFileCmp.xid;
                var prom = getPromise(act)
                waitForXuiLib("getHtmlFromXUI", function () {
                    $xui.getHtmlFromXUI(data.infoFileCmp, act);
                    prom.then(jsCmp => {
                        document.querySelector("#rootFrame").contentWindow.postMessage({ "action": act, jsCmp: jsCmp }, "*");
                    });
                }, this);

            }
        });
    }

    initEvent() {
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

        window.addEventListener('pointerup', function (e) {
            if (e.button == 0) {
                $xui.closePopup();
            }
        });

        // gestion des evenements entre le designer et l'iframe
        window.addEventListener('message', function (e) {
            var data = e.data;
            if (data.action == "select") {
                $xui.closePopup();
                //this.console.debug("message select ", data);
                $xui.displaySelectorByPosition(data.position);
                $xui.modeDisplaySelection = true;

                // se repositionne sur l'onglet 0
                $xui.rootdata.activeAction = 0;
                // 250 = delay d'animation des v-tabs
                const delayWaitEndAnim = 250;
                setTimeout(() => { $xui.displayPropertiesJS(data.xid, data.xid_slot); }, delayWaitEndAnim);
            }
            else if (data.action == "unselect") {   // sur scroll ou resize
                $xui.closePopup();
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
                $xui.copyCmp();
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
            else if (data.action == "updateDirectProp") {
                $xui.unDisplaySelector();
                $xui.updateDirectProperty(data.value, data.variable, data.xid);
            }
            // gestion d'un hot load reloader
            else if (data.action == "get template reloader") {
                var infoFileCmp = $xui.pageDesignManager.getInfoFile('template');
                infoFileCmp.part = data.xid;
                var prom = getPromise("getVueCmp")
                $xui.getHtmlFromXUI(infoFileCmp, "getVueCmp");
                prom.then(template => {
                    document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "doChangeComponent", "xid": data.xid, "template": template }, "*");
                })
            }
            else if (data.action == "reloader finish") {
                // this.console.debug("reloader finish");
                $xui.doPromiseJS("changePageFinish");
            }
        });
    }
}