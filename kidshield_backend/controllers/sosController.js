const Child = require('../models/Child');
const User = require('../models/User');
const Notification = require('../models/Notification');
const Location = require('../models/Location');
const { sendPushNotification } = require('../config/firebaseAdmin');

// @desc    Trigger Emergency SOS Alert from Child App
// @route   POST /api/sos/trigger
// @access  Public (Child Device)
exports.triggerSos = async (req, res, next) => {
  try {
    const { childId, latitude, longitude, address, batteryLevel } = req.body;

    if (!childId) {
      return res.status(400).json({ success: false, message: 'Please provide childId' });
    }

    const child = await Child.findById(childId);
    if (!child) {
      return res.status(404).json({ success: false, message: 'Child device record not found' });
    }

    const parent = await User.findById(child.parentId);

    // Save location if coordinates supplied
    if (latitude !== undefined && longitude !== undefined) {
      await Location.create({
        childId: child._id,
        latitude,
        longitude,
        address: address || 'Emergency location',
        batteryAtLocation: batteryLevel || 100,
        isOffline: false,
      });
    }

    const title = '🚨 EMERGENCY SOS ALERT!';
    const message = `${child.name} has pressed the Emergency SOS button! Immediate attention required.`;

    // Save critical notification
    const alert = await Notification.create({
      parentId: child.parentId,
      childId: child._id,
      childName: child.name,
      type: 'sosEmergency',
      severity: 'critical',
      title,
      message,
      metadata: {
        latitude,
        longitude,
        address,
        batteryLevel,
        triggeredAt: new Date().toISOString(),
      },
    });

    // Send push notification via Firebase Admin SDK
    let fcmDispatched = false;
    if (parent && parent.fcmToken) {
      fcmDispatched = await sendPushNotification(parent.fcmToken, {
        title,
        body: message,
        data: {
          type: 'sosEmergency',
          alertId: String(alert._id),
          childId: String(child._id),
          childName: child.name,
          latitude: String(latitude || 0),
          longitude: String(longitude || 0),
        },
      });
    }

    res.status(200).json({
      success: true,
      message: 'Emergency SOS alert dispatched to parent successfully',
      alert,
      fcmDispatched,
    });
  } catch (error) {
    next(error);
  }
};

