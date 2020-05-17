import Vuex from "https://cdn.jsdelivr.net/npm/vuex@3.1.2/dist/vuex.esm.browser.min.js";
import * as vue2CmpMgr from "./vue2MgrCmp.js";


// https://codesandbox.io/s/vue-template-o4j2g

Vue.config.devtools = true;
Vue.config.productionTip = false;

//console.debug(vue2CmpMgr);
window.vue2CmpMgr = vue2CmpMgr;

/*********************************************************************************/
$xui.createComponentFromBody = (idTemplate, dataBinding) => {
	return {
		template: document.querySelector("#" + idTemplate).innerHTML,
		data: () => { return $xui.rootdata; },
		computed: {
			$xui: () => $xui,  // pour les @click="$xui.doXXX()"
			...dataBinding
		}
	}
}


/*********************************************************************************/
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
	$xui.listReloader = {};
	$xui.nbRefeshReloader = 0;

	Vue.component("v-xui-reloader",
		{
			template: '<component v-bind:is="componentToReload"></component>',
			props: ['partid', 'modedisplay'],
			data: () => { return { componentToReload: "", id: 1 }; },
			methods: {
				rload: function (e) {

					var oldId = this.partid + "-" + this.id;
					//console.debug("reload " + oldId + " reponse **************", e);
					delete Vue.options.components[oldId];

					this.id++; //passe en composant suivant
					var newId = this.partid + "-" + this.id;        //all:unset; box-sizing: inherit;
					Vue.component(newId,
						{ template: '<div style="display:' + this.modedisplay + '">' + e.template + '</div>' });
					this.componentToReload = newId;
					this.$nextTick(function () {
						$xui.nbRefeshReloader--;
						console.debug("nbRefeshReloader ", $xui.nbRefeshReloader);
						if ($xui.nbRefeshReloader == 0) {
							var message = {
								action: "reloader finish",
							};
							window.parent.postMessage(message, "*");
						}
					});
				},
				reload: function () {
					//console.debug("reload **************", this.partid);
					$xui.nbRefeshReloader++;
					var message = {
						action: "load reloader",
						xid: this.partid,
					};
					window.parent.postMessage(message, "*");
				}
			},
			mounted: function () {
				this.reload();
				$xui.listReloader[this.partid] = this;
			},
			computed: {
				$xui: () => $xui
			}
		});

	/******************************************************************************/

	var dataBinding = Vuex.mapState({ titre: 'count' });
	const RootComponent = $xui.createComponentFromBody("xui-rootTemplate", dataBinding);

	const configVuetify = {
		theme: {
			dark: false,
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

	$xui.vuejs = new Vue({
		el: '#app',
		store: $xui.store,
		data: $xui.rootdata,
		components: { RootComponent },
		template: "<RootComponent ref='root'></RootComponent>",
		vuetify: new Vuetify(configVuetify)
	});
}
