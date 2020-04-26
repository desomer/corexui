export class SelectorManager {
    init() {

        $xui.unDisplaySelector = () => {
            var node = document.getElementById("xui-display-selector");
            if (node != null) {
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
            }

            var posFrame = rootFrame.getBoundingClientRect();
            node.style.height = position.height + "px";
            node.style.left = (position.left + posFrame.left) + "px";
            node.style.top = (position.top + posFrame.top) + "px";
            node.style.width = position.width + "px";
            node.style.display = null;   //affiche la div de selection

            $xui.rootdata.activeAction = 0;

            $xui.displayAction($xui.propertiesDesign.xid, null);

        }


        // selection par click des properties
        $xui.displaySelectorByXid = (xid, xid_slot, noSelect) => {
            $xui.unDisplaySelector();

            // recherche xid simple
            var node = document.querySelector("#rootFrame").contentDocument.querySelector("[data-xid=" + xid + "]")
            if (node != null) {
                let elemRect = node.getBoundingClientRect();
                $xui.displaySelectorByPosition(elemRect);
            }

            // recherche xid de slot invisible sur les div parentes
            if (node == null) {
                node = document.querySelector("#rootFrame").contentDocument.querySelector("[data-xid-slot-" + xid + "=true]")
                if (node != null) {
                    let elemRect = node.getBoundingClientRect();
                    $xui.displaySelectorByPosition(elemRect);
                }
            }

            // recherche xid de slot invisible sur les div enfant => realise un merge des clientRect
            if (node == null) {
                var listNode = document.querySelector("#rootFrame").contentDocument.querySelectorAll("[data-xid-slot=" + xid + "]")
                if (listNode != null && listNode.length > 0) {
                    // gestion des d'intersection des region des enfants
                    var myRegion = null;
                    for (const aNode of listNode) {
                        let elemRect = aNode.getBoundingClientRect();
                        if (myRegion == null)
                            myRegion = new Region2D(elemRect);
                        else
                            myRegion = myRegion.union(new Region2D(elemRect));
                    }

                    $xui.displaySelectorByPosition(myRegion.getBounds());
                }
            }

            if (!noSelect) {
                $xui.modeDisplaySelection = true;
                setTimeout(() => { $xui.displayPropertiesJS(xid, xid_slot); }, 100);
            }
        }
    }
}