var json = {

    openDialogClass : false,
    openDialogBinding : false,

    // listeTemplate: [
    //     { name: "Empty", frameName:"frame1", frameTemplate:"template/frameEmpty", size : 2},
    //     { name: "e-Commerce", frameName:"frame1", frameTemplate:"template/frameTest1", picture:"app/template/ecommerce.png", size : 2},
    //     { name: "Blog", frameName:"frame1", frameTemplate:"template/frameArray", size : 2},
    // ],

    //isDesignFrame: true,

    // selectedxui: "PWA Generator",
 
    // urlApp : "",
    // frameTemplate:"template/frameTest1",
    // frameName:"frame1",
    
    contentEditor: '', // pour l'editeur de text   vue-editor

    // pasteDisabled: true,
    // undoDisabled: true,
    // redoDisabled: true,

    /******************************************** */
    // idxTabMain: 0,
    // idxTabProperties: 0,
    // routeEnable : true,
    // actionEnable: true,
    /******************************************** */

    saveLayout: false,
    overlay: false,
    overlayEvent: false,

    openDialogError : false,
    dialogError_text : "error",

    //listPopupAdd: [],
    // messages : [],
    // snackbar: true,
    // snackbar_text: 'initialize in progress...',
    // snackbar_timeout: 3000,

    //listSlot : [],
    // activeSlot : [],
    // openSlot : [],
    //expandAllCmp : false,
    
    //isModePhone : false,

    //stateDataSource : "template",   // ou mock
    // stateData : {},
    // stateDataMock : {},

    jsonEditorOptions : { mode: 'code', onEditable:() => false },
    jsonEditorOptionsMock : { mode: 'code' },

    // ListActions : [],    // liste des actions
    // currentCode : "no code",
    // currentCodeName : "",
    // currentCodeIdx : -1,
    // currentCodeXid : ""
};

$xui.rootdata = { ...$xui.rootdata, ...json };