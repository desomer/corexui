document.addEventListener('dragenter', function (e) {
    var slotDroppable = e.target.closest('.xui-class-slot')
    if (slotDroppable) {
        slotDroppable.classList.add("xui-class-dragover");
    }
});

document.addEventListener('dragleave', function (e) {
    var slotDroppable = e.target.closest('.xui-class-slot')
    if (slotDroppable)
        slotDroppable.classList.remove("xui-class-dragover");
});

document.addEventListener('dragover', function (e) {
    var slotDroppable = e.target.closest('.xui-class-slot')
    if (slotDroppable)
        e.preventDefault();
});

document.addEventListener('drop', function (e) {
    var slotDroppable = e.target.closest('.xui-class-slot')
    if (slotDroppable) {
        e.preventDefault();
        var idCmp = e.dataTransfer.getData('text/plain');
        let targetAction = e.target.closest("[data-xid]");
        console.debug("drop ", idCmp, targetAction);
        var message = { action: "drop", xid: targetAction.dataset.xid, xid_slot: targetAction.dataset.xidSlot };
        window.parent.postMessage(message, "*");
    }
});

// Cet événement détecte n'importe quel drag & drop qui se termine, autant le mettre sur « document » :
document.addEventListener('dragend', function () {
});

/***********************************************************************************/

document.addEventListener('pointerdown', e => {
    targetActionStart = e.target.closest("[data-xid]");
});

document.addEventListener('pointerup', function (e) {  
    //console.debug("pointerup", e);
    if (e.button != 0)
        return;

    let targetAction = e.target.closest("[data-xid]");
    if (targetActionStart != targetAction)
        return;  // ne fait rien sur le drag (ex : Split)

    let elemRect = targetAction.getBoundingClientRect();
    let s = getComputedStyle(targetAction);
    let margin = { mb: parseInt(s.marginBottom), mt: parseInt(s.marginTop), ml: parseInt(s.marginLeft), mr: parseInt(s.marginRight) }

    var message = {
        action: "select",
        xid: targetAction.dataset.xid,
        xid_slot: targetAction.dataset.xidSlot,
        position: {
            hasMargin: (margin.mb > 0 || margin.mt > 0 || margin.ml > 0 || margin.mr > 0),
            height: elemRect.height,
            width: elemRect.width,
            left: elemRect.left,
            top: elemRect.top,
            ...margin
        },
    };
    //console.debug("***********message", message, targetAction, targetActionStart);
    window.parent.postMessage(message, "*");
});

document.addEventListener('scroll', function (event) {
    var message = {
        action: "unselect",
    };
    window.parent.postMessage(message, "*");
});

window.addEventListener('resize', function (event) {
    var message = {
        action: "unselect",
    };
    window.parent.postMessage(message, "*");
});

//******************************************************************************* */

window.addEventListener('message', function (e) {
    var data = e.data;
    if (data.action == "changeTemplate") {
        if (data.param.listReloader != null) {
            var uniqReloader = [...new Set(data.param.listReloader)];
            this.console.info("changeTemplate event reloader", data.param.listReloader);

            for (const idReloader of uniqReloader) {
                if ($xui.listReloader[idReloader] != null)
                $xui.listReloader[idReloader].reload();
            else
                this.console.error("+-+-+-+-+-+-+-+-+ pb reloader inconnu", idReloader, $xui.listReloader);
            }
        }
        else {
            this.console.info("changeTemplate event all", data.param);
            let styleXui = this.document.body.querySelector("#xui-style");
            if (styleXui!=null) {
                this.console.debug("+++++++++++>  move style to header")
                styleXui.remove()
                this.document.head.appendChild(styleXui);
            }
            
            this.document.body.innerHTML = data.param.html;
            $xui.loadApplicationJS();
        }
    }
    if (data.action == "changeReloader") {
        //console.debug("load reloader", data.xid, data);
        if ($xui.listReloader[data.xid] == null)
            console.error("changeReloader on error", data, $xui.listReloader);
        $xui.listReloader[data.xid].rload(data);
    }
});

//******************************************************************************* */

$xui.updateDirectPropInnerText = (event, variable, xid, selectAll) => {
    if (selectAll)
        setTimeout(() => { document.execCommand('selectAll', false, null); }, 300);

    var message = {
        action: "updateDirectProp",
        xid: xid,
        xid_slot: xid,
        variable: variable,
        value: event.target.innerText
    };
    window.parent.postMessage(message, "*");
}

$xui.updateDirectPropBlur = () =>
{
    window.getSelection().removeAllRanges();
} 

// ne sert plus
$xui.updateDirectPropValue = (value, variable, xid) => {
    var message = {
        action: "updateDirectProp",
        xid: xid,
        xid_slot: xid,
        variable: variable,
        value: value.target.value
    };
    window.parent.postMessage(message, "*");
}


window.getInfoForSelector = (selector, parent) => {
    var targetAction = document.querySelector(selector)
    if (targetAction == null) return null;
    if (parent)
        targetAction = targetAction.parentNode;

    let elemRect = targetAction.getBoundingClientRect();
    let s = getComputedStyle(targetAction);

    let margin = { mb: parseInt(s.marginBottom), mt: parseInt(s.marginTop), ml: parseInt(s.marginLeft), mr: parseInt(s.marginRight) }

    var ret = {
        selector : selector,
        parent : parent,
        hasMargin: (margin.mb > 0 || margin.mt > 0 || margin.ml > 0 || margin.mr > 0),
        height: elemRect.height,
        width: elemRect.width,
        left: elemRect.left,
        top: elemRect.top,
        ...margin
    };

    return ret;
}