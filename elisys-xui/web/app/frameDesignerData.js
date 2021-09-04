var json = {
    isDesignFrame: true,
    selectedxui: "PWA Generator",
    pasteDisabled: true,
    undoDisabled: true,
    redoDisabled: true,
    frameName:"frame1",

    activeTab: 0,
    activeAction: 0,
    contentEditor: '',
    saveLayout: false,
    overlay: false,

    listPopupAdd: [
    ],

    snackbar: true,
    snackbar_text: 'initialize in progress...',
    snackbar_timeout: 3000,

    listSlot : [],
    routeEnable : true,
    jsonEditorDataSrc : "template",   // ou mock
    jsonEditorData : {},
    jsonEditorDataMock : {},
    jsonEditorOptions : { mode: 'code', onEditable:() => {return false;} },
    jsonEditorOptionsCode : { mode: 'code' },

    ListActions : [
        { id:"add"}
    ],
    currentCode : "no code"
};

$xui.rootdata = { ...$xui.rootdata, ...json };
//$xui.disableVuex = true;