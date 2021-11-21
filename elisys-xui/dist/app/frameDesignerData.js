var json = {


    listeTemplate: [
        { name: "Empty", frameName:"frame1", frameTemplate:"template/frameEmpty", size : 2},
        { name: "e-Commerce", frameName:"frame1", frameTemplate:"template/frameTest1", size : 2},
        { name: "Blog", frameName:"frame1", frameTemplate:"template/frameTest2", size : 2},
    ],

    isDesignFrame: true,
    selectedxui: "PWA Generator",
    pasteDisabled: true,
    undoDisabled: true,
    redoDisabled: true,
    frameTemplate:"template/frameTest1",
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
    activeSlot : [],
    openSlot : [],
    expandAll : false,
    
    routeEnable : true,
    jsonEditorDataSrc : "template",   // ou mock
    jsonEditorData : {},
    jsonEditorDataMock : {},
    jsonEditorOptions : { mode: 'code', onEditable:() => {return false;} },
    jsonEditorOptionsCode : { mode: 'code' },

    ListActions : [
        { id:"add"}
    ],
    messages : [
    ],
    currentCode : "no code"
};

$xui.rootdata = { ...$xui.rootdata, ...json };