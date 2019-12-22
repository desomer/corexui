Vue.config.devtools = true;
Vue.config.productionTip = false;

$xui.loadTemplate= ()=>
{
	$xui.vuejs = new Vue(
	{
		template:'#xui-rootTemplate', 
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