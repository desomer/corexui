import { initializeApp } from "https://www.gstatic.com/firebasejs/9.6.10/firebase-app.js";
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword, setPersistence, browserLocalPersistence, onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/9.6.10/firebase-auth.js";
import { getFirestore, collection, addDoc, getDocs, doc, setDoc } from "https://www.gstatic.com/firebasejs/9.6.10/firebase-firestore.js";



$xui.connect = async () => {
    var login = $xui.getAppState().main.login;
    var password = $xui.getAppState().main.password;
    
    const auth = $xui.firebase.auth;
    signInWithEmailAndPassword(auth, "gauthier.desomer@gmail.com", "toto1234")
    .then((userCredential) => {
        // Signed in 
        const user = userCredential.user;
        console.debug("==========>LOGIN ", user);
        $xui.getAppState().main.showLogin=false;
    })
    .catch((error) => {
        const errorCode = error.code;
        const errorMessage = error.message;
    });
}

$xui.disconnect = async () => {
    const auth = $xui.firebase.auth;
    signOut(auth).then(() => {
      // Sign-out successful.
    }).catch((error) => {
      // An error happened.
    });
}

const initFirebaseData = async () => {
    try {
        const docRef = await addDoc(collection(db, "users"), {
            id: "toto",
            first: "Ada",
            last: "Lovelace",
            born: 1815
        });
        console.log("Document written with ID: ", docRef.id);
    } catch (e) {
        console.error("Error adding document: ", e);
    }

    const cityRef = doc(db, "cities/TT/toto", "LA2");

    await setDoc(cityRef, {
        name: "Los Angeles",
        state: "CA",
        country: "USA3"
    });
    await setDoc(doc(db, "cities", "TT"), {
        country: "EEEE"
    });

    const querySnapshot = await getDocs(collection(db, "users"));
    querySnapshot.forEach((doc) => {
        console.log(`${doc.id} => ${doc.data()}`);
    });
}

$xui.initFirebase = async () => {


    $xui.firebase={};

    // Your web app's Firebase configuration
    const firebaseConfig = {
        apiKey: "AIzaSyA1P5qGw-nhBTyqmDpju47dVtKYK7j0dCs",
        authDomain: "xuielisa-acfaf.firebaseapp.com",
        databaseURL: "https://xuielisa-acfaf.firebaseio.com",
        projectId: "xuielisa-acfaf",
        storageBucket: "xuielisa-acfaf.appspot.com",
        messagingSenderId: "916380438343",
        appId: "1:916380438343:web:db97d82ea885e7a9318662"
    };

    // Initialize Firebase
    const app = initializeApp(firebaseConfig);

    // Initialize Firebase Authentication and get a reference to the service
    const auth = getAuth(app);
    const db = getFirestore(app);

    console.debug("INIT ==========>", app, auth, db);

    $xui.firebase.app=app;
    $xui.firebase.auth=auth;
    $xui.firebase.db=db;

    if (false) {
        createUserWithEmailAndPassword(auth, "gauthier.desomer@gmail.com", "toto1234")
            .then((userCredential) => {
                // Signed in 
                const user = userCredential.user;
                console.debug("==========>", user);
            })
            .catch((error) => {
                const errorCode = error.code;
                const errorMessage = error.message;
                console.error("==========>", errorCode, errorMessage);
                // ..
            });
    }

    onAuthStateChanged(auth, async (user) => {
        if (user) {
            const uid = user.uid;



        } else {
            // User is signed out
            // ...
        }
    });


    setPersistence(auth, browserLocalPersistence)
        .then(() => {
            const user = auth.currentUser;
            if (user) {
                $xui.getAppState().main.login=user.email;
                console.debug("==========>RE LOGIN ", user);
            }
            else {

            }
        })
        .catch((error) => {
            // Handle Errors here.
            const errorCode = error.code;
            const errorMessage = error.message;
        });

}

$xui.initFirebase();

// const provider = new GoogleAuthProvider();

// signInWithPopup(auth, provider)
//   .then((result) => {
//     // This gives you a Google Access Token. You can use it to access the Google API.
//     const credential = GoogleAuthProvider.credentialFromResult(result);
//     const token = credential.accessToken;
//     // The signed-in user info.
//     const user = result.user;
//     // ...
//   }).catch((error) => {
//     // Handle Errors here.
//     const errorCode = error.code;
//     const errorMessage = error.message;
//     // The email of the user's account used.
//     const email = error.email;
//     // The AuthCredential type that was used.
//     const credential = GoogleAuthProvider.credentialFromError(error);
//     // ...
//   });


// initFirebase();

//***********************test de la gestion de lecture de fichier */
var r = async () => {
    // open file picker
    let [fileHandle] = await window.showOpenFilePicker();

    console.debug("fileHandle", fileHandle);

    if (fileHandle.kind === 'file') {
        // run file code
        const fileData = await fileHandle.getFile();
        console.debug(fileData);

        const reader = new FileReader();

        reader.onload = function (evt) {
            console.log(evt.target.result);
        };
        reader.readAsText(fileData);

    } else if (fileHandle.kind === 'directory') {
        // run directory code
    }
}