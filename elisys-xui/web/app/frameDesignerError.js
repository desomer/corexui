/******************************************  LA GESTION DES ERREURS JS   ***********************************************/
const observer = new ReportingObserver((reports, observer) => {
    for (const report of reports) {
        console.log("******************************************", report.type, report.url, report.body, observer);
    }
}, { buffered: true });

console.log("***************start reporting ********************");
observer.observe();

window.onunhandledrejection = function (e) {
    console.log("*************** onunhandledrejection", e);
    alert('Error object: ' + e.reason.message + "\n" + e.reason.stack);
}

window.addEventListener('error', function (e) {

    console.log("*************** error", e);

})

window.onerror = function (msg, url, lineNo, columnNo, error) {
    console.log("***************error reporting OK ********************");
    var string = msg.toLowerCase();
    var substring = "script error";
    if (string.indexOf(substring) > -1) {
        alert('Script Error: See Browser Console for Detail');
    } else {
        var message = [
            'XUI reporting Message: ' + msg,
            'URL: ' + url,
            'Line: ' + lineNo,
            'Column: ' + columnNo,
            'Error object: ' + JSON.stringify(error)
        ].join(' - ');

        alert(message);
    }

    return false;
};

function wrapErrors(fn) {
    // don't wrap function more than once
    if (!fn.__wrapped__) {
        fn.__wrapped__ = function () {
            try {
                return fn.apply(this, arguments);
            } catch (e) {
                captureError(e); // report the error
                throw e; // re-throw the error
            }
        };
    }

    return fn.__wrapped__;
}

function captureError(e) {
    alert(e.message)
    console.debug("------- send info error -------", e)
}

//    wrapErrors(function () {
//    --------
//    })();

console.log("***************start reporting OK ********************");