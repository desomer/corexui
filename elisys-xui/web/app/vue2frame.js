import Vuex from "https://cdn.jsdelivr.net/npm/vuex@3.1.2/dist/vuex.esm.browser.min.js";
import VueRouter from "https://cdn.jsdelivr.net/npm/vue-router@3.5.1/dist/vue-router.esm.browser.min.js";

import * as vue2CmpMgr from "./vue2MgrCmp.js";

// https://codesandbox.io/s/vue-template-o4j2g

Vue.config.devtools = true;
Vue.config.productionTip = false;

Vue.use(Vuex);
Vue.use(VueRouter);

/*********************************************************************************/
// $xui.createComponentFromTemplate = (idTemplate, computeDataBinding) => {
// 	return {
// 		template: document.querySelector("#" + idTemplate).innerHTML,
// 		data: () => { return $xui.rootdata; },
// 		computed: {
// 			$xui: () => $xui,  // pour les @click="$xui.doXXX()"
// 			...computeDataBinding
// 		}
// 	}
// }

/******************************* INIT DU vue2CmpMgr *******************************/
window.vue2CmpMgr = vue2CmpMgr;

$xui.loadApplicationJS = () => {
	if ($xui.vuejs != null) {
		// suppression de vues
		console.debug("Destroy vuejs");
		$xui.vuejs.$destroy();
	}
	else {
		/********************** creation des composants xui/vuejs  *****************/
		var listFunctCreateCmp = $xui.initComponentVuejs;
		for (const functCreateCmp of listFunctCreateCmp) {
			functCreateCmp();
		}
	}

	/*********************************** STORE   *********************************/
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

	// passer la valeur littérale 'count' revient à écrire `state => state.count`
	var storeDataBinding = Vuex.mapState({ titre: 'count' });
	$xui.storeDataBinding=storeDataBinding;

	/***********************************  ROUTER   **********************************/
	//const defaut = { template: '<div>dddd</div>' }
	const defaut = vue2CmpMgr.ComponentManager.getComponentFromTemplate("xui-route-default", storeDataBinding)
	const info = { template: '<div>info</div>' }
	const Unknown = { template: '<div>unknown</div>' }

	const routes = [
		{ path: '/', component: defaut },
		{ path: '/info', component: info },
	//	vue2CmpMgr.ComponentManager.getRoute('/foo', 'app/frameDesigner.html', 'routeA'),
	//	vue2CmpMgr.ComponentManager.getRoute('/bar', 'app/frameDesigner.html', 'routeB'),
		{ path: '*', component: Unknown }
	]

	$xui.router = new VueRouter({
		routes // short for `routes: routes`
	})

	/*********************************** THEME ***********************************/
	var darkTheme = document.querySelector("#xui-rootTemplate").attributes["dark"];
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

	/*********************************** VUEJS ***********************************/
	const RootComponent = vue2CmpMgr.ComponentManager.getComponentFromTemplate("xui-rootTemplate", storeDataBinding);
	//$xui.rootdata.toto="4444";

	$xui.vuejs = new Vue({
		el: '#app',
		store: $xui.store,
		router: $xui.router,
		data: $xui.rootdata,
		components: { RootComponent },
		computed: { ...$xui.storeDataBinding },
		template: "<RootComponent ref='root'></RootComponent>",
		vuetify: new Vuetify(configVuetify),
		errorCaptured: function (err, component, details) {
			console.error(err, component, details);
			alert("vue errorCaptured <" + err + "> details <" + details+">");
			if (details=="render")
			{
				var variab = (""+err).split(' ')[1];
				console.debug("renderer error ====>", variab);
				//$xui.rootdata[variab]="wwsdsdsd";
			}
			throw err;
		}
	});
	//$xui.rootdata.toto2="5555";
	// setTimeout(() => {
	// 	$xui.rootdata.toto2="5555";
	// }, 10000);

	//Vue.set($xui.vuejs, 'toto2');
	//$xui.rootdata.toto="4444";
	//console.debug("$xui.vuejs", $xui.vuejs.toto);
}
