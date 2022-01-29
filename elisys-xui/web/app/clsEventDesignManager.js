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
            const data = e.data;
            if (data.action == "getCmpForFile") {
                const act = `returnCmpForFile_${data.infoFileCmp.file}_${data.infoFileCmp.xid}`;
                const prom = getPromise(act);
                waitForXuiLib("getHtmlFromXUI", () => {
                    $xuicore.getHtmlFromXUI(data.infoFileCmp, act);
                    prom.then(jsCmp => {
                        document.querySelector("#rootFrame").contentWindow.postMessage({ "action": act, jsCmp }, "*");
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
            e.dataTransfer.setData('text/plain', `add cmp ${item.xid}`);
            $xui.SelectorManager.unDisplaySelector();
        }

        // gestion du déplacement de composant entre slot sur selector
        $xui.dragMoveStart = (e) => {
            $xui.dragMoveItem = $xui.propertiesDesign;
            $xui.dragItem = null;
            e.dataTransfer.setData('text/plain', `move ${$xui.propertiesDesign.xid}`);
        }

        // gestion de la fermeture par ctrl Q
        document.addEventListener("keydown", (event) => {

            if (event.ctrlKey && event.keyCode == 80) {    // ctrl + P
                // mode preview  : gestion de l'ouverture par ctrl P
                event.stopPropagation();
                event.preventDefault();
                $xui.modePreview();
            }

        });

        window.addEventListener('pointerup', (e) => {
            if (e.button == 0) {
                $xui.closePopup();
            }
        });

        // gestion des evenements entre le designer et l'iframe
        window.addEventListener('message', function (e) {
            const data = e.data;
            if (data.action == "select" || data.action == "popupAction") {
                $xui.closePopup();
                $xui.SelectorManager.displaySelectorByPosition(data.position);
                $xui.modeDisplaySelection = true;

                // se repositionne sur l'onglet 0
                if (data.action == "select" && $xui.rootdata.idxTabProperties > 2)
                    $xui.rootdata.idxTabProperties = 0;

                // 250 = delay d'animation des v-tabs
                const delayWaitEndAnim = 50;   //250
                setTimeout(() => { 

                    $xui.displayPropertiesJS(data.xid, data.xid_slot); 
                    if (data.action == "popupAction")
                    {
                        const prom = getPromise("afterDesignProperties");
                        prom.then(()=>{
                                const pos = document.querySelector("#rootFrame").getBoundingClientRect();
                                $xui.OpenPopupAction( {clientX : data.position.clientX+pos.left, clientY :  data.position.clientY + pos.top});
                            }
                        )
                    }

                }, delayWaitEndAnim);
            }
            else if (data.action == "unselect") {   // sur scroll ou resize
                $xui.closePopup();
                $xui.SelectorManager.unDisplaySelector();
            }
            else if (data.action == "changeRoute") {   // sur scroll ou resize
                $xui.closePopup();
                $xui.SelectorManager.unDisplaySelector();
                
                // setTimeout(() => {
                //    // $xui.displayPropertiesJS("root", "root", ); 
                // }, 500);
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
                    if (data.ctrlKey)
                        $xui.copyCmpOnDrap(data);
                    else
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
            else if (data.action == "delete") {
                $xui.deleteCmp();
            }
            else if (data.action == "updateDirectProp") {
                $xui.SelectorManager.unDisplaySelector();
                $xui.updateDirectProperty(data.value, data.variable, data.xid);
            }
            else if (data.action == "displayMessage") {
                $xui.rootdata.messages.push(data.value);
                this.setTimeout(() => {
                    const index = $xui.rootdata.messages.indexOf(data.value);
                    if (index !== -1) {
                        $xui.rootdata.messages.splice(index, 1);
                    }
                }, data.value.timeout);
            }
            // gestion d'un hot load reloader
            else if (data.action == "get template reloader") {
                const infoFileCmp = $xui.pageDesignManager.getInfoFile('template');
                infoFileCmp.partXID = data.xid;
                const prom = getPromise("getVueCmp");
                $xuicore.getHtmlFromXUI(infoFileCmp, "getVueCmp");
                prom.then(template => {
                    document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "doChangeComponent", "xid": data.xid, "template": template }, "*");
                })
            }
            else if (data.action == "reloader finish") {
                // lancer par les v-xui-reloader  ou aprés un rechargement global du body
                console.debug("reloader finish");

                
                doPromiseJS("OnPageReady");
                doPromiseJS("AfterChangeSelectByXid");
            }
            else if (data.action == "return getInfoForSelector") {
                //console.debug("*******>", data);
                doPromiseJS(`getInfoForSelectorOnIFrame${data.info.idx}`, data.ret);
            }


        });
    }
}