const mongoose = require('mongoose');
const Location = require('../models/Location');
const Child = require('../models/Child');
const SafeZone = require('../models/SafeZone');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { sendPushNotification } = require('../config/firebaseAdmin');

// In-memory store for demo/custom children IDs
const demoLocations = new Map();

// Calculate distance in meters using Haversine formula
function getDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth radius in meters
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// @desc    Update child location (Called periodically by Child App or Live GPS sync)
// @route   POST /api/locations
// @access  Public (from Child device / Parent sync)
exports.updateLocation = async (req, res, next) => {
  try {
    const { childId, latitude, longitude, address, accuracy, speed, batteryLevel, isOffline } = req.body;

    if (!childId || latitude === undefined || longitude === undefined) {
      return res.status(400).json({ success: false, message: 'Please provide childId, latitude, and longitude' });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const addr = address || 'Current Location';
    const acc = parseFloat(accuracy) || 5.0;
    const spd = parseFloat(speed) || 0.0;
    const batt = parseInt(batteryLevel, 10) || 85;

    // Handle non-ObjectId or demo children gracefully
    if (!mongoose.Types.ObjectId.isValid(childId)) {
      const demoLoc = {
        _id: 'loc-' + Date.now(),
        childId,
        latitude: lat,
        longitude: lng,
        address: addr,
        accuracy: acc,
        speed: spd,
        batteryAtLocation: batt,
        isOffline: isOffline || false,
        timestamp: new Date(),
      };
      demoLocations.set(childId, demoLoc);
      return res.status(201).json({
        success: true,
        message: 'Live location updated (demo profile)',
        location: demoLoc,
      });
    }

    const child = await Child.findById(childId);
    if (!child) {
      return res.status(404).json({ success: false, message: 'Child not found' });
    }

    // Save location record in MongoDB
    const location = await Location.create({
      childId,
      latitude: lat,
      longitude: lng,
      address: addr,
      accuracy: acc,
      speed: spd,
      batteryAtLocation: batt,
      isOffline: isOffline || false,
    });

    // Update child live status
    child.batteryLevel = batt;
    child.lastActive = new Date();
    child.isOnline = !isOffline;
    child.locationPermissionEnabled = true;
    await child.save();

    // Check Safe Zones
    const safeZones = await SafeZone.find({ childId });
    for (const zone of safeZones) {
      const distance = getDistanceMeters(lat, lng, zone.latitude, zone.longitude);
      if (distance > zone.radiusMeters && zone.notifyOnExit) {
        const parent = await User.findById(child.parentId);
        const title = `⚠️ Safe Zone Alert: ${child.name}`;
        const message = `${child.name} has moved outside the designated safe zone: "${zone.name}".`;

        await Notification.create({
          parentId: child.parentId,
          childId: child._id,
          childName: child.name,
          type: 'general',
          severity: 'warning',
          title,
          message,
          metadata: { latitude: lat, longitude: lng, address: addr, zoneName: zone.name },
        });

        if (parent && parent.fcmToken) {
          await sendPushNotification(parent.fcmToken, {
            title,
            body: message,
            data: { type: 'safeZoneExit', childId: String(child._id) },
          });
        }
      }
    }

    res.status(201).json({
      success: true,
      message: 'Location updated',
      location,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get latest location of a child
// @route   GET /api/locations/:childId/latest
// @access  Public or Private
exports.getLatestLocation = async (req, res, next) => {
  try {
    const { childId } = req.params;

    // Check demo or custom ID cache
    if (!mongoose.Types.ObjectId.isValid(childId)) {
      if (demoLocations.has(childId)) {
        return res.status(200).json({ success: true, location: demoLocations.get(childId) });
      }
      return res.status(404).json({ success: false, message: 'No location records found for this demo child' });
    }

    let location = await Location.findOne({ childId }).sort({ timestamp: -1 });

    if (!location) {
      return res.status(200).json({
        success: true,
        location: null,
        message: 'No location records found yet from child device',
      });
    }

    // Keep child permission enabled whenever location is accessed
    await Child.findByIdAndUpdate(childId, { locationPermissionEnabled: true });

    res.status(200).json({ success: true, location });
  } catch (error) {
    next(error);
  }
};

// @desc    Get location trace history for a child
// @route   GET /api/locations/:childId/history
// @access  Public or Private
exports.getLocationHistory = async (req, res, next) => {
  try {
    const { childId } = req.params;
    const limit = parseInt(req.query.limit, 10) || 50;

    if (!mongoose.Types.ObjectId.isValid(childId)) {
      const demo = demoLocations.get(childId);
      return res.status(200).json({
        success: true,
        count: demo ? 1 : 0,
        history: demo ? [demo] : [],
      });
    }

    const history = await Location.find({ childId })
      .sort({ timestamp: -1 })
      .limit(limit);

    res.status(200).json({
      success: true,
      count: history.length,
      history,
    });
  } catch (error) {
    next(error);
  }
};
