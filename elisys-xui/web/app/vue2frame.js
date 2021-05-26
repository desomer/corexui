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

	/*********************************** STORE CQRS  *********************************/
	$xui.store = new Vuex.Store({
		state: {
			count: 0    // private
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
				$xui.rootdata.items.push({ key:"c"});
			}
		}
	})

	//  $xui.store.commit('increment', {amount:1});   // appel une mutation
	//  $xui.store.dispatch('inc', 1);    // appel une action

	$xui.storeAction = Vuex.mapActions({
		add: 'inc', // attacher `this.add()` à `this.$store.dispatch('increment')`
		say: 'say'
	});


	// passer la valeur littérale 'count' revient à écrire `state => state.count`
	$xui.storeDataBinding = Vuex.mapState({ titre2: 'count' });   // titre2 mount l'attribut private 'count' du state

	/***********************************  ROUTER   **********************************/
	const defautRoute = vue2CmpMgr.ComponentManager.getComponentFromTemplate("xui-route-default", $xui.storeDataBinding);
	const routes = [
		{ path: '/', component: defautRoute },
		//	vue2CmpMgr.ComponentManager.getRoute('/foo', 'app/frameDesigner.html', 'routeA'),
		//	vue2CmpMgr.ComponentManager.getRoute('/bar', 'app/frameDesigner.html', 'routeB'),
	];

	var i = 0;
	while (true) {
		var idTemplate = "xui-route-"+i;
		console.info("create route <" + idTemplate +"> uri='/route"+i+"'");
		const template = document.querySelector("#" + idTemplate);
		if (template==null) break;
		const infoRoute = vue2CmpMgr.ComponentManager.getComponentFromTemplate(idTemplate, $xui.storeDataBinding);
		routes.push({ path: '/route'+i, component: infoRoute });
		i++;
	}

	const UnknownRoute = { template: '<div>unknown</div>' };
	routes.push({ path: '*', component: UnknownRoute });

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
	const RootComponent = vue2CmpMgr.ComponentManager.getComponentFromTemplate("xui-rootTemplate", $xui.storeDataBinding);
	
	
	/*************************************************************************** */
	//$xui.rootdata.toto="4444";
	// var json = { items:[{ key:"a" }, { key:"b"}]}
	// $xui.rootdata = { ...$xui.rootdata, ...json };


	var allState = Reflect.ownKeys($xui.store.state);
	console.debug("vue store allState ", allState)

	console.debug("vue store compute state ", $xui.storeDataBinding)
	console.debug("vue inner state", $xui.store.state)
	console.debug("vue static data", $xui.rootdata)
	console.debug("vue store", $xui.store);
	console.debug("vue routes", routes);


	$xui.router.afterEach((to, from) => {
		console.log("router going to " + to.fullPath)
		console.log(to);
	  
		// console.log("all ref", $xui.router );
	  })

	/*************************************************************************** */
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
