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

        /************************************************************************************ */
        $xui.displaySelectorByPosition = (position) => {

            if ($xui.hasPropertiesChanged) {
                /*******************************************************/
                // sauvegarde automatique
                /*******************************************************/
                $xui.saveProperties()
                return;
            }

            /*******************************************************/
            var node = document.getElementById("xui-display-selector");
            if (node == null) {
                /************************************************* */
                // le node selector draggable
                node = document.createElement("div");
                node.id = "xui-display-selector";
                node.classList.add("xui-style-selector");

                node.setAttribute("draggable", true);
                node.addEventListener("dragstart", function (event) { $xui.dragMoveStart(event); }, false);

                node.addEventListener("click", (e) => {
                    e.currentTarget.style.display = "none";   // retire sur le click
                    $xui.modeDisplaySelection = false;
                }, { capture: false })

                node.addEventListener("wheel", (e) => {
                    e.currentTarget.style.display = "none";   // retire sur le wheel
                }, { capture: false })

                /************************************************* */
                // le node action
                var nodeAction = document.createElement("div");
                nodeAction.id = "xui-display-selector-action";
                node.appendChild(nodeAction);


                /************************************************* */
                document.body.appendChild(node);

                /************************************************* */

                // le node action
                // var nodePopup = document.createElement("div");
                // nodePopup.id = "xui-display-selector-popup";
                // document.body.appendChild(nodePopup);


                /************************************************* */
                // le node margin
                var nodeMargin = document.createElement("div");
                nodeMargin.id = "xui-display-selector-margin";
                nodeMargin.classList.add("xui-style-selector-margin");
                nodeMargin.addEventListener("click", (e) => {
                    e.currentTarget.style.display = "none";   // retire sur le click
                    $xui.modeDisplaySelection = false;
                }, { capture: false })
                document.body.appendChild(nodeMargin);
                /************************************************* */
            }

            var nodeMargin = document.getElementById("xui-display-selector-margin");
            var posFrame = rootFrame.getBoundingClientRect();
            //console.debug(position);

            // si survole page (root) = affiche la totalité de la page (même si scroll)
            if (position.selector=="[data-xid=root]")
            {
                position.top=0;
            }
            // ne depasse pas de l'iframe
            var pt =  Math.max(0, position.top);
            var ph =  Math.min((position.top - pt) + position.height, posFrame.height- pt);

            node.style.height = ph + "px";
            node.style.left = (position.left + posFrame.left) + "px";
            node.style.top = (pt + posFrame.top) + "px";
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


            // affiche les action du Node
            $xui.displayAction($xui.propertiesDesign.xid, null);

        }

        /************************************************************************************ */
        // selection par click des properties
        $xui.displaySelectorByXid = (xid, xid_slot, noDisplayProp) => {

            $xui.unDisplaySelector();

            // recherche xid simple
            let winFrame = document.querySelector("#rootFrame").contentWindow;
            let elemRect = winFrame.getInfoForSelector("[data-xid=" + xid + "]");
            if (elemRect != null) {
                //console.debug("displaySelectorByXid 1 ", xid);
                $xui.displaySelectorByPosition(elemRect);
            }

            if (elemRect == null) {
                elemRect = winFrame.getInfoForSelector("[data-xid-slot-" + xid + "=true]");
                if (elemRect != null) {
                    //console.debug("displaySelectorByXid 2 ", xid);
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
                        if (elemRect.width!=0 && elemRect.height!=0)
                        {
                            //console.debug("displaySelectorByXid 3 ", xid);
                            $xui.displaySelectorByPosition(elemRect);
                            found=true;
                        }
                    }
                } 
                
                if (!found && listNode != null && listNode.length > 0) {
                    // gestion des d'intersection des region des enfants
                    let myRegion = null;
                    for (const aNode of listNode) {
                        let elemRect = aNode.getBoundingClientRect();
                        if (myRegion == null)
                            myRegion = new Region2D(elemRect);
                        else
                            myRegion = myRegion.union(new Region2D(elemRect));
                    }
                    //console.debug("displaySelectorByXid 4 ", xid);
                    $xui.displaySelectorByPosition(myRegion.getBounds());
                }
                else if (!found)
                {
                    console.debug("displaySelectorByXid 5 no found ", xid);
                }
            }

            if (!noDisplayProp) {
                // affiche les properties sur le click (pas sur le survole des properties)
                $xui.modeDisplaySelection = true;
                setTimeout(() => { $xui.displayPropertiesJS(xid, xid_slot); }, 10);
            }
        }
    }

    /************************************************************************************ */
    getInfoPositionCmp(targetAction) {
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