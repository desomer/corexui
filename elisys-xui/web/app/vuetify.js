Vue.config.devtools = true;
Vue.config.productionTip = false;

window.addEventListener('message',function(e) {
	var data = e.data;
	if (data.action=="changeTemplate")
	{
		var template = data.template;
		this.document.body.innerHTML=template;
		$xui.loadTemplate();
	}
});

$xui.loadTemplate= ()=>
{
	if ($xui.vuejs!=null)
		$xui.vuejs.$destroy();

    str =document.querySelector("#xui-rootTemplate").innerHTML;

	$xui.vuejs = new Vue(
	{
		template: str,   // pas de cache car en string
		el: '#app', 
		vuetify: new Vuetify(), 
		data: $xui.rootdata,
		computed: {
			$xui : function(){
				return window.$xui;
			}
		}
	});
}
