// Firebase SDK Initialization & Analytics Integration
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import { getAnalytics, logEvent } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-analytics.js";
import {
  getAuth,
  GoogleAuthProvider,
  signInWithPopup,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";

export const firebaseConfig = {
  apiKey: "AIzaSyBTsCGa2QvDriHhuQzOR43q_PmqXmtpEf4",
  authDomain: "topup-22f94.firebaseapp.com",
  databaseURL: "https://topup-22f94-default-rtdb.firebaseio.com",
  projectId: "topup-22f94",
  storageBucket: "topup-22f94.firebasestorage.app",
  messagingSenderId: "90105429216",
  appId: "1:90105429216:web:45762ad9c311b646ce6485",
  measurementId: "G-WHDQ2EVHHV"
};

let app = null;
let analytics = null;
let auth = null;

try {
  app = initializeApp(firebaseConfig);
  if (typeof window !== "undefined" && window.location.protocol.startsWith("http")) {
    try { analytics = getAnalytics(app); } catch (e) { console.debug("Analytics note:", e); }
    try { auth = getAuth(app); } catch (e) { console.debug("Auth init note:", e); }
  }
  window.firebaseApp = app;
  window.firebaseAnalytics = analytics;
  window.firebaseAuth = auth;
  window.firebaseConfig = firebaseConfig;
  console.log("⚡ Firebase & Auth Initialized Successfully [Project: topup-22f94]");
} catch (error) {
  console.warn("Firebase initialization warning:", error);
}

// Google Sign-In with Firebase Auth
export async function signInWithGoogle() {
  if (!auth) {
    throw new Error("Firebase Auth is not available in current environment");
  }
  const provider = new GoogleAuthProvider();
  provider.addScope("profile");
  provider.addScope("email");
  provider.setCustomParameters({ prompt: "select_account" });
  return await signInWithPopup(auth, provider);
}

// Email / Gmail Sign-In with Firebase Auth
export async function signInWithEmail(email, password) {
  if (!auth) {
    throw new Error("Firebase Auth is not available in current environment");
  }
  return await signInWithEmailAndPassword(auth, email, password);
}

// Register with Email
export async function registerWithEmail(email, password) {
  if (!auth) {
    throw new Error("Firebase Auth is not available in current environment");
  }
  return await createUserWithEmailAndPassword(auth, email, password);
}

// Sign Out Firebase
export async function logOutFirebase() {
  if (auth) {
    await signOut(auth);
  }
}

export function trackAnalyticsEvent(eventName, params = {}) {
  try {
    if (analytics) {
      logEvent(analytics, eventName, params);
    }
  } catch (err) {
    console.debug("Analytics event dispatch note:", err);
  }
}

window.signInWithGoogle = signInWithGoogle;
window.signInWithEmail = signInWithEmail;
window.registerWithEmail = registerWithEmail;
window.logOutFirebase = logOutFirebase;
window.trackAnalyticsEvent = trackAnalyticsEvent;

export { app, analytics, auth };

