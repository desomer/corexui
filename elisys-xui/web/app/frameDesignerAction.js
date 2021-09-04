
$xui.closePopup = (event) => {
    var popupNode = document.getElementById("xui-display-selector-popup");
    if (popupNode != null && popupNode.style.display == "block") {
        popupNode.style.display = "none";
    }
}


$xui.OpenPopupAction = (event) => {
    //--------------------------------------------------------
    console.debug("OpenPopupAction", event);

    let infoFile = $xui.pageDesignManager.getInfoFile("template");
    var ret = $xuicore.getActionsXUI(infoFile, $xui.propertiesDesign.xid, $xui.propertiesDesign.xidSlot, "OpenPopupAction");

    $xui.rootdata.activeAction = 4; // affiche la liste des composants


    $xui.rootdata.listPopupAdd.length = 0;
    $xui.rootdata.listPopupAdd.push(...ret);

    var popupNode = document.getElementById("xui-display-selector-popup");
    popupNode.style.left = (event.clientX) + "px";
    popupNode.style.top = (event.clientY) + "px";

    var hpopup = 16 + (40 * $xui.rootdata.listPopupAdd.length);

    if (event.clientY + 100 + hpopup > window.innerHeight) {
        popupNode.style.top = (event.clientY - hpopup) + "px";  // ouverture en dessus
    }

    popupNode.style.display = "block";   //affiche la div de selection des actions (itemPopup)
}


$xui.doActionPopup = (actionId) => {
    console.debug("doActionPopup", actionId);
    //--------------------------------------------------------
    let infoFile = $xui.pageDesignManager.getInfoFile("template");


    $xui.rootdata.activeAction = 4;  // affiche la liste des composants

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
        addCmpXID($xui.propertiesDesign.xidSlot, "xui-flow");
        console.debug("doActionPopup addFlow OK");
        return true;
    }

    if (actionId.action == "surroundRight") {
        $xui.setCurrentAction("addFlow");
        let cmp = { xid: 'xui-flow' };
        const newXid = $xui.getNewXid(info.parentXid, 'xui-flow');
        const currentXid = info.parentXid;
        const template = "<xui-design xid=\"" + currentXid + "\"><" + cmp.xid + " xid=\"" + newXid + "\"></" + cmp.xid + "></xui-design>";
        $xuicore.surroundDesignXUI(infoFile, $xui.propertiesDesign.xid, template, newXid);
        return true;
    }

}


/*******************************************LES ACTIONS DELETE, ADD, EDIT**************************************************/
var cacheHtmlAction = null;
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