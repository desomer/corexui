
import Vuex from "https://cdn.jsdelivr.net/npm/vuex@3.1.2/dist/vuex.esm.browser.min.js";

// https://codesandbox.io/s/vue-template-o4j2g

Vue.config.devtools = true;
Vue.config.productionTip = false;

/*********************************************************************************/
$xui.createComponent = (idTemplate, dataBinding) => {
	return {
		template: document.querySelector("#"+idTemplate).innerHTML,
		data: () => { return $xui.rootdata; },
		computed: {
			$xui: () => $xui,  // pour les @click="$xui.doXXX()"
			...dataBinding
		}
	}
}
/*********************************************************************************/
$xui.loadApplicationJS = () => {
	if ($xui.vuejs != null)
		$xui.vuejs.$destroy();

	/******************************************/
	$xui.store = new Vuex.Store({
		state: {
			count: 0
		},
		mutations: {
			increment(state) {
				state.count++
			}
		}
	})
	/******************************************/
	$xui.store.commit('increment');
	$xui.store.commit('increment');

	/******************************************/

    var dataBinding = Vuex.mapState( { titre: 'count'});
	const RootComponent = $xui.createComponent("xui-rootTemplate", dataBinding);

	$xui.vuejs = new Vue({
		el: '#app',
		store : $xui.store,
		data : $xui.rootdata,
		components: { RootComponent },
		template: "<RootComponent></RootComponent>",
		vuetify: new Vuetify()
	});
}
