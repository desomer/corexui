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
globalThis.vue2CmpMgr = vue2CmpMgr;
globalThis.Vuex = Vuex;

$xui.rootdata.animationNameEnter = "animate__animated animate__fadeInUp";
$xui.rootdata.animationNameExit = "";

$xui.routeEnable = true;
$xui.actionEnable = true;

$xui.info={};

$xui.loadApplicationJS = () => {

	$xui.logger = (store) => {
		store.subscribe((event, store) => {
			console.log(`%c MUTATION ${event.type} `, "color: #03A9F4; font-weigth: bold; background-color: #eee", event.payload, store);
		});
	};

	if ($xui.vuejs != null) {
		// suppression de vues
		console.debug("Destroy vuejs");
		$xui.vuejs.$destroy();
	}
	else {
		/********************** creation des composants une seule fois xui/vuejs  *****************/
		initDirective();

		const listFunctCreateCmp = $xui.initComponentVuejs;
		for (const functCreateCmp of listFunctCreateCmp) {
			functCreateCmp();
		}
	}

	//initStore();
	//var modulesManager = null;
	//if (globalThis.initialiseAppState!=null)
	//{
	//console.debug("********************* initialiseAppState OK *******************************************");
	const modulesManager = globalThis.initialiseAppState();
	//}
	// else {
	// 	console.debug("********************* error initialiseAppState NOK *******************************************");
	// 	modulesManager = new VuexModuleManager();
	// 	const main = modulesManager.addModule("main", $xui.rootdata);
	// 	modulesManager.setStore(new Vuex.Store({
	// 		modules: {
	// 			main,
	// 		},
	// 		plugins: [$xui.logger],
	// 		strict: true
	// 	}));
	// }


	$xui.mixinStore = modulesManager.getMixin();
	$xui.modulesManager = modulesManager;

	$xui.rootdata = modulesManager.getStore().state.main;

	/***********************************  ROUTER   **********************************/
	initRouter();

	/*********************************** THEME ***********************************/
	var darkTheme = document.querySelector("#xui-root-template").attributes["dark"];
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
	const RootComponent = vue2CmpMgr.ComponentManager.getComponentFromTemplate("xui-root-template");

	/*************************************************************************** */
	//$xui.rootdata.toto="4444";
	// var json = { items:[{ key:"a" }, { key:"b"}]}
	// $xui.rootdata = { ...$xui.rootdata, ...json };

	//var allState = Reflect.ownKeys($xui.store.state);
	//console.debug("vue store allState ", allState)

	//console.debug("vue store compute state ", $xui.computeDataBinding)
	//console.debug("vue inner state", $xui.store.state)
	//console.debug("vue static data", $xui.rootdata)
	//console.debug("vue store", $xui.store);
	//console.debug("vue routes", routes);

	/*************************************************************************** */
	$xui.vuejs = new Vue({
		el: '#app',
		router: $xui.router,
		store: modulesManager.getStore(),
		mixins: [$xui.mixinStore],
		components: { RootComponent },
		computed: { ...$xui.computeDataBinding },
		template: "<RootComponent ref='root'></RootComponent>",
		vuetify: new Vuetify(configVuetify),
		errorCaptured: function (err, component, details) {
			console.error(err, component, details);
			alert("vue errorCaptured <" + err + "> details <" + details + ">");
			if (details == "render") {
				var variab = ("" + err).split(' ')[1];
				console.debug("renderer error ====>", variab);
			}
			throw err;
		}
	});

}


function initRouter() {
	
	const routes = [];
	let idxPage = 0;
	let pageName = `page-${idxPage}`;

	while (document.querySelector(`#${pageName}`)!=null) {
		const defautRouteDef = vue2CmpMgr.ComponentManager.getRouteFromTemplate(pageName, `${pageName}-route-0`);
		const children = [
			{ path: '', component: defautRouteDef }
		];

		let idxRoute = 1;
		while (true) {
			const idTemplate = `${pageName}-route-${idxRoute}`;
			const page = document.querySelector(`#${pageName}`);
			const template = page.content.querySelector(`#${idTemplate}`);
			if (template == null) break;

			console.info(`create route <${idTemplate}> uri='/route${idxRoute}'`);
			const infoRoute = globalThis.vue2CmpMgr.ComponentManager.getRouteFromTemplate(pageName, idTemplate);
			children.push(
				{ 
				 path: `route${idxRoute}`, 
				 component: infoRoute,
				 name: idTemplate,
				});
			idxRoute++;
		}

		const pageRoute = vue2CmpMgr.ComponentManager.getComponentFromTemplate(pageName);
		var path = "/";
		if (idxPage > 0) {
			path = `/page${idxPage}`;
		}
		routes.push(
			{
				path: path,
				component: pageRoute,
				children: children,
				name: pageName
			},
		);
		idxPage++;
		pageName = `page-${idxPage}`;
	}


	const UnknownRoute = { template: '<div>unknown</div>' };
	routes.push({ path: '*', component: UnknownRoute });

	$xui.router = new VueRouter({
		routes, // short for `routes: routes`
		scrollBehavior_disable (to, from, savedPosition) {
			console.debug("scrollBehavior", to, from, savedPosition);
			return { x: 0, y: 0 };
			// if (savedPosition) {
			//   return savedPosition
			// } else {
			//   return { x: 0, y: 0 }
			// }
		  }
	})

	initEventRouter();

}


function initStore() {
	var mutations = {
		increment(state, info) {
			console.debug("-------event info = ", info);
			state.count += info.amount;
		},
		mutate(state, payload) {
			console.debug("-------event mutate = ", state, payload);
			Vue.set(state, payload.property, payload.value);
		},
	};

	var actions = {
		add(context, payload) {

			context.commit({
				type: 'increment',
				amount: payload
			});

			context.state.titre += payload;
		},

		say(context, event) {
			console.debug("message say", context, event, this);
			$xui.rootdata.items.push({ "key": "c" });
		}
	};

	var getters = {
		$xui: () => $xui
	};



	/*********************************** STORE CQRS  *********************************/
	$xui.store = new Vuex.Store({
		state: {
			count: 0,
			...$xui.rootdata
		},
		mutations: mutations,
		getters: getters,
		actions: actions
	});

	// generique
	$xui.store.commit('mutate', {
		property: 'count',
		value: 12
	}, {
		root: true // don't forget to pass this second argument when you want to call a root mutation
	});

	$xui.store.commit('increment', { amount: 3 }); // appel une mutation


	//  $xui.store.dispatch('inc', 1);    // appel une action
	// $xui.storeAction = Vuex.mapActions({
	// 	add: 'inc', // attacher `this.add()` à `this.$store.dispatch('increment')`
	// 	say: 'say'
	// });
	// passer la valeur littérale 'count' revient à écrire `state => state.count`
	//$xui.storeDataBinding = Vuex.mapState({ titre2: 'count' });   // titre2 mount l'attribut private 'count' du state
	var allState = Reflect.ownKeys($xui.store.state);
	var allGetters = Reflect.ownKeys(getters);
	var allMutations = Reflect.ownKeys(mutations);
	var allActions = Reflect.ownKeys(actions);

	$xui.mixinStore = {
		methods: {
			...Vuex.mapMutations(allMutations),
			...Vuex.mapActions(allActions)
		},
		computed: {
			...Vuex.mapState(allState),
			...Vuex.mapGetters(allGetters)
		}
	};

	console.debug("mixin store", $xui.mixinStore);
}

//------------------------------------------------------------------------------------------------------
function initEventRouter() {
	$xui.router.beforeEach((to, from, next) => {
		next($xui.routeEnable); // si false =>  pas de routage
		if ($xui.routeEnable && to.fullPath!=from.fullPath) {
			const message = {
				action: "changeRoute",
			};
			window.parent.postMessage(message, "*");
		}
	});

	$xui.router.afterEach((to, from) => {
		console.log(`router going to ${to.fullPath} from ${from.fullPath}`);
		console.log(to, from);

		const el = document.querySelector(".v-main__wrap");
		if (el == null)
			return;
		const scrollPos = window.scrollY;
		const exitElem = el.firstChild;
		const exitElemscrollHeight = exitElem.scrollHeight;

		// force le retour en haut du scroll en debut d'animation
		exitElem.style.position = 'absolute';
		exitElem.style.height = `${exitElemscrollHeight}px`;
		exitElem.style.top = `-${scrollPos}px`;
		window.scrollTo(0, 0);

		if (to.fullPath == "/") {
			$xui.rootdata.animationNameEnter = "xui-transition-down animate__animated animate__fadeInUp"; 
			$xui.rootdata.animationNameExit = "xui-transition animate__animated animate__fadeOutDown";
		}
		else {
			$xui.rootdata.animationNameEnter = "xui-transition animate__animated animate__fadeInUp";
			$xui.rootdata.animationNameExit = "xui--transition-down animate__animated animate__fadeOutDown";
		}
	});
}

function initDirective() {
	console.debug("*** add directive ***");
	Vue.directive('bottomnavigationhideonscroll', {
		// Quand l'élément lié est inséré dans le DOM...
		inserted(el, binding) {
			let lastScroll = 0;
			let bottomIsShow = true;
			window.addEventListener('scroll', (e) => {

				if (!bottomIsShow && lastScroll > window.scrollY) // remonte
				{
					var el = document.querySelector(".v-bottom-navigation");
					el.style.transform = "none";
					bottomIsShow = true;
				}
				else if (window.scrollY > document.body.scrollHeight - document.body.offsetHeight - 30) 
				{ 
					// tous en bas
					var el = document.querySelector(".v-bottom-navigation");
					el.style.transform = "none";
					bottomIsShow = true;
				}
				else if (bottomIsShow && lastScroll < window.scrollY) { // descent
					var el = document.querySelector(".v-bottom-navigation");
					el.style.transform = "translateY(100%)";
					bottomIsShow = false;
				}
				lastScroll = window.scrollY;
			});
		}
	});


	// gestion de la direcvtive       v-pressanimation="{link:'/page1'}"  
	Vue.directive('pressanimation', {
		// Quand l'élément lié est inséré dans le DOM...
		inserted(el, binding) {
			// L'élément prend le focus
			//console.debug("------------------------------v-pressAnimation", el, binding);
			el.classList.add('clickAnimation');
			el.addEventListener('click', (e) => {
				if (el.classList.contains('clickAnimationPress')) {
					el.classList.remove('clickAnimationPress');
				} else {
					el.classList.add('clickAnimationPress');
					setTimeout(() => {
						//console.debug(e);
						el.classList.remove('clickAnimationPress');
						$xui.router.push(binding.value.link);
					}, 100);
				}
			});
		}
	});
}

