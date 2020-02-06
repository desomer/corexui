PAGE MANAGENENT SYSTEM  
    eXtends User Inteface = XUI


Engine = converti les fichiers XML vers XUIResource de design et component XUI
    -    XUIResource :  correspond à un fichier XML 
                        utilise les parser
    
Factory =
    -   process phase 1 : creation de element HTML a partir des XUI
         - affecte les implementBy et designBy

    -   process phase 2 : process autour des lien enfant et leur parent  
            (ex NativeSlot : ajoute un slot visible si pas d'enfant)
         - genere les infos de design (info, doc, etc...)

    -   process phase 3 : construit le code HTML

Element =
    -   convertion de elemnentHTML en code HTML au travers du XUIHtmlBuffer
    -   applique les propertiesXUI dans les __xxx__  ou [[xxx]]

    

Netlify
Faunadb
    https://docs.fauna.com/fauna/current/tutorials/crud