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
    actionEnable: true,
    isModePhone : false,
    jsonEditorDataSrc : "template",   // ou mock
    
    jsonEditorData : {},
    jsonEditorDataMock : {},
    jsonEditorOptions : { mode: 'code', onEditable:() => {return false;} },
    jsonEditorOptionsCode : { mode: 'code' },

    ListActions : [],    // liste des actions
    messages : [
    ],
    currentCode : "no code",
    currentCodeName : "",
    currentCodeIdx : -1,
    currentCodeXid : ""
};

$xui.rootdata = { ...$xui.rootdata, ...json };