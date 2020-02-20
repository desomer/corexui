$xui.initVuejs = (vuejs) => {
    vuejs.$watch('activeAction', function(newValue, oldValue) {
        console.debug('The activeAction name was changed from ' + oldValue + ' to ' + newValue + '!');
    }, { deep: true });

    vuejs.$watch('activeTab', function(newValue, oldValue) {
        console.debug('The activeTab name was changed from ' + oldValue + ' to ' + newValue + '!');
        if (newValue==1)
            $xui.loadCode( $xui.codeHtml);

    }, { deep: true });
}