export class SelectorManager {

    idxGetInfoForSelectorOnIFrame = 0;

    unDisplaySelector() {
        let node = document.getElementById("xui-display-selector");
        if (node != null) {
            node.style.display = "none";
            node = document.getElementById("xui-display-selector-margin");
            node.style.display = "none";
        }
    }

    /************************************************************************************ */
    displaySelectorByPosition(position) {

        const rootdata = $xui.getAppState().main;

        if (rootdata.idxTabMain != $xui.MainTabEnum.DESIGN)
            return;

        /*******************************************************/
        let node = document.getElementById("xui-display-selector");
        if (node == null) {
            /************************************************* */
            // le node selector draggable
            node = document.createElement("div");
            node.id = "xui-display-selector";
            node.classList.add("xui-style-selector");

            node.setAttribute("draggable", true);
            node.addEventListener("dragstart", (event) => { $xui.dragMoveStart(event); }, false);

            node.addEventListener("click", (e) => {
                e.currentTarget.style.display = "none";   // retire sur le click
                $xui.modeDisplaySelection = false;
            }, { capture: false, passive: true })

            node.addEventListener("wheel", (e) => {
                e.currentTarget.style.display = "none";   // retire sur le wheel
            }, { capture: false, passive: true })

            /************************************************* */
            // le node action
            const nodeAction = document.createElement("div");
            nodeAction.id = "xui-display-selector-action";
            node.appendChild(nodeAction);
            /************************************************* */
            document.body.appendChild(node);

            /************************************************* */
            //le node info
            const aNodeInfo = document.createElement("div");
            aNodeInfo.id = "xui-display-selector-info";
            $xui.css(aNodeInfo, {
                position: "absolute",	
                right: "0px",	top: "-20px", 
                width : "80px", height : "20px"   
            });
            node.appendChild(aNodeInfo);

            /************************************************* */
            // le node margin
            const aNodeMargin = document.createElement("div");
            aNodeMargin.id = "xui-display-selector-margin";
            aNodeMargin.classList.add("xui-style-selector-margin");
            aNodeMargin.addEventListener("click", (e) => {
                e.currentTarget.style.display = "none";   // retire sur le click
                $xui.modeDisplaySelection = false;
            }, { capture: false })
            document.body.appendChild(aNodeMargin);
            /************************************************* */
        }

        const nodeMargin = document.getElementById("xui-display-selector-margin");
        const nodeInfo = document.getElementById("xui-display-selector-info");
        const posFrame = rootFrame.getBoundingClientRect();

        // si survole page (root) = affiche la totalité de la page (même si scroll)
        if (position.selector == "[data-xid=root]") {
            position.top = 0;
        }
        const z = 1; //1.11;  //pour zoom 0.9

        position.top = position.top * z;
        position.left = position.left * z;
        position.height = position.height * z;
        position.width = position.width * z;
        position.mt = position.mt * z;
        position.ml = position.ml * z;
        position.mr = position.mr * z;
        position.mb = position.mb * z;

        // ne depasse pas de l'iframe
        const pt = Math.max(0, position.top);
        const ph = Math.min((position.top - pt) + position.height, posFrame.height - pt);

        node.style.left = `${position.left + posFrame.left}px`;
        node.style.top = `${pt + posFrame.top}px`;
        node.style.height = `${ph}px`;
        node.style.width = `${position.width}px`;
        node.style.display = null;   //affiche la div de selection

        if (position.hasMargin) {
            nodeMargin.style.height = `${position.height + (position.mt + position.mb)}px`;
            nodeMargin.style.left = `${position.left + posFrame.left - position.ml}px`;
            nodeMargin.style.top = `${position.top + posFrame.top - position.mt}px`;
            nodeMargin.style.width = `${position.width + (position.mr + position.ml)}px`;
            nodeMargin.style.display = null;   //affiche la div de selection
        }
        else {
            nodeMargin.style.display = "none";
        }

        nodeInfo.innerHTML= position.parentDisplay;

        // affiche les action du Node
        $xui.displayAction($xui.propertiesDesign.xid, null);

    }


    displayInTree() {
        const rootdata = $xui.getAppState().main;
        if (rootdata.activeSlot.length == 0 || rootdata.activeSlot[0].id != $xui.propertiesDesign.xid) {
            let rowInTree = this._searchInTree($xui.propertiesDesign.xid, rootdata.listSlot);
            if (rowInTree == null) {
                const infoFile = $xui.pageDesignManager.getInfoFile("template");
                let info = $xuicore.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xid);
                rowInTree = this._searchInTree(info.parentXid, rootdata.listSlot);
            }
            if (rowInTree != null) {
                rootdata.activeSlot.length = 0;
                rootdata.activeSlot.push(rowInTree);
            }
            setTimeout(() => {
                const elem = document.querySelector("#treeCmp .v-treeview-node--active")
                if (elem!=null)
                    elem.scrollIntoView();
            }, 500);
 
        }
    }

    _searchInTree(xid, arr) {
        for (const obj of arr) {
            if (obj.id == xid) {
                return obj;
            }
            if (obj.children) {
                let ret = this._searchInTree(xid, obj.children);
                if (ret != null) return ret;
            }
        }

        return null;
    }

    _getInfoForSelectorOnIFrame(selector, parent) {
        this.idxGetInfoForSelectorOnIFrame++;
        const idx = this.idxGetInfoForSelectorOnIFrame;
        const prom = getPromise(`getInfoForSelectorOnIFrame${idx}`);
        const winFrame = document.querySelector("#rootFrame").contentWindow;
        winFrame.postMessage({ "action": "getInfoForSelector", "selector": selector, "parent": parent, "idx": idx }, "*");
        return prom;
    }

    ///////////////////////////////////////////////
    ////////////////////////////////////////////    A changer
    ///////////////////////////////////////////////
    _getlistNodeOnIFrame(xid) {
        let ret = null;
        try {
            ret = document.querySelector("#rootFrame").contentDocument.querySelectorAll(`[data-xid-slot=${xid}]`);
        } catch (error) {
            alert(`getlistNodeOnIFrame on error${error}`);
        }
        return ret;
    }
    
    async getBoundFromXid(xid) {
         // recherche xid simple
         let elemRect = await this._getInfoForSelectorOnIFrame(`[data-xid=${xid}]`);

         if (elemRect != null) {
            return elemRect;
         }
 
         if (elemRect == null) {
             elemRect = await this._getInfoForSelectorOnIFrame(`[data-xid-slot-${xid}=true]`);
             if (elemRect != null) {
                 return elemRect;
             }
         }
 
         // recherche xid de slot invisible sur les div enfant => realise un merge des clientRect
         if (elemRect == null) {
             const listNode = this._getlistNodeOnIFrame(xid);
             //console.debug("displaySelectorByXid 31 ", xid, listNode);
 
             if (listNode != null && listNode.length > 0 && listNode.length == listNode[0].parentNode.children.length) {
                 const parent = true;
                 elemRect = await this._getInfoForSelectorOnIFrame(`[data-xid-slot=${xid}]`, parent);
                 if (elemRect != null && (elemRect.width != 0 && elemRect.height != 0)) {
                     //console.debug("displaySelectorByXid 32 ", xid);
                     return elemRect;
                 }
             }
 
             if (listNode != null && listNode.length > 0) {
                 // gestion des d'intersection des region des enfants
                 let myRegion = null;
                 for (const aNode of listNode) {
                     elemRect = aNode.getBoundingClientRect();
                     if (elemRect.width == 0 || elemRect.height == 0) {
                         console.debug("error get rec", elemRect, xid);
                         continue;
                     }
 
                     if (myRegion == null)
                         myRegion = new Region2D(elemRect);
                     else
                         myRegion = myRegion.union(new Region2D(elemRect));
                 }
                 //console.debug("displaySelectorByXid 4 ", xid);
                 if (myRegion != null)
                     return myRegion.getBounds();
             }
             else {
                // console.debug("displaySelectorByXid 5 no found ", xid);
             }
         }
    }


    /************************************************************************************ */
    // selection par click des properties
    async displaySelectorByXid(xid, xid_slot, noDisplayProp) {

        this.unDisplaySelector();

        if ($xui.hasPropertiesChanged) {
            /*******************************************************/
            // sauvegarde automatique
            /*******************************************************/
            $xui.saveProperties()
            return;
        }

        const elemInfo=  await this.getBoundFromXid(xid);
        if (elemInfo!=null)
            this.displaySelectorByPosition(elemInfo);

       
        if (!noDisplayProp) {
            // affiche les properties sur le click (pas sur le survole des properties)
            $xui.modeDisplaySelection = true;
            setTimeout(() => {
                $xui.displayPropertiesJS(xid, xid_slot);
            }, 10);


        }
    }
}