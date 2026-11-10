const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let isFirebaseAdminInitialized = false;

const initFirebaseAdmin = () => {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './config/serviceAccountKey.json';
  const resolvedPath = path.resolve(serviceAccountPath);

  if (fs.existsSync(resolvedPath)) {
    try {
      const serviceAccount = require(resolvedPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      isFirebaseAdminInitialized = true;
      console.log('[FCM] Firebase Admin SDK initialized successfully.');
    } catch (err) {
      console.warn(`[FCM Warning] Failed to initialize Firebase Admin: ${err.message}`);
    }
  } else {
    console.log('[FCM Info] No serviceAccountKey.json found. Push notifications will run in simulation mode.');
  }
};

initFirebaseAdmin();

const sendPushNotification = async (fcmToken, { title, body, data = {} }) => {
  if (!fcmToken) return false;

  if (isFirebaseAdminInitialized) {
    try {
      const message = {
        token: fcmToken,
        notification: { title, body },
        data: Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
        android: {
          priority: 'high',
          notification: {
            channelId: 'kidshield_emergency_channel',
            sound: 'default',
          },
        },
      };
      await admin.messaging().send(message);
      console.log(`[FCM Success] Push notification sent to token: ${fcmToken.substring(0, 10)}...`);
      return true;
    } catch (error) {
      console.error(`[FCM Error] Push notification failed: ${error.message}`);
      return false;
    }
  } else {
    console.log(`[FCM Simulation] Alert: "${title}" - "${body}" (Simulated for token: ${fcmToken.substring(0, 10)}...)`);
    return true;
  }
};

module.exports = {
  admin,
  sendPushNotification,
  isFirebaseAdminInitialized: () => isFirebaseAdminInitialized,
};

