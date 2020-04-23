console.debug("--------start worker-----------");

$xui={};
$xuiworker={};
$xuiworker.doPromiseJS= (ret) => {
    console.debug("doPromiseJS", ret);
}

importScripts('workerXUI.drt.js'); 


onmessage = function (e) {
    console.log('Message reçu depuis le script principal.', this);
    var workerResult = 'Résultat : ' + (e.data[0] * e.data[1]);
    console.log('Envoi du message de retour au script principal');
    $xui.doEvent("JJJJJJJJSSSSSSSSSSSOOOOOOOOOOOOOOONNNNNNNNNN");
    postMessage(workerResult);
}