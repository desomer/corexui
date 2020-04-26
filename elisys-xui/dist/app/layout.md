https://codepen.io/makhtar/pen/YzPJRpX

https://haltu.github.io/muuri/

css grid drag and drop

https://github.com/nathancahill/split/tree/master/packages/split-grid


https://shamasis.net/2009/07/regular-expression-to-validate-css-length-and-position-values/


^\s*[a-zA-Z\-]+\s*[:]{1}\s*[a-zA-Z0-9\s.#]+[;]{1}  regex css  (color:dddd;)
(\d*\.?\d+)\s?(px|em|ex|%|in|cn|mm|pt|pc+)    regex size  

http://gamon.webfactional.com/regexnumericrangegenerator/



https://stackoverflow.com/questions/10189582/regex-to-match-valid-values-for-html-style-attribute



bug a corriger
-----------------

xui-reloader=true   ET  class="[[class@-1]]" -style="[[style@-1]]" 
le reloader devrait rafraichir le parent  V-TAB-ITEM car @-1

    => workaround utiliser un XUI-RELOADER parent (voix XUI-SESSION)

ex
       <v-tab-item class="[[class@-1]]" -style="[[style@-1]]" :transition="false" :reverse-transition="false" eager>
            <!-- eager  desactive le lazyloading -->
            <xui-slot xui-reloader=true xid="[[parent-xid]]-tab-item-[[idx@0+]]" xui-slot-name="tab content [[idx@0+]]">
            </xui-slot>
        </v-tab-item>