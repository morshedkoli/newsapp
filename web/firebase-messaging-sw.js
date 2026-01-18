importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyB24LKrdGn6phkDuuB7tAGrH_iX-t3Qn7M",
  authDomain: "ainews-f6d83.firebaseapp.com",
  projectId: "ainews-f6d83",
  storageBucket: "ainews-f6d83.firebasestorage.app",
  messagingSenderId: "125810430014",
  appId: "1:125810430014:web:824a273ad5695d932fc16f"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification handling here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
