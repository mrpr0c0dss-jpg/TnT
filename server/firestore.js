const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

let app;
if (admin.getApps().length === 0) {
  let credential = null;

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      const sa = typeof process.env.FIREBASE_SERVICE_ACCOUNT === 'string'
        ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
        : process.env.FIREBASE_SERVICE_ACCOUNT;
      credential = admin.cert(sa);
    } catch (e) {
      console.warn('Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:', e.message);
    }
  } else if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
    credential = admin.cert({
      projectId: process.env.FIREBASE_PROJECT_ID || 'topup-22f94',
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    });
  } else {
    try {
      credential = admin.applicationDefault();
    } catch (e) {
      // Allow fallback if no local ADC file
    }
  }

  const appOptions = {
    projectId: process.env.FIREBASE_PROJECT_ID || 'topup-22f94'
  };
  if (credential) appOptions.credential = credential;

  app = admin.initializeApp(appOptions);
} else {
  app = admin.getApp();
}

const firestore = getFirestore(app);

try {
  firestore.settings({ ignoreUndefinedProperties: true });
} catch (e) {}

module.exports = {
  admin,
  app,
  firestore,
  db: firestore
};
