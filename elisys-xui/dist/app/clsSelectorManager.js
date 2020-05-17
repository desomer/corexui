export class SelectorManager {
    init() {

        $xui.unDisplaySelector = () => {
            var node = document.getElementById("xui-display-selector");
            if (node != null) {
                node.style.display = "none";
                node = document.getElementById("xui-display-selector-margin");
                node.style.display = "none";
            }
        };

        $xui.displaySelectorByPosition = (position) => {

            if ($xui.hasPropertiesChanged) {
                // sauvegarde automatique
                $xui.saveProperties().then(() => {
                    console.debug("auto save ok");
                    if ($xui.modeDisplaySelection) {
                        console.debug("reselect after save ", $xui.propertiesDesign);
                        setTimeout(() => {   // attente prise en compte par l'iFrame
                            $xui.displaySelectorByXid($xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot, true);
                        }, 500);
                    }
                }
                )
            }

            var node = document.getElementById("xui-display-selector");
            if (node == null) {
                node = document.createElement("div");
                node.id = "xui-display-selector";
                node.classList.add("xui-style-selector");

                node.addEventListener("click", (e) => {
                    e.currentTarget.style.display = "none";   // retire sur le click
                    $xui.modeDisplaySelection = false;
                }, { capture: false })

                node.addEventListener("wheel", (e) => {
                    e.currentTarget.style.display = "none";   // retire sur le wheel
                }, { capture: false })

                var nodeAction = document.createElement("div");
                nodeAction.id = "xui-display-selector-action";
                node.appendChild(nodeAction);
                node.setAttribute("draggable", true);

                node.addEventListener("dragstart", function (event) { $xui.dragMoveStart(event); }, false);

                document.body.appendChild(node);


                node = document.createElement("div");
                node.id = "xui-display-selector-margin";
                node.classList.add("xui-style-selector-margin");
                node.addEventListener("click", (e) => {
                    e.currentTarget.style.display = "none";   // retire sur le click
                    $xui.modeDisplaySelection = false;
                }, { capture: false })
                document.body.appendChild(node);
            }

            var nodeMargin = document.getElementById("xui-display-selector-margin");
            var posFrame = rootFrame.getBoundingClientRect();
            //console.debug(position);
            node.style.height = position.height + "px";
            node.style.left = (position.left + posFrame.left) + "px";
            node.style.top = (position.top + posFrame.top) + "px";
            node.style.width = position.width + "px";
            node.style.display = null;   //affiche la div de selection

            if (position.hasMargin) {
                nodeMargin.style.height = position.height + (position.mt + position.mb) + "px";
                nodeMargin.style.left = (position.left + posFrame.left - position.ml) + "px";
                nodeMargin.style.top = (position.top + posFrame.top - position.mt) + "px";
                nodeMargin.style.width = position.width + (position.mr + position.ml) + "px";
                nodeMargin.style.display = null;   //affiche la div de selection
            }
            else {
                nodeMargin.style.display = "none";
            }

            $xui.rootdata.activeAction = 0;

            $xui.displayAction($xui.propertiesDesign.xid, null);

        }


        // selection par click des properties
        $xui.displaySelectorByXid = (xid, xid_slot, noDisplayProp) => {

            $xui.unDisplaySelector();

            // recherche xid simple
            let winFrame = document.querySelector("#rootFrame").contentWindow;
            var elemRect = winFrame.getInfoForSelector("[data-xid=" + xid + "]");
            if (elemRect != null) {
                console.debug("displaySelectorByXid 1 ", xid);
                $xui.displaySelectorByPosition(elemRect);
            }

            if (elemRect == null) {
                elemRect = winFrame.getInfoForSelector("[data-xid-slot-" + xid + "=true]");
                if (elemRect != null) {
                    console.debug("displaySelectorByXid 2 ", xid);
                    $xui.displaySelectorByPosition(elemRect);
                }
            }
           

            // recherche xid de slot invisible sur les div enfant => realise un merge des clientRect
            if (elemRect == null) {
                var listNode = document.querySelector("#rootFrame").contentDocument.querySelectorAll("[data-xid-slot=" + xid + "]")
                var found = false;
                
                if (listNode != null && listNode.length>0 && listNode.length == listNode[0].parentNode.children.length) {
                    let parent = true;   
                    elemRect = winFrame.getInfoForSelector("[data-xid-slot=" + xid + "]", parent);
                    if (elemRect != null) {
                        console.debug("displaySelectorByXid 3 ", xid);
                        if (elemRect.width!=0 && elemRect.height!=0)
                        {
                            $xui.displaySelectorByPosition(elemRect);
                            found=true;
                        }
                    }
                } 
                
                if (!found && listNode != null && listNode.length > 0) {
                    // gestion des d'intersection des region des enfants
                    var myRegion = null;
                    for (const aNode of listNode) {
                        let elemRect = aNode.getBoundingClientRect();
                        if (myRegion == null)
                            myRegion = new Region2D(elemRect);
                        else
                            myRegion = myRegion.union(new Region2D(elemRect));
                    }
                    console.debug("displaySelectorByXid 4 ", xid);
                    $xui.displaySelectorByPosition(myRegion.getBounds());
                }
                else
                {
                    console.debug("displaySelectorByXid 5 no found ", xid);
                }
            }

            if (!noDisplayProp) {
                $xui.modeDisplaySelection = true;
                setTimeout(() => { $xui.displayPropertiesJS(xid, xid_slot); }, 100);
            }
        }
    }

    getInfoCmp(targetAction) {
        let elemRect = targetAction.getBoundingClientRect();
        let s = document.querySelector("#rootFrame").contentWindow.getComputedStyle(targetAction);

        let margin = { mb: parseInt(s.marginBottom), mt: parseInt(s.marginTop), ml: parseInt(s.marginLeft), mr: parseInt(s.marginRight) }

        var ret = {
            hasMargin: (margin.mb > 0 || margin.mt > 0 || margin.ml > 0 || margin.mr > 0),
            height: elemRect.height,
            width: elemRect.width,
            left: elemRect.left,
            top: elemRect.top,
            ...margin
        };

        return ret;
    }
}