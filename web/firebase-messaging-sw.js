// This is the Firebase service worker file for web push notifications.
// It is required for Firebase Messaging to work correctly on the web.

// Import and initialize the Firebase SDK
importScripts(
  "https://www.gstatic.com/firebasejs/10.4.0/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.4.0/firebase-messaging-compat.js"
);

// Initialize Firebase
const firebaseConfig = {
  apiKey: "AIzaSyC3bvpWDksdpYQsyfyluKabZjarnb5z0fw",
  authDomain: "q-auto-asset-manager.firebaseapp.com",
  projectId: "q-auto-asset-manager",
  storageBucket: "q-auto-asset-manager.firebasestorage.app",
  messagingSenderId: "938513065793",
  appId: "1:938513065793:web:73f5b165ffdca3dd4723c0",
  measurementId: "G-NZ7FYLRB02",
};

const app = firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log(
    "[firebase-messaging-sw.js] Received background message ",
    payload
  );
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/flutter-logo.png", // Or any other icon you want
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});

// You can also add logic to save the token to your Firestore database from here
// using a callable cloud function or REST API call.
