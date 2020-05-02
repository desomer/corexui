export class EventManager {

    init() {

        // gestion du drag de nouveau composant
        $xui.dragStart = (item, e) => {
            $xui.dragItem = item;
            $xui.dragMoveItem = null;
            e.dataTransfer.setData('text/plain', "add cmp " + item.xid);
            $xui.unDisplaySelector();
        }
        
        // gestion du déplacement de composant
        $xui.dragMoveStart = (e) => {
            $xui.dragMoveItem = $xui.propertiesDesign;
            $xui.dragItem = null;
            e.dataTransfer.setData('text/plain', "move " + $xui.propertiesDesign.xid);
        }

        document.addEventListener("keydown", function (event) {

            if (event.ctrlKey && event.keyCode == 80) {    // ctrl + Q
                // mode preview  : gestion de la fermeture par ctrl Q
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
                // 250 = delay d'animation des v-tabs
                setTimeout(() => { $xui.displayPropertiesJS(data.xid, data.xid_slot); }, 250);
            }
            if (data.action == "unselect") {
                $xui.unDisplaySelector();
            }
            if (data.action == "drop") {
                if ($xui.dragItem != null) {
                    // gestion drag de nouveau component sur l'Iframe
                    $xui.displayPropertiesJS(data.xid, data.xid_slot);
                    $xui.displayComponents(data.xid, data.xid_slot);
                    $xui.addCmp($xui.dragItem);
                }
                if ($xui.dragMoveItem != null) {
                    // gestion de drag entre slot
                    if ($xui.cutCmp()) {   // suppression de source
                        // selection de la target
                        var prom = $xui.displayPropertiesJS(data.xid, data.xid_slot);
                        prom.then(() => {  
                            $xui.pasteTo();
                        })

                        // setTimeout(() => {   // todo gestion par promise
                        //     $xui.pasteTo();
                        // }, 200);  // attend la fin du displayPropertiesJS
                    }
                }
            }
            if (data.action == "ctrlQ") {
                $xui.modePreview();
            }

            if (data.action == "updateDirectProp") {
                $xui.unDisplaySelector();
                $xui.updateDirectProperty(data.value, data.variable, data.xid);
            }

            if (data.action == "load reloader") {
                var infoFileCmp = { file: "app/frame1.html", xid: "root", mode: 'template',  part:data.xid };
                var prom = getPromise("getVueCmp")
                $xui.getHtmlFrom(infoFileCmp, "getVueCmp");
                prom.then(template => {
                  document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "changeReloader", "xid": data.xid , "template": template }, "*");
                })

            }

            if (data.action == "getCmpForFile")
            {
                //this.console.debug("***********getCmpForFile***********", data);
                var act = "returnCmpForFile_"+data.infoFileCmp.file+"_"+data.infoFileCmp.xid;

                var prom = getPromise(act)
                $xui.getHtmlFrom(data.infoFileCmp, act);
                prom.then(jsCmp => {
                    document.querySelector("#rootFrame").contentWindow.postMessage({ "action": act, jsCmp: jsCmp }, "*");
                });


            }
        });
    }
}