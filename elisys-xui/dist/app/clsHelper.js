function waitForXuiLib(key, callback, self) {
    if ($xuicore[key] != null) {
        callback();
    } else {
        setTimeout(function () { waitForXuiLib(key, callback); }.bind(self), 100);
    }
};

// ANCHOR requireXUI  
globalThis.requireXUI = (function () {
    const cache = {};

    async function loadScript(url) {
        if (url.startsWith("http")) {
            await fetch(url)
                .then(response => response.text())
                .then(txt => {
                    const fnBody = `var exports = {};var module = {}\n${txt}\nif(module.exports!=null) return module.exports;\nreturn exports;`;
                    cache[url] = (new Function(fnBody)).call({});
                })
        }
    }

    function resolve(module) {
        //TODO resolve urls
        return module;
    }

    async function require(module) {
        var url = resolve(module);
        if (!Object.prototype.hasOwnProperty.call(cache, url)) {
            await loadScript(url);
        }
        return cache[url];
    }

    function requireCache(module) {
        var url = resolve(module);
        return cache[url];
    }

    require.cache = cache;
    require.resolve = resolve;
    require.requireCache = requireCache;
    require.require = require;
    return require;
}());

/***************************************************************************************************************/

const dicoPromise = {};

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
     console.debug(`nb promise ${Object.keys(dicoPromise).length}`, dicoPromise);

    return promise;
}

globalThis.doPromiseJS = (idPromise, ret) => {
    if (dicoPromise[idPromise] != null) {
        dicoPromise[idPromise].resolve_ex(ret);
        delete  dicoPromise[idPromise];
    }
}