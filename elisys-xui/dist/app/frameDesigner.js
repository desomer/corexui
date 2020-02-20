if (typeof $xui === 'undefined')
    $xui = {};


window.$xui.load = (html) => {
    // console.debug("load", html);
    document.querySelector("#rootFrame").srcdoc = html;

    setTimeout(() => {
        $xui.displayComponents("", "");
        $xui.displayProperties("root","root")
    }, 1000);

    setTimeout(() => {
        $xui.loadCode(html);
    }, 2000);
};

window.$xui.changeTemplate = (param) => {
    console.debug("change template", param);
    if (param.mode == "template") {
        document.querySelector("#rootFrame").contentWindow.postMessage({ "action": "changeTemplate", "template": param.html }, "*");
    }

    $xui.loadCode(param.html);

};

window.$xui.loadCode = (strCode) => {
    $xui.unDisplaySelector();
    var codeElem = document.querySelector("#xui-code-html");
    if (codeElem != null) {
        const code = Prism.highlight(strCode, Prism.languages.html, 'html');
        codeElem.innerHTML = code;
    }
}

window.$xui.save = () => {
    console.debug("save", $xui.propertiesDesign.json);
    $xui.setDesignProperties("save", $xui.propertiesDesign.json);
}

window.$xui.fullScreen = () => {
    window.$xui.unDisplaySelector();
    window.document.documentElement.requestFullscreen();
}

window.$xui.addCmp = (cmp) => {
    window.$xui.unDisplaySelector();
    console.debug(cmp, $xui.propertiesComponent);
    $xui.addDesign($xui.propertiesComponent.xid, "<xui-design xid="+$xui.propertiesComponent.xid+"><"+cmp.xid+" xid=\""+($xui.propertiesComponent.xid+"-"+cmp.xid)+"\"></"+cmp.xid+"></xui-design>");
}

window.$xui.deleteCmp = (cmp) => {
    window.$xui.unDisplaySelector();
    console.debug(cmp, $xui.propertiesDesign);
    $xui.removeDesign($xui.propertiesDesign.xid, null);
}

window.$xui.selectCmp = (xid, xid_slot)=>{
    $xui.displayProperties(xid, xid_slot);
    $xui.unDisplaySelector();
    var node = document.querySelector("#rootFrame").contentDocument.querySelector("[data-xid="+xid+"]")
    let elemRect = node.getBoundingClientRect();
    $xui.displaySelector(elemRect);
}

window.$xui.dragStart = (item, e)=> {
    $xui.dragItem = item;
    e.dataTransfer.setData('text/plain', ""+item.xid);
    window.$xui.unDisplaySelector();
}

/******************************************************************/

window.$xui.unDisplaySelector = ()=>{ 
	var node = document.getElementById("xui-display-selector");
	if (node!=null) {
        node.style.display="none"; 
    }
};

window.$xui.displaySelector = (position)=>{

	let text =  "";
	var node = document.getElementById("xui-display-selector");
	if (node==null) {
		node = document.createElement("div");           
		node.id="xui-display-selector";
		node.style="position: absolute;background: rgba(204, 205, 255, 0.59); border: 1px solid rgb(64, 37, 226); padding: 5px;  z-index: 1000;";	
        node.addEventListener("click", (e)=> {
              e.currentTarget.style.display="none";   // retire sur le click
        }, {capture: false})

        var nodeAction = document.createElement("div");           
        nodeAction.id="xui-display-selector-action";	
        node.appendChild(nodeAction); 

        document.body.appendChild(node); 
    }

    var posFrame = rootFrame.getBoundingClientRect();
    //node.innerHTML = text;
    node.style.height = position.height+"px";
    node.style.left = (position.left+posFrame.left)+"px";
    node.style.top = (position.top+posFrame.top)+"px";
    node.style.width = position.width+"px";
    node.style.display=null;   //affiche la div de selection

    $xui.rootdata.activeAction=0;

    $xui.displayAction($xui.propertiesDesign.xid, null);

}

window.addEventListener('message', function (e) {
    var data = e.data;
    if (data.action == "select") {
        //  var info = $xui.getInfo(data.xid, data.xid_slot);
        $xui.displaySelector(data.position);

        $xui.displayProperties(data.xid, data.xid_slot);
    }
    if (data.action == "drop") {
        $xui.displayProperties(data.xid, data.xid_slot);
        $xui.displayComponents(data.xid, data.xid_slot);
        $xui.addCmp( $xui.dragItem);
    }
});

$xui.displayProperties = (xid, xid_slot) => {
    $xui.propertiesDesign = $xui.getDesignProperties(xid, xid_slot);
    console.debug("displayProperties", $xui.propertiesDesign);
    $xui.rootdata.selectedxui = $xui.propertiesDesign.path;
    $xui.propertiesDesign.json = $xui.parseJson($xui.propertiesDesign.data);
    $xui.rootDataProperties = { data: $xui.propertiesDesign.json };
    if ($xui.vuejsDesign != null) {
        $xui.vuejsAppPropertiesSetting.$destroy();
    }
    $xui.vuejsAppPropertiesSetting = new Vue({
        template: "<div class='barcustom' id='AppPropertiesSetting' style='overflow-y: scroll; height: calc(100% - 38px);'>" + $xui.propertiesDesign.template + "</div>",
        el: '#AppPropertiesSetting',
        vuetify: new Vuetify(),
        data: $xui.rootDataProperties,
        computed: {
            $xui: function () {
                return window.$xui;
            }
        }
    });
}

$xui.parseJson = (str) => {
    try {
        return JSON.parse(str);
    } catch (error) {
        console.debug("pb parse json" ,error, str);
    }
}

$xui.displayComponents = (xid, xid_slot) => {
    $xui.propertiesComponent = $xui.getComponents(xid, xid_slot);
    console.debug("displayComponents", $xui.propertiesComponent);
    $xui.propertiesComponent.json = $xui.parseJson($xui.propertiesComponent.data);
    $xui.rootDataComponents = { data: $xui.propertiesComponent.json, item:null };
    if ($xui.vuejsDesign != null) {
        $xui.vuejsAppCmpSetting.$destroy();
    }
    $xui.vuejsAppCmpSetting = new Vue({
        template: "<div class='barcustom' id='AppComponents' style='overflow-y: scroll; height: calc(100% - 38px);'>" + $xui.propertiesComponent.template + "</div>",
        el: '#AppComponents',
        vuetify: new Vuetify(),
        data: $xui.rootDataComponents,
        computed: {
            $xui: function () {
                return window.$xui;
            }
        }
    });
}

$xui.callHtml= (str) =>
{
    console.debug(str);
    $xui.rootDataAction = { };
    if ($xui.vuejsAppCmpAction != null) {
        $xui.vuejsAppCmpAction.$destroy();
    }
    $xui.vuejsAppCmpAction = new Vue({
        template: "<div id='xui-display-selector-action' style='position:absolute;bottom:-20px;left: 0px;background: rgba(204, 205, 255, 1); border: 1px solid rgb(64, 37, 226); padding: 0px 5px;  z-index: 1000;'>"+str+"</div>",
        el: '#xui-display-selector-action',
        vuetify: new Vuetify(),
        data: $xui.rootDataAction,
        computed: {
            $xui: function () {
                return window.$xui;
            }
        }
    });
}

$xui.displayAction= (xid, xid_slot) => {

    $xui.getHtmlFrom('final','app/cmpDesignEditor.html', 'bottom-editor');

}