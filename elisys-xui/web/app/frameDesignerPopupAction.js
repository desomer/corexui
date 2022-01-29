
$xui.closePopup = (event) => {
    const popupNode = document.getElementById("xui-display-selector-popup");
    if (popupNode != null && popupNode.style.display == "block") {
        popupNode.style.display = "none";
    }
}


$xui.OpenPopupAction = (event) => {
    //--------------------------------------------------------
    console.debug("OpenPopupAction", event);

    const infoFile = $xui.pageDesignManager.getInfoFile("template");
    const ret = $xuicore.getActionsXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot, "OpenPopupAction");

    $xui.rootdata.idxTabProperties = 5; // affiche la liste des composants
    $xui.modeDisplaySelection=false;  // ne change pas de selection
    $xui.SelectorManager.displayInTree();

    $xui.rootdata.listPopupAdd.length = 0;
    $xui.rootdata.listPopupAdd.push(...ret);

    const popupNode = document.getElementById("xui-display-selector-popup");
    popupNode.style.left = `${event.clientX}px`;
    popupNode.style.top = `${event.clientY}px`;

    let hpopup = 0;

    for (const itemPopup of $xui.rootdata.listPopupAdd) {
        if (itemPopup.type=='divider')
             hpopup+=10;
        else hpopup+=40;
    }

    if (event.clientY + 16 + hpopup > window.innerHeight) {
        const deltaTop = event.clientY + 16 + hpopup - window.innerHeight;
        popupNode.style.top = `${event.clientY - deltaTop}px`;  // ouverture au dessus
    }

    popupNode.style.display = "block";   //affiche la div de selection des actions (itemPopup)
}


$xui.doActionPopup = (actionId) => {
    console.debug("doActionPopup", actionId);
    //--------------------------------------------------------
    const infoFile = $xui.pageDesignManager.getInfoFile("template");

    if (actionId.action == "class") {
        $xui.rootdata.idxTabProperties = 1;  // affiche les style
        setTimeout(() => {
            $xui.openClassEditor(actionId.xid);
        }, 500);
        return true;
    }
    if (actionId.action == "addCmp") {
        $xui.rootdata.idxTabProperties = 4;  // affiche les style
        return true;
    }

    $xui.rootdata.idxTabProperties = 4;  // affiche la liste des composants

    if (actionId.action == "incNbAfter") {
        $xui.setCurrentAction("addSlot");
        $xuicore.changeNbChildXUI(infoFile, actionId.xid, "after");
        console.debug("doActionPopup incNb OK");
        return true;
    }

    if (actionId.action == "incNbBefore") {
        $xui.setCurrentAction("addSlot");
        $xuicore.changeNbChildXUI(infoFile, actionId.xid, "prev");
        console.debug("doActionPopup incNb OK");
        return true;
    }

    if (actionId.action == "addFlow") {
        $xui.setCurrentAction("addCmp");
        $xui.addCmpXID(actionId.xid, "xui-flow");
        console.debug("doActionPopup addFlow OK");
        return true;
    }

    if (actionId.action == "surround") {
        const info = $xuicore.getInfoXUI(infoFile, actionId.xid, actionId.xid);
        $xui.doSurroundCmp(info, infoFile, actionId);
        return true;
    }
}


$xui.doSurroundCmp = (info, infoFile, actionId) => {
    $xui.setCurrentAction("addSlot");
    let cmp = { xid: actionId.type };
    const newXid = $xui.getNewXid(info.parentXid, actionId.type);
    const currentXid = info.parentXid;
    const template = `<xui-design xid="${currentXid}"><${cmp.xid} xid="${newXid}"></${cmp.xid}></xui-design>`;
    $xuicore.surroundDesignXUI(infoFile, actionId.xid, template, newXid, actionId.slot);
}

$xui.onActionOver= async (state, item) => 
{
    console.debug(`onAction : ${state}`, item);
    let node = document.getElementById("xui-action-selector");
    if (node == null) {
        /************************************************* */
        // le node selector draggable
        node = document.createElement("div");
        node.id = "xui-action-selector";
        node.classList.add("xui-action-selector");

        nodeTop = document.createElement("div");
        nodeTop.id = "xui-action-selector-arrow";
        node.appendChild(nodeTop);

        document.body.appendChild(node);
    }
    if (state=="enter") {
        let position=  await $xui.SelectorManager.getBoundFromXid(item.xid);
        if (position==null)
        {   // pas des xui flow
            position=  await $xui.SelectorManager.getBoundFromXid($xui.rootdata.listPopupAdd[0].xid);
        }
        if (position!=null)
        {
            const winFrame = document.querySelector("#rootFrame");
            const posFrame = winFrame.getBoundingClientRect();
            // ne depasse pas de l'iframe
            const pt = Math.max(0, position.top);
            const ph = Math.min((position.top - pt) + position.height, posFrame.height - pt);
    
            node.style.left = `${position.left + posFrame.left}px`;
            node.style.top = `${pt + posFrame.top}px`;
            node.style.height = `${ph}px`;
            node.style.width = `${position.width}px`;
            node.style.display = null;   //affiche la div de selection

            var nodeTop = document.getElementById("xui-action-selector-arrow");
            nodeTop.removeAttribute('class');

            if (item.title.includes("row") && item.title.includes("before"))
                nodeTop.classList.add("xui-action-selector-top");
            else if (item.title.includes("row") && item.title.includes("after"))
                nodeTop.classList.add("xui-action-selector-bottom");
            else if (item.title.includes("column") && item.title.includes("before"))
                nodeTop.classList.add("xui-action-selector-left");
            else if (item.title.includes("column") && item.title.includes("after"))
                nodeTop.classList.add("xui-action-selector-right");
            else if (item.title.includes("slot") && item.title.includes("before"))
                nodeTop.classList.add("xui-action-selector-left");
            else if (item.title.includes("slot") && item.title.includes("after"))
                nodeTop.classList.add("xui-action-selector-right");
        }
    }
    else
    {
        node.style.display = "none";
    }

}

/*******************************************LES ACTIONS DELETE, ADD, EDIT**************************************************/
let cacheHtmlAction = null;

$xui.displayAction = (xid, xid_slot) => {
    if (cacheHtmlAction == null) {
        var infoFile = { file: 'app/cmpDesignPropEditor.html', xid: 'bottom-editor', mode: 'final' };
        var prom = getPromise("displayActionPromise");
        $xuicore.getHtmlFromXUI(infoFile, "displayActionPromise");
        prom.then(html => {
            $xui.rootDataAction = {};
            if ($xui.vuejsAppCmpAction != null) {
                $xui.vuejsAppCmpAction.$destroy();
            }
            $xui.vuejsAppCmpAction = new Vue({
                template: `<div id='xui-display-selector-action' style='position:absolute;bottom:-20px;left: 0px;background: rgba(204, 205, 255, 1); border: 1px solid rgb(64, 37, 226); padding: 0px 5px;  z-index: 1000;'>${html}</div>`,
                el: '#xui-display-selector-action',
                vuetify: new Vuetify(),
                data: $xui.rootDataAction,
                computed: {
                    $xui() {
                        return window.$xui;
                    }
                }
            });
            cacheHtmlAction = html;
        });
    }

}
/***************************************************************************************************************/

$xui.displayPropActionByXid= (xid, xid_slot) => {
    console.debug("displayPropActionByXid ", xid);
};



