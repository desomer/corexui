

//--------------------------------------------------------------------------------------------------------
const pause = ms => new Promise(resolve => setTimeout(resolve, ms))

function _initPathTo(pathTo, aSlotTree) {
    let parent = aSlotTree; 
    let hasRouteDefine = false;
    do {
        if (parent.toPath != null) {

            if (parent.toPath.startsWith("router:")) {
                if (!hasRouteDefine) {
                    pathTo.unshift(parent.toPath);
                    hasRouteDefine = true;
                }

            }
            else {
                pathTo.unshift(parent.toPath);
            }
        }
        parent = parent.parent;
    } while (parent != null);
}

$xui.doPathSelectAction = async (pathTo)=> {
    for (const action of pathTo) {
        console.debug("selectCmp pathTo " + action);
        if (action.startsWith("router:")) {
            const url = action.substring(7);
            await $xui.goToRoute(url);
        }
        if (action.startsWith("click:")) {
            var xidc = action.substring(6);
            await $xui.goToClick(xidc);
        }
    }
}

$xui.selectPath = ()=> {
    const state = $xui.vuejs.$store.state;
    const sel = state.main.breadcrumb[$xui.info["main.breadcrumb"]];
    $xui.SelectorManager.displaySelectorByXid(sel.id, sel.id, false);
}

$xui.selectChildPath = ()=> {  
    const state = $xui.vuejs.$store.state;
    const sel = state.main.childrenSlots[$xui.info["main.childrenSlots"]];
    $xui.SelectorManager.displaySelectorByXid(sel.id, sel.id, false);
}

$xui.selectConditionalPath = ()=> { 
    const state = $xui.vuejs.$store.state;
    const sel = state.main.dynamicSlots[$xui.info["main.dynamicSlots"]];
    if (sel.toPath!=null)
    {
        document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "switchValue", "param": { attr: sel.toPath } }, "*");
    } else
    {
        $xui.SelectorManager.displaySelectorByXid(sel.id, sel.id, false);
    }

}

// select le composant a partir du tree
$xui.selectCmp = async () => {
    const rootdata = $xui.getAppState().main;
    console.debug("selectCmp " + rootdata.activeSlot);
    if (!$xui.modeDisplaySelection) 
    {
        $xui.modeDisplaySelection=true;
        return;
    }

    if (rootdata.activeSlot.length>0)
    {
        const pathTo = [];
        _initPathTo(pathTo, rootdata.activeSlot[0]);
        await $xui.doPathSelectAction(pathTo);

        const xid = rootdata.activeSlot[0].id;
        $xui.SelectorManager.displaySelectorByXid(xid, xid, false);
    }
}

// $xui.selectCmpByXid= async (xid) => {
//     const rootdata = $xui.getAppState().main;
//     const listSlot = rootdata.listSlot;

//     if (xid.startsWith("_slot-"))
//     {
//         xid=xid.substring(6);
//     }    
//     console.debug("selectCmpByXid search " + xid);  

//     const found = _searchPathTo(xid, listSlot[0] );
//     if (found!=null)
//     {
//         const pathTo = [];
//         _initPathTo(pathTo, found);
//         await $xui.doPathSelectAction(pathTo);
//     }
// }

$xui.getPathActionByXid= (xid) => {
    const rootdata = $xui.getAppState().main;
    const listSlot = rootdata.listSlot;

    if (xid.startsWith("_slot-"))
    {
        xid=xid.substring(6);
    }    
    console.debug("getPathActionByXid search " + xid);  

    const found = _searchPathTo(xid, listSlot[0] );
    if (found!=null)
    {
        const pathTo = [];
        _initPathTo(pathTo, found);
        return pathTo;
    }
    return null;
}

function _searchPathTo(id, elem) {
    if (elem.id==id)
    {
        return elem;
    }
    if (elem.children!=null)
    {
        for (let index = 0; index < elem.children.length; index++) {
            const child = elem.children[index];
            const ret = _searchPathTo(id, child);
            if (ret!=null) {
                return ret;
            }
        }
    }
    return null;
}


$xui.goToClick =async (xid) => {
    console.debug("goToClick "+xid)
    var str = "[data-xid-slot="+xid+"]";
    var nodetoClick = document.querySelector("#rootFrame").contentWindow.document.querySelectorAll(str);

    if (nodetoClick.length==0)
    {
        nodetoClick=document.querySelector("#rootFrame").contentWindow.document.querySelectorAll(`[data-xid-slot-${xid}=true]`);
    }

    if (nodetoClick.length>0)
        nodetoClick[0].click();
    else
        console.debug("goToClick nofound <"+str+">");
        
    await pause(30); //300
}

$xui.goToRoute =async (url) => {
    if (url.endsWith("/route0")) {
        url = url.substring(0, url.length - 7);
    }
    if (url.startsWith("/page0")) {
        url = url.substring(6, url.length);
    }
    if (url == "") {
        url = "/";
    }
    const router = document.querySelector("#rootFrame").contentWindow.$xui.router;

    if (router.currentRoute.path != url) {
        console.debug("route to", url, router.currentRoute.path);
        router.push(url);
        await pause(400);
    }
}


