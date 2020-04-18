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

document.addEventListener('mousedown', e => {
    targetActionStart = e.target.closest("[data-xid]");
  });

document.addEventListener('click', function (e) {    //dblclick
    let targetAction = e.target.closest("[data-xid]");
    if (targetActionStart!=targetAction)
        return ;  // ne fait rien sur le drag (ex : Split)

    let elemRect = targetAction.getBoundingClientRect();

    var message = {
        action: "select",
        xid: targetAction.dataset.xid,
        xid_slot: targetAction.dataset.xidSlot,
        position: elemRect
    };
    //console.debug("***********message", message, targetAction, targetActionStart);
    window.parent.postMessage(message, "*");
});

window.addEventListener('message', function (e) {
    var data = e.data;
    if (data.action == "changeTemplate") {
        this.console.debug(data);
        if (data.param.listReloader!=null) {
            this.console.debug($xui.listReloader);
            $xui.listReloader[data.param.listReloader[0]].reload();
        }
        else {
            this.document.body.innerHTML = data.param.html;
            $xui.loadApplicationJS();
        }
    }
    if (data.action == "changeReloader") {
        //console.debug("changeReloader", data, $xui);
        $xui.listReloader[data.xid].rload(data);
    }
});

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