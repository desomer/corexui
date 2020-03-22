$xui.initVuejs = (vuejs) => {
    vuejs.$watch('activeAction', function(newValue, oldValue) {
        console.debug('The activeAction name was changed from ' + oldValue + ' to ' + newValue + '!');
    }, { deep: true });

    vuejs.$watch('activeTab', function(newValue, oldValue) {
        console.debug('The activeTab name was changed from ' + oldValue + ' to ' + newValue + '!');
        if (newValue==1)
        {
            $xui.refreshAction('final')
            $xui.loadCode( $xui.codeHtml);
        }

    }, { deep: true });



    Vue.use(Vue2Editor);
    const VueEditor = Vue2Editor.VueEditor
    Vue.component(VueEditor)    //vue-editor
}

// Vue.component('spanEditable',{
//     template:'<span contenteditable="true" @input="update"></span>',
//     props:['content'],
//     mounted:function(){
//       this.$el.innerText = this.content;
//     },
//     methods:{
//       update:function(event){
//         this.$emit('updatekkk',event.target.innerText);
//       }
//     }
//   })

/*
<div id="example">
  <editable :content="text2" @updatekkk="text2 = $event"></editable>
  <div>
    <pre>{{$data |json }}</pre>
  </div>
</div>



var example = new Vue({
  el: '#example',
  data: {
    text2:"This text is editable!"
  }
});

*/