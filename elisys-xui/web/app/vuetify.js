Vue.config.devtools = true;
Vue.config.productionTip = false;

$xui.loadTemplate= ()=>
{
	if ($xui.vuejs!=null)
		$xui.vuejs.$destroy();

	var str =document.querySelector("#xui-rootTemplate").innerHTML;

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
