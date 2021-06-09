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

    listPopupAdd: [
    ],

    snackbar: true,
    snackbar_text: 'initialize in progress...',
    snackbar_timeout: 3000,

    listSlot : [],
    jsonEditorData : {},
    jsonEditorOptions : { mode: 'code' }
};

$xui.rootdata = { ...$xui.rootdata, ...json };