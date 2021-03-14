function waitForXuiLib(key, callback, self) {
    if ($xui[key] != null) {
        callback();
    } else {
        setTimeout(function () { waitForXuiLib(key, callback); }.bind(self), 100);
    }
};

/***************************************************************************************************************/

var dicoPromise = {};

function getPromise(id) {

    var _resolve, _reject;

    var promise = new Promise((resolve, reject) => {
        _reject = reject;
        _resolve = resolve;
    });

    promise.resolve_ex = (value) => {
        _resolve(value);
    };

    promise.reject_ex = (value) => {
        _reject(value);
    };

    if (id != null)
        dicoPromise[id] = promise;

    if (Object.keys(dicoPromise).length>10)
     console.debug("nb promise "+Object.keys(dicoPromise).length, dicoPromise);

    return promise;
}

$xui.doPromiseJS = (idPromise, ret) => {
    if (dicoPromise[idPromise] != null) {
        dicoPromise[idPromise].resolve_ex(ret);
        delete  dicoPromise[idPromise];
    }
}