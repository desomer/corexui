UI MANAGENENT SYSTEM  
    eXtends User Inteface = XUI


DesignManager  = identifie un onglet de design
    - dictionnaire des Engine
    - gestion d'un cache des fichiers parser

Engine = converti les fichiers XML vers XUIResource de design et component XUI
    -    XUIResource :  correspond à un fichier XML 
                        utilise les parser
                        getObjects et addObjectDesign

    - lancer par initialize + parseXUIFile
    
Factory =
    -   process phase 1 : creation de element HTML a partir des XUI
         - affecte les implementBy et designBy
         - affecte les XUIBinding a partir de prop binding pour la creation des Json de mapping de data

    -   process phase 2 : process autour des lien enfant et leur parent  
            (ex NativeSlot : ajoute un slot visible si pas d'enfant)
         - genere les infos de design (info, doc, etc...)
         - ajoute le code JS dans le cache pour ajout dans la phase3  (processPhase2JS)

    -   process phase 3 : construit le code HTML
        - rechercher des tag de databinding

Element =
    -   convertion de elemnentHTML en code HTML au travers du XUIHtmlBuffer
    -   applique les propertiesXUI dans les __xxx__  ou [[xxx]]


XUIPropertyBinding   : proprerty avec binding
XUIBinding  : attribut json à binder  => permet de creer le json associé


--------------------------------------    

Netlify
Faunadb
    https://docs.fauna.com/fauna/current/tutorials/crud
eval d'import
    https://2ality.com/2019/10/eval-via-import.html

css to json
    https://codepen.io/Cdca12/pen/xJOEqd

copieer clloer excel
https://jsfiddle.net/mowglisanu/zmhg5rwo/

gestion d'api
https://wanago.io/2021/12/27/redux-toolkit-query-typescript/