import Vuex from "https://cdn.jsdelivr.net/npm/vuex@3.1.2/dist/vuex.esm.browser.min.js";


// https://codesandbox.io/s/vue-template-o4j2g

Vue.config.devtools = true;
Vue.config.productionTip = false;

/*********************************************************************************/
$xui.createComponent = (idTemplate, dataBinding) => {
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

	Vue.component("v-xui-reloader",
		{
			template: '<component v-bind:is="componentToReload"></component>',       // '<template>loading...</template>',
			props: ['partid'],
			data: () => { return { componentToReload: "", id: 1 }; },
			methods: {
				rload : function (e) {

					var oldId = this.partid+"-"+this.id;
					console.debug("reload "+oldId+" reponse **************", e);
					delete Vue.options.components[oldId];

					this.id++; //passe en composant suivant
					var newId = this.partid+"-"+this.id;
					Vue.component(newId, { template: '<div style="display:inherit">'+ e.template+'</div>' });
					this.componentToReload=newId;
				},
				reload: function () {
					console.debug("reload **************", this.partid);

					var message = {
						action:"load reloader", 
						xid: this.partid, 
					};
					window.parent.postMessage(message, "*");
				}
			},
			mounted: function () {
				this.reload();
				$xui.listReloader[this.partid]=this;
			},
			computed: {
				$xui: () => $xui
			}
		});

	var dataBinding = Vuex.mapState({ titre: 'count' });
	const RootComponent = $xui.createComponent("xui-rootTemplate", dataBinding);

	$xui.listReloader={};
	$xui.vuejs = new Vue({
		el: '#app',
		store: $xui.store,
		data: $xui.rootdata,
		components: { RootComponent },
		template: "<RootComponent ref='root'></RootComponent>",
		vuetify: new Vuetify()
	});
}
