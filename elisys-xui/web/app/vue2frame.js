import Vuex from "https://cdn.jsdelivr.net/npm/vuex@3.1.2/dist/vuex.esm.browser.min.js";
import VueRouter from "https://cdn.jsdelivr.net/npm/vue-router@3.5.1/dist/vue-router.esm.browser.min.js";

import * as vue2CmpMgr from "./vue2MgrCmp.js";

// https://codesandbox.io/s/vue-template-o4j2g

Vue.config.devtools = true;
Vue.config.productionTip = false;


/*********************************************************************************/
$xui.createComponentFromTemplate = (idTemplate, dataBinding) => {
	return {
		template: document.querySelector("#" + idTemplate).innerHTML,
		data: () => { return $xui.rootdata; },
		computed: {
			$xui: () => $xui,  // pour les @click="$xui.doXXX()"
			...dataBinding
		}
	}
}

/******************************* INIT DU vue2CmpMgr *******************************/
window.vue2CmpMgr = vue2CmpMgr;

$xui.loadApplicationJS = () => {
	if ($xui.vuejs != null) {
		$xui.vuejs.$destroy();
	}
	else {
		// creation des composants xui/vuejs
		var listFunctCreateCmp = $xui.initComponentVuejs;
		for (const functCreateCmp of listFunctCreateCmp) {
			functCreateCmp();
		}
	}

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

	$xui.store.commit('increment');
	$xui.store.commit('increment');

	/******************************************************************************/

	var dataBinding = Vuex.mapState({ titre: 'count' });
	var darkTheme = document.querySelector("#xui-rootTemplate").attributes["dark"];

	const RootComponent = $xui.createComponentFromTemplate("xui-rootTemplate", dataBinding);

	const configVuetify = {
		theme: {
			dark: ((darkTheme != null) ? true : false),
			themes: {
				light: {
					primary: '#000000',
					secondary: '#424242',
					accent: '#82B1FF',
					error: '#FF5252',
					info: '#2196F3',
					success: '#4CAF50',
					warning: '#FFC107'
				},
				dark: {
					//primary: '#0caf50',
				},
			},
		},
	};


	const defaut = { template: '<div>def</div>' }
	const Unknown = { template: '<div>unknown</div>' }
	const routeMgr = new vue2CmpMgr.ComponentManager();

	const routes = [
		{ path: '/', component: defaut },
		 routeMgr.getRoute('/foo', 'app/frameDesigner.html', 'routeA'),
		 routeMgr.getRoute('/bar', 'app/frameDesigner.html', 'routeB'),
		{ path: '*', component: Unknown }
	]

	$xui.router = new VueRouter({
		routes // short for `routes: routes`
	})

	$xui.vuejs = new Vue({
		el: '#app',
		store: $xui.store,
		router: $xui.router,
		data: $xui.rootdata,
		components: { RootComponent },
		template: "<RootComponent ref='root'></RootComponent>",
		vuetify: new Vuetify(configVuetify),
		errorCaptured: function (err, component, details) {
			console.error(err, component, details);
			alert("vue errorCaptured " + err + " details " + details);
			throw err;
		}
	});
}
