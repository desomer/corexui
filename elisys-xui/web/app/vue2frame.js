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
		/********************** creation des composants une seule fois xui/vuejs  *****************/
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
			increment(state, info) {
				console.debug("-------event info = ", info);
				state.count+=info.amount;
			}
		},
		actions: {
			inc(context, payload) {

				context.commit({
					type: 'increment',
					amount: payload
				  })
				
				  $xui.rootdata.titre+=payload;
			},
			say(context, event) {
				console.debug("message say",context, event, this);
			}
		}
	})

	// $xui.store.commit('increment');
	$xui.store.dispatch('inc', 1)

	$xui.storeAction = Vuex.mapActions({
		add: 'inc', // attacher `this.add()` à `this.$store.dispatch('increment')`
		say: 'say'
	});

	var allState = Reflect.ownKeys($xui.store.state);
	console.debug("allState ", allState)

	// passer la valeur littérale 'count' revient à écrire `state => state.count`
	var storeDataBinding = Vuex.mapState({ titre2: 'count' });
	$xui.storeDataBinding = storeDataBinding;

	/***********************************  ROUTER   **********************************/
	const defautRoute = vue2CmpMgr.ComponentManager.getComponentFromTemplate("xui-route-default", storeDataBinding);
	const routes = [
		{ path: '/', component: defautRoute },
		//	vue2CmpMgr.ComponentManager.getRoute('/foo', 'app/frameDesigner.html', 'routeA'),
		//	vue2CmpMgr.ComponentManager.getRoute('/bar', 'app/frameDesigner.html', 'routeB'),
	];

	var i = 0;
	while (true) {
		var idTemplate = "xui-pagerouter-route-"+i;
		console.info("create route " + idTemplate);
		const template = document.querySelector("#" + idTemplate);
		if (template==null) break;
		const infoRoute = vue2CmpMgr.ComponentManager.getComponentFromTemplate("xui-pagerouter-route-"+i, storeDataBinding);
		routes.push({ path: '/route'+i, component: infoRoute });
		i++;
	}

	const UnknownRoute = { template: '<div>unknown</div>' };
	routes.push({ path: '*', component: UnknownRoute });

	console.debug("---> routes", routes);

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
			alert("vue errorCaptured <" + err + "> details <" + details + ">");
			if (details == "render") {
				var variab = ("" + err).split(' ')[1];
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
