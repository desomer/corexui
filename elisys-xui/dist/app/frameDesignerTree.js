

//--------------------------------------------------------------------------------------------------------
const pause = ms => new Promise(resolve => setTimeout(resolve, ms))

function initPathTo(pathTo) {
    const rootdata = $xui.getAppState().main;
    let parent = rootdata.activeSlot[0];
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
    console.debug(rootdata.activeSlot);
    if (!$xui.modeDisplaySelection) 
    {
        $xui.modeDisplaySelection=true;
        return;
    }

    if (rootdata.activeSlot.length>0)
    {
        const pathTo = [];
        initPathTo(pathTo);

        for (const action of pathTo) {
            if (action.startsWith("router:"))
            {
                const url = action.substring(7);
                await $xui.goToRoute(url);
            }
            if (action.startsWith("click:"))
            {
                var xid = action.substring(6);
                await $xui.goToClick(xid);
            }
        }

        xid = rootdata.activeSlot[0].id;
        $xui.SelectorManager.displaySelectorByXid(xid, xid, false);
    }
}

$xui.goToClick =async (xid) => {
    const node = document.querySelector("#rootFrame").contentWindow.document.querySelectorAll(`[data-xid-slot=${xid}]`);
    if (node.lenght>=0)
        node[0].click();
    await pause(300);
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





