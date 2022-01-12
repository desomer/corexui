
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

    $xui.rootdata.idxTabProperties = 4; // affiche la liste des composants

    $xui.rootdata.listPopupAdd.length = 0;
    $xui.rootdata.listPopupAdd.push(...ret);

    const popupNode = document.getElementById("xui-display-selector-popup");
    popupNode.style.left = `${event.clientX}px`;
    popupNode.style.top = `${event.clientY}px`;

    const hpopup = 16 + (40 * $xui.rootdata.listPopupAdd.length);

    if (event.clientY + 100 + hpopup > window.innerHeight) {
        popupNode.style.top = `${event.clientY - hpopup}px`;  // ouverture en dessus
    }

    popupNode.style.display = "block";   //affiche la div de selection des actions (itemPopup)
}


$xui.doActionPopup = (actionId) => {
    console.debug("doActionPopup", actionId);
    //--------------------------------------------------------
    let infoFile = $xui.pageDesignManager.getInfoFile("template");


    $xui.rootdata.idxTabProperties = 4;  // affiche la liste des composants

    if (actionId.action == "incNbAfter") {
        $xui.setCurrentAction("addFlow");
        $xuicore.changeNbChildXUI(infoFile, actionId.xid, "after");
        console.debug("doActionPopup incNb OK");
        return true;
    }


    if (actionId.action == "incNbBefore") {
        $xui.setCurrentAction("addFlow");
        $xuicore.changeNbChildXUI(infoFile, actionId.xid, "prev");
        console.debug("doActionPopup incNb OK");
        return true;
    }


    let info = $xuicore.getInfoXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot);
    let infoParent = $xuicore.getInfoXUI(infoFile, info.parentXid, info.parentXid);
    console.debug("info add action ", $xui.propertiesDesign, info, infoParent);

    if (actionId.action == "addFlow") {
        $xui.setCurrentAction("addCmp");
        $xui.addCmpXID($xui.propertiesDesign.xidSlot, "xui-flow");
        console.debug("doActionPopup addFlow OK");
        return true;
    }

    if (actionId.action == "surroundLeft") {
        $xui.setCurrentAction("addFlow");
        let cmp = { xid: 'xui-flow' };
        const newXid = $xui.getNewXid(info.parentXid, 'xui-flow');
        const currentXid = info.parentXid;
        const template = `<xui-design xid="${currentXid}"><${cmp.xid} xid="${newXid}"></${cmp.xid}></xui-design>`;
        $xuicore.surroundDesignXUI(infoFile, $xui.propertiesDesign.xid, template, newXid, "-col-1");
        return true;
    }

    if (actionId.action == "surroundRight") {
        $xui.setCurrentAction("addFlow");
        let cmp = { xid: 'xui-flow' };
        const newXid = $xui.getNewXid(info.parentXid, 'xui-flow');
        const currentXid = info.parentXid;
        const template = `<xui-design xid="${currentXid}"><${cmp.xid} xid="${newXid}"></${cmp.xid}></xui-design>`;
        $xuicore.surroundDesignXUI(infoFile, $xui.propertiesDesign.xid, template, newXid, "-col-0");
        return true;
    }

    if (actionId.action == "surroundBadge") {
        $xui.setCurrentAction("addFlow");
        const cmp = { xid: 'xui-badge-1' };
        const newXid = $xui.getNewXid(info.parentXid, 'xui-badge-1');
        const currentXid = info.parentXid;
        const template = `<xui-design xid="${currentXid}"><${cmp.xid} xid="${newXid}"></${cmp.xid}></xui-design>`;
        $xuicore.surroundDesignXUI(infoFile, $xui.propertiesDesign.xid, template, newXid, "-col-0");
        return true;
    }
    if (actionId.action == "surroundBlock") {
        $xui.setCurrentAction("addFlow");
        const cmp = { xid: 'xui-block' };
        const newXid = $xui.getNewXid(info.parentXid, 'xui-block');
        const currentXid = info.parentXid;
        const template = `<xui-design xid="${currentXid}"><${cmp.xid} xid="${newXid}"></${cmp.xid}></xui-design>`;
        $xuicore.surroundDesignXUI(infoFile, $xui.propertiesDesign.xid, template, newXid, "-block");
        return true;
    }
    if (actionId.action == "surroundRow") {
        $xui.setCurrentAction("addFlow");
        const cmp = { xid: 'xui-row-1' };
        const newXid = $xui.getNewXid(info.parentXid, 'xui-row-1');
        const currentXid = info.parentXid;
        const template = `<xui-design xid="${currentXid}"><${cmp.xid} xid="${newXid}"></${cmp.xid}></xui-design>`;
        $xuicore.surroundDesignXUI(infoFile, $xui.propertiesDesign.xid, template, newXid, "-col-0");
        return true;
    }

    if (actionId.action == "surroundCol") {
        $xui.setCurrentAction("addFlow");
        const cmp = { xid: 'xui-column-responsive-1' };
        const newXid = $xui.getNewXid(info.parentXid, 'xui-column-responsive-1');
        const currentXid = info.parentXid;
        const template = `<xui-design xid="${currentXid}"><${cmp.xid} xid="${newXid}"></${cmp.xid}></xui-design>`;
        $xuicore.surroundDesignXUI(infoFile, $xui.propertiesDesign.xid, template, newXid, "-col-0");
        return true;
    }

    if (actionId.action == "surroundOver") {
        $xui.setCurrentAction("addFlow");
        const cmp = { xid: 'xui-over-1' };
        const newXid = $xui.getNewXid(info.parentXid, 'xui-over-1');
        const currentXid = info.parentXid;
        const template = `<xui-design xid="${currentXid}"><${cmp.xid} xid="${newXid}"></${cmp.xid}></xui-design>`;
        $xuicore.surroundDesignXUI(infoFile, $xui.propertiesDesign.xid, template, newXid, "-col-0");
        return true;
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
                template: "<div id='xui-display-selector-action' style='position:absolute;bottom:-20px;left: 0px;background: rgba(204, 205, 255, 1); border: 1px solid rgb(64, 37, 226); padding: 0px 5px;  z-index: 1000;'>" + html + "</div>",
                el: '#xui-display-selector-action',
                vuetify: new Vuetify(),
                data: $xui.rootDataAction,
                computed: {
                    $xui: function () {
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