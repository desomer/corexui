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