const mongoose = require('mongoose');

const safeZoneSchema = new mongoose.Schema(
  {
    parentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Child',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true, // e.g. "School", "Home", "Grandparents"
    },
    latitude: {
      type: Number,
      required: true,
    },
    longitude: {
      type: Number,
      required: true,
    },
    radiusMeters: {
      type: Number,
      default: 200, // Safe radius in meters
    },
    notifyOnEntry: {
      type: Boolean,
      default: true,
    },
    notifyOnExit: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('SafeZone', safeZoneSchema);

